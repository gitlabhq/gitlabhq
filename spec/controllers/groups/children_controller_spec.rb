require 'spec_helper'

describe Groups::ChildrenController do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }
  let!(:group_member) { create(:group_member, group: group, user: user) }

  describe 'GET #index' do
    context 'for projects' do
      let!(:public_project) { create(:project, :public, namespace: group) }
      let!(:private_project) { create(:project, :private, namespace: group) }

      context 'as a user' do
        before do
          sign_in(user)
        end

        it 'shows all children' do
          get :index, group_id: group.to_param, format: :json

          expect(assigns(:children)).to contain_exactly(public_project, private_project)
        end

        context 'being member of private subgroup' do
          it 'shows public and private children the user is member of' do
            group_member.destroy!
            private_project.add_guest(user)

            get :index, group_id: group.to_param, format: :json

            expect(assigns(:children)).to contain_exactly(public_project, private_project)
          end
        end
      end

      context 'as a guest' do
        it 'shows the public children' do
          get :index, group_id: group.to_param, format: :json

          expect(assigns(:children)).to contain_exactly(public_project)
        end
      end
    end

    context 'for subgroups', :nested_groups do
      let!(:public_subgroup) { create(:group, :public, parent: group) }
      let!(:private_subgroup) { create(:group, :private, parent: group) }
      let!(:public_project) { create(:project, :public, namespace: group) }
      let!(:private_project) { create(:project, :private, namespace: group) }

      context 'as a user' do
        before do
          sign_in(user)
        end

        it 'shows all children' do
          get :index, group_id: group.to_param, format: :json

          expect(assigns(:children)).to contain_exactly(public_subgroup, private_subgroup, public_project, private_project)
        end

        context 'being member of private subgroup' do
          it 'shows public and private children the user is member of' do
            group_member.destroy!
            private_subgroup.add_guest(user)
            private_project.add_guest(user)

            get :index, group_id: group.to_param, format: :json

            expect(assigns(:children)).to contain_exactly(public_subgroup, private_subgroup, public_project, private_project)
          end
        end
      end

      context 'as a guest' do
        it 'shows the public children' do
          get :index, group_id: group.to_param, format: :json

          expect(assigns(:children)).to contain_exactly(public_subgroup, public_project)
        end
      end

      context 'filtering children' do
        it 'expands the tree for matching projects' do
          project = create(:project, :public, namespace: public_subgroup, name: 'filterme')

          get :index, group_id: group.to_param, filter: 'filter', format: :json

          group_json = json_response.first
          project_json = group_json['children'].first

          expect(group_json['id']).to eq(public_subgroup.id)
          expect(project_json['id']).to eq(project.id)
        end

        it 'expands the tree for matching subgroups' do
          matched_group = create(:group, :public, parent: public_subgroup, name: 'filterme')

          get :index, group_id: group.to_param, filter: 'filter', format: :json

          group_json = json_response.first
          matched_group_json = group_json['children'].first

          expect(group_json['id']).to eq(public_subgroup.id)
          expect(matched_group_json['id']).to eq(matched_group.id)
        end

        it 'merges the trees correctly' do
          shared_subgroup = create(:group, :public, parent: group, path: 'hardware')
          matched_project_1 = create(:project, :public, namespace: shared_subgroup, name: 'mobile-soc')

          l2_subgroup = create(:group, :public, parent: shared_subgroup, path: 'broadcom')
          l3_subgroup = create(:group, :public,  parent: l2_subgroup, path: 'wifi-group')
          matched_project_2 = create(:project, :public, namespace: l3_subgroup, name: 'mobile')

          get :index, group_id: group.to_param, filter: 'mobile', format: :json

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

          get :index, group_id: subgroup.to_param, filter: 'test', format: :json

          expect(response).to have_http_status(200)
        end

        it 'returns an array with one element when only one result is matched' do
          create(:project, :public, namespace: group, name: 'match')

          get :index, group_id: group.to_param, filter: 'match', format: :json

          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
        end

        it 'returns an empty array when there are no search results' do
          subgroup = create(:group, :public, parent: group)
          l2_subgroup = create(:group, :public, parent: subgroup)
          create(:project, :public, namespace: l2_subgroup, name: 'no-match')

          get :index, group_id: subgroup.to_param, filter: 'test', format: :json

          expect(json_response).to eq([])
        end

        it 'succeeds if multiple pages contain matching subgroups' do
          create(:group, parent: group, name: 'subgroup-filter-1')
          create(:group, parent: group, name: 'subgroup-filter-2')

          # Creating the group-to-nest first so it would be loaded into the
          # relation first before it's parents, this is what would cause the
          # crash in: https://gitlab.com/gitlab-org/gitlab-ce/issues/40785.
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

          get :index, group_id: group.to_param, filter: 'filter', per_page: 3, format: :json

          expect(response).to have_gitlab_http_status(200)
        end

        it 'includes pagination headers' do
          2.times { |i| create(:group, :public, parent: public_subgroup, name: "filterme#{i}") }

          get :index, group_id: group.to_param, filter: 'filter', per_page: 1, format: :json

          expect(response).to include_pagination_headers
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
          get :index, group_id: group.to_param, format: :json
        end

        it 'queries the expected amount for a group row' do
          control = ActiveRecord::QueryRecorder.new { get_list }

          _new_group = create(:group, :public, parent: group)

          expect { get_list }.not_to exceed_query_limit(control).with_threshold(expected_queries_per_group)
        end

        it 'queries the expected amount for a project row' do
          control = ActiveRecord::QueryRecorder.new { get_list }
          _new_project = create(:project, :public, namespace: group)

          expect { get_list }.not_to exceed_query_limit(control).with_threshold(expected_queries_per_project)
        end

        context 'when rendering hierarchies' do
          # When loading hierarchies we load the all the ancestors for matched projects
          # in 1 separate query
          let(:extra_queries_for_hierarchies) { 1 }

          def get_filtered_list
            get :index, group_id: group.to_param, filter: 'filter', format: :json
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
      let(:per_page) { 3 }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      end

      context 'with only projects' do
        let!(:other_project) { create(:project, :public, namespace: group) }
        let!(:first_page_projects) { create_list(:project, per_page, :public, namespace: group ) }

        it 'has projects on the first page' do
          get :index, group_id: group.to_param, sort: 'id_desc', format: :json

          expect(assigns(:children)).to contain_exactly(*first_page_projects)
        end

        it 'has projects on the second page' do
          get :index, group_id: group.to_param, sort: 'id_desc', page: 2, format: :json

          expect(assigns(:children)).to contain_exactly(other_project)
        end
      end

      context 'with subgroups and projects', :nested_groups do
        let!(:first_page_subgroups) { create_list(:group,  per_page, :public,  parent: group) }
        let!(:other_subgroup) { create(:group, :public, parent: group) }
        let!(:next_page_projects) { create_list(:project, per_page, :public, namespace: group) }

        it 'contains all subgroups' do
          get :index, group_id: group.to_param, sort: 'id_asc', format: :json

          expect(assigns(:children)).to contain_exactly(*first_page_subgroups)
        end

        it 'contains the project and group on the second page' do
          get :index, group_id: group.to_param, sort: 'id_asc', page: 2, format: :json

          expect(assigns(:children)).to contain_exactly(other_subgroup, *next_page_projects.take(per_page - 1))
        end

        context 'with a mixed first page' do
          let!(:first_page_subgroups) { [create(:group,  :public,  parent: group)] }
          let!(:first_page_projects) { create_list(:project, per_page, :public, namespace: group) }

          it 'correctly calculates the counts' do
            get :index, group_id: group.to_param, sort: 'id_asc', page: 2, format: :json

            expect(response).to have_gitlab_http_status(200)
          end
        end
      end
    end
  end
end
