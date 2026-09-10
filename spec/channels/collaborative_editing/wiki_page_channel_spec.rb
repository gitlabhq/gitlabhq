# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CollaborativeEditing::WikiPageChannel, :clean_gitlab_redis_shared_state,
  :with_current_organization, feature_category: :wiki do
  let_it_be_with_reload(:project) { create(:project, :private, :wiki_repo) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:stranger) { create(:user) }

  let_it_be(:page) { create(:wiki_page, wiki: project.wiki, title: 'home', content: 'Hello') }

  let(:subscribe_params) do
    { container_full_path: project.full_path, slug: page.slug }
  end

  let(:document_key) { "wiki:Project:#{project.id}:#{CGI.escape(page.slug)}" }
  let(:stream_name) { "collaborative_editing:#{document_key}" }

  before do
    stub_action_cable_connection current_user: developer, current_organization: current_organization
  end

  describe '#subscribed' do
    it 'subscribes a user who can edit the wiki' do
      subscribe(subscribe_params)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from(stream_name)
    end

    it 'sends the existing update log to the joining client' do
      store_for(page).append('existing-update')

      subscribe(subscribe_params)

      expect(transmissions.last).to include('type' => 'init', 'updates' => ['existing-update'])
    end

    describe 'feature flag scope' do
      context 'when the flag is disabled' do
        before do
          stub_feature_flags(wiki_collaborative_editing: false)
        end

        it 'rejects the subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end

      it 'is scoped to the root ancestor of the container' do
        stub_feature_flags(wiki_collaborative_editing: project.root_ancestor)

        subscribe(subscribe_params)

        expect(subscription).to be_confirmed
      end
    end

    context 'when the user cannot edit the wiki' do
      before do
        stub_action_cable_connection current_user: guest, current_organization: current_organization
      end

      it 'rejects the subscription' do
        subscribe(subscribe_params)

        expect(subscription).to be_rejected
      end
    end

    context 'when the user cannot read the project' do
      before do
        stub_action_cable_connection current_user: stranger, current_organization: current_organization
      end

      it 'rejects the subscription' do
        subscribe(subscribe_params)

        expect(subscription).to be_rejected
      end

      it 'rejects before looking the page up' do
        expect(ProjectWiki).not_to receive(:new)

        subscribe(subscribe_params)

        expect(subscription).to be_rejected
      end
    end

    context 'when the page does not exist' do
      it 'rejects the subscription' do
        subscribe(container_full_path: project.full_path, slug: 'does-not-exist')

        expect(subscription).to be_rejected
      end
    end

    context 'when the container does not exist' do
      it 'rejects the subscription' do
        subscribe(container_full_path: 'no/such/project', slug: page.slug)

        expect(subscription).to be_rejected
      end
    end

    context 'when the container has no wiki' do
      it 'rejects the subscription' do
        subscribe(container_full_path: developer.username, slug: page.slug)

        expect(subscription).to be_rejected
      end
    end

    context 'when params are missing' do
      it 'rejects the subscription' do
        subscribe({})

        expect(subscription).to be_rejected
      end
    end

    describe 'seed election' do
      it 'elects the first subscriber to seed an empty document' do
        subscribe(subscribe_params)

        expect(transmissions.last).to include('seed' => true)
      end

      it 'does not elect a second subscriber' do
        subscribe(subscribe_params)
        subscribe(subscribe_params)

        expect(transmissions.last).to include('seed' => false)
      end

      it 'does not elect a subscriber when the document already has updates' do
        store_for(page).append('existing-update')

        subscribe(subscribe_params)

        expect(transmissions.last).to include('seed' => false)
      end
    end

    context 'with a slug containing Redis Cluster hash tag characters' do
      let_it_be(:braced_page) do
        create(:wiki_page, wiki: project.wiki, title: 'we{ir}d', content: 'Hello')
      end

      it 'escapes the slug so the key carries no braces', :aggregate_failures do
        escaped = "collaborative_editing:wiki:Project:#{project.id}:#{CGI.escape(braced_page.slug)}"

        subscribe(container_full_path: project.full_path, slug: braced_page.slug)

        expect(braced_page.slug).to include('{', '}')
        expect(escaped).not_to include('{', '}')
        expect(subscription).to have_stream_from(escaped)
      end

      it 'keeps the document distinct from a similarly named page', :aggregate_failures do
        store_for(braced_page).append('braced-update')

        subscribe(subscribe_params)

        expect(transmissions.last).to include('updates' => [])
      end
    end

    context 'with a wiki page of the same slug in another project' do
      let_it_be_with_reload(:other_project) { create(:project, :private, :wiki_repo, developers: developer) }
      let_it_be(:other_page) do
        create(:wiki_page, wiki: other_project.wiki, title: 'home', content: 'Other')
      end

      it 'uses a separate document so content does not leak between projects' do
        store_for(other_page).append('other-project-update')

        subscribe(subscribe_params)

        expect(transmissions.last).to include('updates' => [])
      end
    end

    context 'with a legacy personal access token' do
      it 'rejects a token that only carries read_api' do
        token = create(:personal_access_token, scopes: ['read_api'], user: developer)
        stub_action_cable_connection current_user: developer, access_token: token,
          current_organization: current_organization

        subscribe(subscribe_params)

        expect(subscription).to be_rejected
      end

      it 'accepts a token carrying api' do
        token = create(:personal_access_token, scopes: ['api'], user: developer)
        stub_action_cable_connection current_user: developer, access_token: token,
          current_organization: current_organization

        subscribe(subscribe_params)

        expect(subscription).to be_confirmed
      end
    end

    context 'with a granular personal access token' do
      let(:pat) do
        create(:granular_pat, user: developer, boundary: Authz::Boundary.for(project),
          permissions: :create_wiki)
      end

      it 'subscribes when the token carries create_wiki' do
        stub_action_cable_connection current_user: developer, access_token: pat,
          current_organization: current_organization

        subscribe(subscribe_params)

        expect(subscription).to be_confirmed
      end

      context 'when the token does not carry create_wiki' do
        let(:pat) do
          create(:granular_pat, user: developer, boundary: Authz::Boundary.for(project),
            permissions: :read_wiki)
        end

        it 'rejects the subscription' do
          stub_action_cable_connection current_user: developer, access_token: pat,
            current_organization: current_organization

          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end

      context 'when the token is scoped to another project' do
        let_it_be(:other_project) { create(:project, :private, developers: developer) }
        let(:pat) do
          create(:granular_pat, user: developer, boundary: Authz::Boundary.for(other_project),
            permissions: :create_wiki)
        end

        it 'rejects the subscription' do
          stub_action_cable_connection current_user: developer, access_token: pat,
            current_organization: current_organization

          subscribe(subscribe_params)

          expect(subscription).to be_rejected
        end
      end
    end
  end

  describe 'periodic access revalidation without a subscription' do
    it 'does nothing when the subscription was rejected', :aggregate_failures do
      subscribe(container_full_path: project.full_path, slug: 'does-not-exist')

      expect(subscription).to be_rejected
      expect(subscription).not_to receive(:unsubscribe_from_channel)

      revalidate
    end
  end

  describe 'periodic access revalidation' do
    before do
      subscribe(subscribe_params)
    end

    it 'is scheduled for every subscriber' do
      expect(described_class.periodic_timers.map(&:last)).to include({ every: 1.minute })
    end

    it 'keeps relaying for a subscriber who still has access', :aggregate_failures do
      revalidate

      expect { perform :receive, message('sync', 'an-update') }
        .to have_broadcasted_to(stream_name)

      expect(store_for(page).updates).to eq(['an-update'])
    end

    context 'when the user loses access to the container' do
      before do
        project.members.find_by(user_id: developer.id).destroy!
      end

      it 'unsubscribes them' do
        expect(subscription).to receive(:unsubscribe_from_channel)

        revalidate
      end

      it 'stops relaying their updates', :aggregate_failures do
        revalidate

        expect { perform :receive, message('sync', 'an-update') }
          .not_to have_broadcasted_to(stream_name)

        expect(store_for(page).updates).to be_empty
      end
    end

    context 'when the feature flag is turned off mid-session' do
      before do
        stub_feature_flags(wiki_collaborative_editing: false)
      end

      it 'unsubscribes them' do
        expect(subscription).to receive(:unsubscribe_from_channel)

        revalidate
      end

      it 'stops relaying their updates' do
        revalidate

        expect { perform :receive, message('sync', 'an-update') }
          .not_to have_broadcasted_to(stream_name)
      end
    end
  end

  describe '#receive' do
    before do
      subscribe(subscribe_params)
    end

    it 'persists and broadcasts a sync update' do
      expect { perform :receive, message('sync', 'an-update') }
        .to have_broadcasted_to(stream_name)
        .with(hash_including('type' => 'sync', 'payload' => 'an-update'))

      expect(store_for(page).updates).to eq(['an-update'])
    end

    it 'broadcasts awareness without persisting it' do
      expect { perform :receive, message('awareness', 'cursor-position') }
        .to have_broadcasted_to(stream_name)
        .with(hash_including('type' => 'awareness'))

      expect(store_for(page).updates).to be_empty
    end

    describe 'identity on an awareness relay' do
      it 'stamps the sender identity from the session' do
        expect { perform :receive, message('awareness', 'cursor-position') }
          .to have_broadcasted_to(stream_name)
          .with(
            hash_including(
              'user' => {
                id: developer.id,
                name: developer.name,
                avatarUrl: developer.avatar_url(only_path: false)
              }
            )
          )
      end

      it 'ignores an identity supplied by the sender' do
        spoofed = message('awareness', 'cursor-position')
          .merge('user' => { 'name' => 'Administrator', 'avatarUrl' => 'https://evil.test/beacon' })

        expect { perform :receive, spoofed }
          .to have_broadcasted_to(stream_name)
          .with(hash_including('user' => hash_including(name: developer.name)))
      end

      it 'does not stamp identity onto a sync relay' do
        expect { perform :receive, message('sync', 'an-update') }
          .to have_broadcasted_to(stream_name)
          .with(->(payload) { expect(payload).not_to have_key('user') })
      end
    end

    it 'ignores a payload that is not a string' do
      expect { perform :receive, { 'type' => 'sync', 'payload' => { 'a' => 'b' } } }
        .not_to have_broadcasted_to(stream_name)
    end

    it 'ignores a payload above the size limit' do
      oversized = 'a' * (described_class.superclass::MAX_PAYLOAD_BYTES + 1)

      expect { perform :receive, message('sync', oversized) }
        .not_to have_broadcasted_to(stream_name)
    end

    it 'ignores an unknown message type' do
      expect { perform :receive, message('nonsense', 'a-payload') }
        .not_to have_broadcasted_to(stream_name)
    end

    [{ 'a' => 'b' }, %w[1 2], 'not-a-number', nil].each do |client_id|
      it "ignores a message whose clientId is #{client_id.class}" do
        expect { perform :receive, message('sync', 'an-update').merge('clientId' => client_id) }
          .not_to have_broadcasted_to(stream_name)
      end
    end

    it 'does not store a message with a rejected clientId' do
      perform :receive, message('sync', 'an-update').merge('clientId' => { 'a' => 'b' })

      expect(store_for(page).updates).to be_empty
    end

    describe 'compaction' do
      before do
        stub_const('Gitlab::CollaborativeEditing::DocumentStore::COMPACTION_THRESHOLD', 2)
      end

      it 'asks the sender for a snapshot once the log grows too long', :aggregate_failures do
        perform :receive, message('sync', 'first')
        perform :receive, message('sync', 'second')

        expect(transmissions.last).to include('type' => 'request_snapshot')
        expect(transmissions.last['token']).to be_present
      end

      it 'replaces the log with a snapshot without rebroadcasting it', :aggregate_failures do
        perform :receive, message('sync', 'first')
        perform :receive, message('sync', 'second')
        token = transmissions.last['token']

        expect { perform :receive, message('snapshot', 'a-snapshot').merge('token' => token) }
          .not_to have_broadcasted_to(stream_name)

        expect(store_for(page).updates).to eq(['a-snapshot'])
      end

      it 'ignores a snapshot from a client that was not asked to compact' do
        perform :receive, message('sync', 'first')
        perform :receive, message('sync', 'second')

        perform :receive, message('snapshot', 'a-snapshot').merge('token' => 'forged')

        expect(store_for(page).updates).to eq(%w[first second])
      end

      it 'ignores a snapshot with no token' do
        perform :receive, message('sync', 'first')
        perform :receive, message('sync', 'second')

        perform :receive, message('snapshot', 'a-snapshot')

        expect(store_for(page).updates).to eq(%w[first second])
      end
    end

    context 'when the log is at its ceiling' do
      before do
        stub_const('Gitlab::CollaborativeEditing::DocumentStore::COMPACTION_THRESHOLD', 2)
        stub_const('Gitlab::CollaborativeEditing::DocumentStore::MAX_LOG_LENGTH', 2)

        perform :receive, message('sync', 'first')
        perform :receive, message('sync', 'second')
      end

      it 'tells the sender the document is full' do
        perform :receive, message('sync', 'third')

        expect(transmissions.last).to eq({ 'type' => 'document_full' })
      end

      it 'does not relay the rejected update' do
        expect { perform :receive, message('sync', 'third') }
          .not_to have_broadcasted_to(stream_name)
      end

      it 'does not store the rejected update' do
        perform :receive, message('sync', 'third')

        expect(store_for(page).updates).to eq(%w[first second])
      end

      context 'and the compactor never delivered a snapshot' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.del("collaborative_editing:{#{document_key}}:compaction")
          end
        end

        it 'asks the sender to compact as well as reporting it full', :aggregate_failures do
          perform :receive, message('sync', 'third')

          types = transmissions.map { |t| t['type'] }

          expect(types).to include('document_full')
          expect(transmissions.last).to include('type' => 'request_snapshot')
          expect(transmissions.last['token']).to be_present
        end

        it 'accepts updates again once that snapshot arrives', :aggregate_failures do
          perform :receive, message('sync', 'third')
          token = transmissions.last['token']

          perform :receive, message('snapshot', 'a-snapshot').merge('token' => token)
          perform :receive, message('sync', 'fourth')

          expect(store_for(page).updates).to eq(%w[a-snapshot fourth])
        end
      end
    end

    context 'when the update rate limit is exceeded', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:throttled?)
          .with(:collaborative_editing_update, scope: [developer, document_key])
          .and_return(true)
      end

      it 'stops relaying updates' do
        expect { perform :receive, message('sync', 'an-update') }
          .not_to have_broadcasted_to(stream_name)
      end

      it 'does not persist the update' do
        perform :receive, message('sync', 'an-update')

        expect(store_for(page).updates).to be_empty
      end
    end

    it 'counts updates from every subscription against one limit',
      :clean_gitlab_redis_rate_limiting do
      expect(Gitlab::ApplicationRateLimiter)
        .to receive(:throttled?)
        .with(:collaborative_editing_update, scope: [developer, document_key])
        .twice
        .and_call_original

      perform :receive, message('sync', 'first')

      subscribe(subscribe_params)
      perform :receive, message('sync', 'second')
    end
  end

  def message(type, payload)
    { 'type' => type, 'payload' => payload, 'clientId' => 1 }
  end

  def revalidate
    subscription.send(:revalidate_access)
  end

  def store_for(wiki_page)
    Gitlab::CollaborativeEditing::DocumentStore.new(
      "wiki:Project:#{wiki_page.wiki.container.id}:#{CGI.escape(wiki_page.slug)}"
    )
  end
end
