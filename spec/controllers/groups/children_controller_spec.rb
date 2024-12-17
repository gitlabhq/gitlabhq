# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ChildrenController, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group_member) { create(:group_member, group: group, user: user) }

  describe 'GET #index' do
    context 'for projects' do
      let_it_be(:public_project) { create(:project, :public, namespace: group) }
      let_it_be(:private_project) { create(:project, :private, namespace: group) }

      context 'as a user' do
        before do
          sign_in(user)
        end

        it 'shows all children' do
          get :index, params: { group_id: group.to_param }, format: :json

          expect(assigns(:children)).to contain_exactly(public_project, private_project)
        end

        context 'being member of private subgroup' do
          it 'shows public and private children the user is member of' do
            group_member.destroy!
            private_project.add_guest(user)

            get :index, params: { group_id: group.to_param }, format: :json

            expect(assigns(:children)).to contain_exactly(public_project, private_project)
          end
        end
      end

      context 'as a guest' do
        it 'shows the public children' do
          get :index, params: { group_id: group.to_param }, format: :json

          expect(assigns(:children)).to contain_exactly(public_project)
        end
      end
    end

    context 'for subgroups' do
      let_it_be(:public_subgroup) { create(:group, :public, parent: group) }
      let_it_be(:private_subgroup) { create(:group, :private, parent: group) }
      let_it_be(:public_project) { create(:project, :public, namespace: group) }
      let_it_be(:private_project) { create(:project, :private, namespace: group) }

      context 'as a user' do
        before do
          sign_in(user)
        end

        it 'shows all children' do
          get :index, params: { group_id: group.to_param }, format: :json

          expect(assigns(:children)).to contain_exactly(public_subgroup, private_subgroup, public_project, private_project)
        end

        context 'being member of private subgroup' do
          it 'shows public and private children the user is member of' do
            group_member.destroy!
            private_subgroup.add_guest(user)
            private_project.add_guest(user)

            get :index, params: { group_id: group.to_param }, format: :json

            expect(assigns(:children)).to contain_exactly(public_subgroup, private_subgroup, public_project, private_project)
          end
        end
      end

      context 'as a guest' do
        it 'shows the public children' do
          get :index, params: { group_id: group.to_param }, format: :json

          expect(assigns(:children)).to contain_exactly(public_subgroup, public_project)
        end
      end

      context 'filtering children' do
        it 'expands the tree for matching projects' do
          project = create(:project, :public, namespace: public_subgroup, name: 'filterme')

          get :index, params: { group_id: group.to_param, filter: 'filter' }, format: :json

          group_json = json_response.first
          project_json = group_json['children'].first

          expect(group_json['id']).to eq(public_subgroup.id)
          expect(project_json['id']).to eq(project.id)
        end

        it 'expands the tree for matching subgroups' do
          matched_group = create(:group, :public, parent: public_subgroup, name: 'filterme')

          get :index, params: { group_id: group.to_param, filter: 'filter' }, format: :json

          group_json = json_response.first
          matched_group_json = group_json['children'].first

          expect(group_json['id']).to eq(public_subgroup.id)
          expect(matched_group_json['id']).to eq(matched_group.id)
        end

        it 'merges the trees correctly' do
          shared_subgroup = create(:group, :public, parent: group, path: 'hardware')
          matched_project_1 = create(:project, :public, namespace: shared_subgroup, name: 'mobile-soc')

          l2_subgroup = create(:group, :public, parent: shared_subgroup, path: 'broadcom')
          l3_subgroup = create(:group, :public, parent: l2_subgroup, path: 'wifi-group')
          matched_project_2 = create(:project, :public, namespace: l3_subgroup, name: 'mobile')

          get :index, params: { group_id: group.to_param, filter: 'mobile' }, format: :json

          shared_group_json = json_response.first
          expect(shared_group_json['id']).to eq(shared_subgroup.id)

          matched_project_1_json = shared_group_json['children'].detect { |child| child['type'] == 'project' }
          expect(matched_project_1_json['id']).to eq(matched_project_1.id)

          l2_subgroup_json = shared_group_json['children'].detect { |child| child['type'] == 'group' }
          expect(l2_subgroup_json['id']).to eq(l2_subgroup.id)

          l3_subgroup_json = l2_subgroup_json['children'].first
          expect(l3_subgroup_json['id']).to eq(l3_subgroup.id)

          matched_project_2_json = l3_subgroup_json['children'].first
          expect(matched_project_2_json['id']).to eq(matched_project_2.id)
        end

        it 'expands the tree upto a specified parent' do
          subgroup = create(:group, :public, parent: group)
          l2_subgroup = create(:group, :public, parent: subgroup)
          create(:project, :public, namespace: l2_subgroup, name: 'test')

          get :index, params: { group_id: subgroup.to_param, filter: 'test' }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns an array with one element when only one result is matched' do
          create(:project, :public, namespace: group, name: 'match')

          get :index, params: { group_id: group.to_param, filter: 'match' }, format: :json

          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
        end

        it 'returns an empty array when there are no search results' do
          subgroup = create(:group, :public, parent: group)
          l2_subgroup = create(:group, :public, parent: subgroup)
          create(:project, :public, namespace: l2_subgroup, name: 'no-match')

          get :index, params: { group_id: subgroup.to_param, filter: 'test' }, format: :json

          expect(json_response).to eq([])
        end

        it 'succeeds if multiple pages contain matching subgroups' do
          create(:group, parent: group, name: 'subgroup-filter-1')
          create(:group, parent: group, name: 'subgroup-filter-2')

          # Creating the group-to-nest first so it would be loaded into the
          # relation first before it's parents, this is what would cause the
          # crash in: https://gitlab.com/gitlab-org/gitlab-foss/issues/40785.
          #
          # If we create the parent groups first, those would be loaded into the
          # collection first, and the pagination would cut off the actual search
          # result. In this case the hierarchy can be rendered without crashing,
          # it's just incomplete.
          group_to_nest = create(:group, parent: group, name: 'subsubgroup-filter-3')
          subgroup = create(:group, parent: group)
          3.times do |i|
            subgroup = create(:group, parent: subgroup)
          end
          group_to_nest.update!(parent: subgroup)

          get :index, params: { group_id: group.to_param, filter: 'filter', per_page: 3 }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when items more than Kaminari.config.default_per_page' do
          let_it_be(:filter) { 'filtered-group' }
          let_it_be(:per_page) { 2 }
          let_it_be(:params) { { group_id: group.to_param, filter: filter } }
          let_it_be(:subgroups) { Array.new(per_page) { create(:group, parent: group) } }
          let_it_be(:sub_subgroups) { subgroups.map { |subgroup| create(:group, parent: subgroup) } }
          let_it_be(:matching_descendants) do
            sub_subgroups.map.with_index do |sub_subgroup, index|
              Array.new(per_page) do |descendant_index|
                formatted_index = "#{index}#{descendant_index}"
                create(:group, :public, parent: sub_subgroup, name: "#{filter}-#{formatted_index}")
              end
            end.flatten
          end

          before do
            allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
          end

          it 'does not throw ArgumentError for N+1 queries' do
            get :index, params: params, format: :json

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'paginates correctly' do
            expected_ids = [subgroups.last, sub_subgroups.last, matching_descendants.last(2)].flatten.pluck(:id)

            get :index, params: params.merge(page: 2), format: :json

            result_ids = descendant_ids(json_response)

            expect(result_ids).to match_array(expected_ids)
          end

          context 'with a single page' do
            let_it_be(:params) { params.merge(per_page: matching_descendants.size) }

            it 'returns the correct pagination headers with per_page' do
              get :index, params: params, format: :json

              expect(response.header).to match(hash_including(
                "X-Per-Page" => "4",
                "X-Page" => "1",
                "X-Next-Page" => "",
                "X-Prev-Page" => "",
                "X-Total" => "4",
                "X-Total-Pages" => "1"
              ))
            end
          end

          def descendant_ids(data)
            return [] if data.blank?

            data = Array.wrap(data)

            ids = []
            data.each do |item|
              ids << item['id']
              ids << descendant_ids(item['children'])
            end

            ids.flatten
          end
        end

        it 'includes pagination headers' do
          2.times { |i| create(:group, :public, parent: public_subgroup, name: "filterme#{i}") }

          get :index, params: { group_id: group.to_param, filter: 'filter', per_page: 1 }, format: :json

          expect(response).to include_pagination_headers
        end
      end

      context 'sorting children' do
        it 'allows sorting projects' do
          project_1 = create(:project, :public, namespace: group, name: 'mobile')
          project_2 = create(:project, :public, namespace: group, name: 'hardware')

          get :index, params: { group_id: group.to_param, sort: 'name_asc' }, format: :json

          expect(assigns(:children)).to eq([public_subgroup, project_2, project_1, public_project])
        end
      end

      context 'queries per rendered element', :request_store do
        # We need to make sure the following counts are preloaded
        # otherwise they will cause an extra query
        # 1. Count of visible projects in the element
        # 2. Count of visible subgroups in the element
        # 3. Count of members of a group
        let(:expected_queries_per_group) { 0 }
        let(:expected_queries_per_project) { 0 }

        def get_list
          get :index, params: { group_id: group.to_param }, format: :json
        end

        it 'queries the expected amount for a group row' do
          control = ActiveRecord::QueryRecorder.new { get_list }

          _new_group = create(:group, :public, parent: group)

          expect { get_list }.not_to exceed_query_limit(control).with_threshold(expected_queries_per_group)
        end

        it 'queries the expected amount for a project row' do
          control = ActiveRecord::QueryRecorder.new { get_list }
          _new_project = create(:project, :public, namespace: group)

          expect { get_list }.not_to exceed_query_limit(control).with_threshold(expected_queries_per_project + 1)
        end

        context 'when rendering hierarchies' do
          # When loading hierarchies we load the all the ancestors for matched projects
          # in 3 separate queries
          let(:extra_queries_for_hierarchies) { 3 }

          def get_filtered_list
            get :index, params: { group_id: group.to_param, filter: 'filter' }, format: :json
          end

          it 'queries the expected amount when nested rows are increased for a group' do
            matched_group = create(:group, :public, parent: group, name: 'filterme')

            control = ActiveRecord::QueryRecorder.new { get_filtered_list }

            matched_group.update!(parent: public_subgroup)

            expect { get_filtered_list }.not_to exceed_query_limit(control).with_threshold(extra_queries_for_hierarchies)
          end

          it 'queries the expected amount when a new group match is added' do
            create(:group, :public, parent: public_subgroup, name: 'filterme')

            control = ActiveRecord::QueryRecorder.new { get_filtered_list }

            create(:group, :public, parent: public_subgroup, name: 'filterme2')
            create(:group, :public, parent: public_subgroup, name: 'filterme3')

            expect { get_filtered_list }.not_to exceed_query_limit(control).with_threshold(extra_queries_for_hierarchies)
          end

          it 'queries the expected amount when nested rows are increased for a project' do
            matched_project = create(:project, :public, namespace: group, name: 'filterme')

            control = ActiveRecord::QueryRecorder.new { get_filtered_list }

            matched_project.update!(namespace: public_subgroup)

            expect { get_filtered_list }.not_to exceed_query_limit(control).with_threshold(extra_queries_for_hierarchies)
          end
        end
      end
    end

    context 'pagination' do
      let_it_be(:per_page) { 3 }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      end

      it 'rejects negative per_page parameter' do
        get :index, params: { group_id: group.to_param, per_page: -1 }, format: :json

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects non-numeric per_page parameter' do
        get :index, params: { group_id: group.to_param, per_page: 'abc' }, format: :json

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'with only projects' do
        let_it_be(:other_project) { create(:project, :public, namespace: group) }
        let_it_be(:first_page_projects) { create_list(:project, per_page, :public, namespace: group) }

        it 'has projects on the first page' do
          get :index, params: { group_id: group.to_param, sort: 'id_desc' }, format: :json

          expect(assigns(:children)).to contain_exactly(*first_page_projects)
        end

        it 'has projects on the second page' do
          get :index, params: { group_id: group.to_param, sort: 'id_desc', page: 2 }, format: :json

          expect(assigns(:children)).to contain_exactly(other_project)
        end
      end

      context 'with subgroups and projects' do
        let_it_be(:first_page_subgroups) { create_list(:group, per_page, :public, parent: group) }
        let_it_be(:other_subgroup) { create(:group, :public, parent: group) }
        let_it_be(:next_page_projects) { create_list(:project, per_page, :public, namespace: group) }

        it 'contains all subgroups' do
          get :index, params: { group_id: group.to_param, sort: 'id_asc' }, format: :json

          expect(assigns(:children)).to contain_exactly(*first_page_subgroups)
        end

        it 'contains the project and group on the second page' do
          get :index, params: { group_id: group.to_param, sort: 'id_asc', page: 2 }, format: :json

          expect(assigns(:children)).to contain_exactly(other_subgroup, *next_page_projects.take(per_page - 1))
        end

        context 'with a mixed first page' do
          let_it_be(:first_page_subgroups) { [create(:group, :public, parent: group)] }
          let_it_be(:first_page_projects) { create_list(:project, per_page, :public, namespace: group) }

          it 'correctly calculates the counts' do
            get :index, params: { group_id: group.to_param, sort: 'id_asc', page: 2 }, format: :json

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'external authorization' do
      it 'works when external authorization service is enabled' do
        enable_external_authorization_service_check

        get :index, params: { group_id: group }, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
