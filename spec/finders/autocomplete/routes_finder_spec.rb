# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::RoutesFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user, username: 'user_path') }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:group) { create(:group, path: 'path1') }
    let_it_be(:group2) { create(:group, path: 'path2') }
    let_it_be(:group3) { create(:group, path: 'not-matching') }
    let_it_be(:project) { create(:project, path: 'path3', namespace: user.namespace) }
    let_it_be(:project2) { create(:project, path: 'path4') }
    let_it_be(:project_namespace) { create(:project_namespace, parent: group, path: 'path5') }

    let(:current_user) { user }
    let(:search) { 'path' }

    before do
      group.add_owner(user)
    end

    context 'for NamespacesOnly' do
      subject { Autocomplete::RoutesFinder::NamespacesOnly.new(current_user, search: search).execute }

      let(:user_route) { Route.find_by_path(user.username) }

      it 'finds only user namespace and groups matching the search excluding project namespaces' do
        is_expected.to match_array([group.route, user_route])
      end

      context 'when user is admin' do
        let(:current_user) { admin }

        context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
          it 'finds all namespaces matching the search excluding project namespaces' do
            is_expected.to match_array([group.route, group2.route, user_route])
          end
        end

        context 'when admin mode setting is enabled' do
          context 'when in admin mode', :enable_admin_mode do
            it 'finds all namespaces matching the search excluding project namespaces' do
              is_expected.to match_array([group.route, group2.route, user_route])
            end
          end

          context 'when not in admin mode' do
            it 'does not find all namespaces' do
              is_expected.to match_array([])
            end
          end
        end
      end
    end

    context 'for ProjectsOnly' do
      subject { Autocomplete::RoutesFinder::ProjectsOnly.new(current_user, search: 'path').execute }

      it 'finds only matching projects the user has access to' do
        is_expected.to match_array([project.route])
      end

      context 'when user is admin' do
        let(:current_user) { admin }

        context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
          it 'finds all projects matching the search' do
            is_expected.to match_array([project.route, project2.route])
          end
        end

        context 'when admin mode setting is enabled' do
          context 'when in admin mode', :enable_admin_mode do
            it 'finds all projects matching the search' do
              is_expected.to match_array([project.route, project2.route])
            end
          end

          context 'when not in admin mode' do
            it 'does not find all projects' do
              is_expected.to match_array([])
            end
          end
        end
      end
    end
  end
end
