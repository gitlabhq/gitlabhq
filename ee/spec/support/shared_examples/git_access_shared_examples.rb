# frozen_string_literal: true

shared_examples 'a read-only GitLab instance' do
  it 'denies push access' do
    project.add_maintainer(user)

    expect { push_changes }.to raise_unauthorized("You can't push code to a read-only GitLab instance.")
  end

  context 'for a Geo setup' do
    before do
      primary_node = create(:geo_node, :primary, url: 'https://localhost:3000/gitlab')
      allow(Gitlab::Geo).to receive(:primary).and_return(primary_node)
      allow(Gitlab::Geo).to receive(:secondary_with_primary?).and_return(secondary_with_primary)
    end

    context 'that is incorrectly setup' do
      let(:secondary_with_primary) { false }
      let(:error_message) { "You can't push code to a read-only GitLab instance." }

      it 'denies push access with primary present' do
        project.add_maintainer(user)

        expect { push_changes }.to raise_unauthorized(error_message)
      end
    end

    context 'that is correctly setup' do
      let(:secondary_with_primary) { true }
      let(:payload) do
        {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => %w{/api/v4/geo/proxy_git_push_ssh/info_refs /api/v4/geo/proxy_git_push_ssh/push},
            'primary_repo' => primary_repo_url
          }
        }
      end

      it 'attempts to proxy to the primary' do
        project.add_maintainer(user)

        expect(push_changes).to be_a(Gitlab::GitAccessResult::CustomAction)
        expect(push_changes.message).to eql('Attempting to proxy to primary.')
        expect(push_changes.payload).to eql(payload)
      end
    end
  end
end
