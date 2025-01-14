# frozen_string_literal: true

require 'spec_helper'

# Persisting records is required because Event#target's AR scope.
# We are trying hard to minimize record creations by:
# * Using `let_it_be`
# * Factory defaults via `create_default` + `factory_default: :keep`
#
# rubocop:disable RSpec/FactoryBot/AvoidCreate
RSpec.describe EventsHelper, factory_default: :keep, feature_category: :user_profile do
  include Gitlab::Routing
  include Banzai::Filter::Concerns::OutputSafety

  let_it_be(:project) { create_default(:project).freeze }
  let_it_be(:project_with_repo) { create(:project, :public, :repository).freeze }
  let_it_be(:user) { create_default(:user).freeze }

  describe '#link_to_author' do
    let(:user) { create(:user) }
    let(:event) { create(:event, author: user) }

    it 'returns a link to the author' do
      name = user.name
      expect(helper.link_to_author(event)).to eq(link_to(name, user_path(user.username), title: name,
        data: { user_id: user.id, username: user.username }, class: 'js-user-link'))
    end

    it 'returns the author name if the author is not present' do
      event.author = nil

      expect(helper.link_to_author(event)).to eq(escape_once(event.author_name))
    end

    it 'returns "You" if the author is the current user' do
      allow(helper).to receive(:current_user).and_return(user)

      name = _('You')
      expect(helper.link_to_author(event, self_added: true)).to eq(link_to(name, user_path(user.username), title: name,
        data: { user_id: user.id, username: user.username }, class: 'js-user-link'))
    end
  end

  describe '#icon_for_profile_event' do
    let(:event) { build(:event, :joined) }
    let(:users_activity_page?) { true }

    before do
      allow(helper).to receive(:current_path?).and_call_original
      allow(helper).to receive(:current_path?).with('users#activity').and_return(users_activity_page?)
    end

    context 'when on users activity page' do
      it 'gives an icon with specialized classes' do
        result = helper.icon_for_profile_event(event)

        expect(result).to include('joined-icon')
        expect(result).to include('<svg')
      end

      context 'with an unsupported event action_name' do
        let(:event) { build(:event, :expired) }

        it 'does not have an icon' do
          result = helper.icon_for_profile_event(event)

          expect(result).not_to include('<svg')
        end
      end
    end

    context 'when not on users activity page' do
      let(:users_activity_page?) { false }

      it 'gives an icon with specialized classes' do
        result = helper.icon_for_profile_event(event)

        expect(result).not_to include('joined-icon')
        expect(result).not_to include('<svg')
        expect(result).to include('<img')
      end
    end
  end

  describe '#event_user_info' do
    let(:event) { build(:event) }
    let(:users_activity_page?) { true }

    before do
      allow(helper).to receive(:current_path?).and_call_original
      allow(helper).to receive(:current_path?).with('users#activity').and_return(users_activity_page?)
    end

    subject { helper.event_user_info(event) }

    context 'when on users activity page' do
      it { is_expected.to be_nil }
    end

    context 'when not on users activity page' do
      let(:users_activity_page?) { false }

      it { is_expected.to include('<div') }
    end
  end

  describe '#event_target_path' do
    subject { helper.event_target_path(event.present) }

    context 'when target is a work item' do
      let(:work_item) { create(:work_item) }
      let(:event) { create(:event, target: work_item, target_type: 'WorkItem') }

      it { is_expected.to eq(Gitlab::UrlBuilder.build(work_item, only_path: true)) }
    end

    context 'when target is a group level work item' do
      let(:work_item) { create(:work_item, namespace: create(:group)) }
      let(:event) { create(:event, target: work_item, target_type: 'WorkItem') }

      it { is_expected.to eq(Gitlab::UrlBuilder.build(work_item, only_path: true)) }
    end

    context 'when target is not a work item' do
      let(:issue) { create(:issue) }
      let(:event) { create(:event, target: issue) }

      it { is_expected.to eq([project, issue]) }
    end
  end

  describe '#localized_action_name' do
    it 'handles all valid design events' do
      created, updated, destroyed = %i[created updated destroyed].map do |trait|
        event = build_stubbed(:design_event, trait)
        helper.localized_action_name(event)
      end

      expect(created).to eq(_('added'))
      expect(updated).to eq(_('updated'))
      expect(destroyed).to eq(_('removed'))
    end

    describe 'handles correct base actions' do
      using RSpec::Parameterized::TableSyntax

      where(:trait, :localized_action_key) do
        :created   | 'Event|created'
        :updated   | 'Event|opened'
        :closed    | 'Event|closed'
        :reopened  | 'Event|opened'
        :commented | 'Event|commented on'
        :merged    | 'Event|accepted'
        :joined    | 'Event|joined'
        :left      | 'Event|left'
        :destroyed | 'Event|destroyed'
        :expired   | 'Event|removed due to membership expiration from'
        :approved  | 'Event|approved'
      end

      with_them do
        it 'with correct name and method' do
          Gitlab::I18n.with_locale(:de) do
            event = build_stubbed(:event, trait)

            expect(helper.localized_action_name(event)).to eq(s_(localized_action_key))
          end
        end
      end
    end
  end

  describe '#event_commit_title' do
    let(:message) { "foo & bar #{'A' * 70}\\n#{'B' * 80}" }

    subject { helper.event_commit_title(message) }

    it 'returns the first line, truncated to 70 chars' do
      is_expected.to eq("#{message[0..66]}...")
    end

    it 'is not html-safe' do
      is_expected.not_to be_html_safe
    end

    it 'handles empty strings' do
      expect(helper.event_commit_title("")).to eq("")
    end

    it 'handles nil values' do
      expect(helper.event_commit_title(nil)).to eq('')
    end

    it 'does not escape HTML entities' do
      expect(helper.event_commit_title('foo & bar')).to eq('foo & bar')
    end
  end

  describe '#event_feed_url' do
    let(:event) { create(:event).present }

    context 'for issue' do
      before do
        event.target = create(:issue)
      end

      it 'returns the project issue url' do
        expect(helper.event_feed_url(event)).to eq(project_issue_url(event.project, event.target))
      end

      it 'contains the project issue IID link' do
        expect(helper.event_feed_title(event)).to include("##{event.target.iid}")
      end
    end

    context 'for merge request' do
      before do
        event.target = create(:merge_request, source_project: project_with_repo)
      end

      it 'returns the project merge request url' do
        expect(helper.event_feed_url(event)).to eq(project_merge_request_url(event.project, event.target))
      end

      it 'contains the project merge request IID link' do
        expect(helper.event_feed_title(event)).to include("!#{event.target.iid}")
      end
    end

    it 'returns project commit url' do
      event.target = create(:note_on_commit, project: project_with_repo)

      expect(helper.event_feed_url(event)).to eq(project_commit_url(event.project, event.note_target))
    end

    it 'returns event note target url' do
      event.target = create(:note)

      expect(helper.event_feed_url(event)).to eq(event_note_target_url(event))
    end

    it 'returns project url' do
      event.action = 1

      expect(helper.event_feed_url(event)).to eq(project_url(event.project))
    end

    it 'returns push event feed url' do
      event = create(:push_event)
      create(:push_event_payload, event: event, action: :pushed)

      expect(helper.event_feed_url(event)).to eq(push_event_feed_url(event))
    end

    it 'returns nil for push event with multiple refs' do
      event = create(:push_event)
      create(:push_event_payload, event: event, ref_count: 2, ref: nil, ref_type: :tag, commit_count: 0,
        action: :pushed)

      expect(helper.event_feed_url(event)).to eq(nil)
    end
  end

  describe '#event_preposition' do
    context 'for wiki page events' do
      let(:event) { create(:wiki_page_event) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('in the wiki for')
      end
    end

    context 'for push action events' do
      let(:event) { create(:push_event) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for commented actions' do
      let(:event) { create(:event, :commented) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for any event with a target' do
      let(:event) { create(:event, target: create(:issue)) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('at')
      end
    end

    context 'for milestone events' do
      let(:event) { create(:event, target: create(:milestone)) }

      it 'returns a suitable phrase' do
        expect(helper.event_preposition(event)).to eq('in')
      end
    end

    context 'for non-matching events' do
      let(:event) { create(:event, :created) }

      it 'returns no preposition' do
        expect(helper.event_preposition(event)).to be_nil
      end
    end
  end

  describe '#event_wiki_page_target_url' do
    let_it_be(:project) { create(:project) }

    context 'for project wiki' do
      let(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }
      let(:event) { create(:event, target: wiki_page_meta, project: wiki_page_meta.project) }

      it 'links to the wiki page' do
        url = helper.project_wiki_url(wiki_page_meta.project, wiki_page_meta.canonical_slug)

        expect(helper.event_wiki_page_target_url(event)).to eq(url)
      end

      context 'without canonical slug' do
        before do
          event.target.slugs.update_all(canonical: false)
          event.target.clear_memoization(:canonical_slug)
        end

        it 'links to the home page' do
          url = helper.project_wiki_url(wiki_page_meta.project, Wiki::HOMEPAGE)

          expect(helper.event_wiki_page_target_url(event)).to eq(url)
        end
      end
    end

    context 'for an event that has neither project nor group' do
      let(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }
      let(:event) { create(:event, target: wiki_page_meta, group: nil, project: nil) }

      it 'returns nil' do
        expect(helper.event_wiki_page_target_url(event)).to be_nil
      end
    end
  end

  describe '#event_wiki_title_html' do
    let(:event) { create(:wiki_page_event) }
    let(:url) { helper.event_wiki_page_target_url(event) }
    let(:title) { event.target_title }

    it 'produces a suitable title chunk' do
      html = [
        "<span class=\"event-target-type \">wiki page </span>",
        "<a title=\"#{title}\" class=\"event-target-link\" href=\"#{url}\">",
        title,
        "</a>"
      ].join

      expect(helper.event_wiki_title_html(event)).to eq(html)
    end

    it 'produces a suitable title chunk on the user profile' do
      allow(helper).to receive(:user_profile_activity_classes).and_return(
        'gl-font-semibold gl-text-default')

      html = [
        "<span class=\"event-target-type gl-font-semibold gl-text-default\">wiki page </span>",
        "<a title=\"#{title}\" class=\"event-target-link\" href=\"#{url}\">",
        title,
        "</a>"
      ].join

      expect(helper.event_wiki_title_html(event)).to eq(html)
    end
  end

  describe '#event_note_target_url' do
    let_it_be(:event) { create(:event) }
    let(:project_base_url) { namespace_project_url(namespace_id: project.namespace, id: project) }

    subject { helper.event_note_target_url(event) }

    it 'returns a commit note url' do
      event.target = create(:note_on_commit, project: project_with_repo, note: '+1 from me')

      expect(subject).to eq("#{project_base_url}/-/commit/#{event.target.commit_id}#note_#{event.target.id}")
    end

    it 'returns a project snippet note url' do
      event.target = create(:note_on_project_snippet, note: 'keep going')

      expect(subject).to eq("#{project_snippet_url(event.note_target.project,
        event.note_target)}#note_#{event.target.id}")
    end

    it 'returns a personal snippet note url' do
      event.target = create(:note_on_personal_snippet, note: 'keep going')

      expect(subject).to eq("#{snippet_url(event.note_target)}#note_#{event.target.id}")
    end

    it 'returns a project issue url' do
      event.target = create(:note_on_issue, note: 'nice work')

      expect(subject).to eq("#{project_base_url}/-/issues/#{event.note_target.iid}#note_#{event.target.id}")
    end

    context 'when group level work item' do
      let(:work_item) { create(:work_item, :group_level, namespace: create(:group)) }
      let(:note) { create(:note_on_work_item, namespace: work_item.namespace, noteable: work_item) }
      let(:event) { create(:event, :closed, group: work_item.namespace, project: nil, target: note) }

      it 'returns url to group level work item' do
        expect(subject).to eq(group_work_item_url(event.group, event.target.noteable, anchor: dom_id(event.target)))
      end
    end

    it 'returns a merge request url' do
      event.target = create(:note_on_merge_request, note: 'LGTM!')

      expect(subject).to eq("#{project_base_url}/-/merge_requests/#{event.note_target.iid}#note_#{event.target.id}")
    end

    context 'for design note events' do
      let(:event) { create(:event, :for_design) }

      it 'returns an appropriate URL' do
        iid = event.note_target.issue.iid
        filename = event.note_target.filename
        note_id  = event.target.id

        expect(subject).to eq("#{project_base_url}/-/issues/#{iid}/designs/#{filename}#note_#{note_id}")
      end
    end

    context 'for wiki page notes' do
      let(:event) { create(:event, :for_wiki_page_note) }
      let(:project) { event.target.project }

      it 'returns an appropriate URL' do
        path = event.note_target.canonical_slug
        note_id = event.target.id

        expect(subject).to eq("#{project_base_url}/-/wikis/#{path}#note_#{note_id}")
      end
    end
  end

  describe '#event_filter_visible' do
    include DesignManagementTestHelpers

    subject { helper.event_filter_visible(key) }

    before do
      enable_design_management
      allow(helper).to receive(:current_user).and_return(user)
    end

    def can_read_design_activity(object, ability)
      allow(Ability).to receive(:allowed?)
        .with(user, :read_design_activity, eq(object))
        .and_return(ability)
    end

    context 'for :designs' do
      let(:key) { :designs }

      context 'without relevant instance variable' do
        it { is_expected.to be(true) }
      end

      context 'with assigned project' do
        before do
          assign(:project, project)
        end

        context 'with permission' do
          before do
            can_read_design_activity(project, true)
          end

          it { is_expected.to be(true) }
        end

        context 'without permission' do
          before do
            can_read_design_activity(project, false)
          end

          it { is_expected.to be(false) }
        end
      end

      context 'with projects assigned' do
        before do
          assign(:projects, Project.id_in(project))
        end

        context 'with permission' do
          before do
            can_read_design_activity(project, true)
          end

          it { is_expected.to be(true) }
        end

        context 'with empty collection' do
          before do
            assign(:projects, Project.none)
          end

          it { is_expected.to be(false) }
        end

        context 'without permission' do
          before do
            can_read_design_activity(project, false)
          end

          it { is_expected.to be(false) }
        end
      end

      context 'with group assigned' do
        let_it_be(:group) { create(:group) }

        before do
          assign(:group, group)
        end

        context 'without projects in the group' do
          it { is_expected.to be(false) }
        end

        context 'with at least one project in the project' do
          let_it_be(:group_link) { create(:project_group_link, group: group) }

          context 'with permission' do
            before do
              can_read_design_activity(group, true)
            end

            it { is_expected.to be(true) }
          end

          context 'without permission' do
            before do
              can_read_design_activity(group, false)
            end

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end

  describe '#user_profile_activity_classes' do
    let(:users_activity_page?) { true }

    before do
      allow(helper).to receive(:current_path?).and_call_original
      allow(helper).to receive(:current_path?).with('users#activity').and_return(users_activity_page?)
    end

    context 'when on the user activity page' do
      it 'returns the expected class names' do
        expect(helper.user_profile_activity_classes).to eq(' gl-font-semibold gl-text-default')
      end
    end

    context 'when not on the user activity page' do
      let(:users_activity_page?) { false }

      it 'returns an empty string' do
        expect(helper.user_profile_activity_classes).to eq('')
      end
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
