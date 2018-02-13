require 'spec_helper'

describe 'Group routing', "routing" do
  include RSpec::Rails::RoutingExampleGroup

  describe 'subgroup "boards"' do
    it 'shows group show page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq/boards', any_args).and_return(true)

      expect(get('/groups/gitlabhq/boards')).to route_to('groups#show', id: 'gitlabhq/boards')
    end

    it 'shows boards index page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
    end
  end

  describe 'legacy redirection' do
    %w(analytics
       boards
       ldap
       ldap_group_links
       notification_setting
       audit_events
       pipeline_quota hooks).each do |legacy_reserved_path|
      describe legacy_reserved_path do
        it_behaves_like 'redirecting a legacy path',
                        "/groups/complex.group-namegit/#{legacy_reserved_path}",
                        "/groups/complex.group-namegit/-/#{legacy_reserved_path}" do
          let!(:parent) { create(:group, path: 'complex.group-namegit') }
          let(:resource) { create(:group, parent: parent, path: legacy_reserved_path) }
        end
      end
    end

    context 'multiple redirects' do
      include RSpec::Rails::RequestExampleGroup

      let!(:parent) { create(:group, path: 'complex.group-namegit') }

      it 'follows multiple redirects' do
        expect(get('/groups/complex.group-namegit/boards/issues'))
          .to redirect_to('/groups/complex.group-namegit/-/boards/issues')
      end

      it 'redirects when the nested group does not exist' do
        create(:group, path: 'boards', parent: parent)

        expect(get('/groups/complex.group-namegit/boards/issues/'))
          .to redirect_to('/groups/complex.group-namegit/boards/-/issues')
      end

      it 'does not redirect when the nested group exists' do
        boards_group = create(:group, path: 'boards', parent: parent)
        create(:group, path: 'issues', parent: boards_group)

        expect(get('/groups/complex.group-namegit/boards/issues'))
          .to eq(200)
      end
    end
  end
end
