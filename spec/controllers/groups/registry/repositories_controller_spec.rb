# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Registry::RepositoriesController do
  let_it_be(:user)  { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group, reload: true) { create(:group) }

  let(:additional_parameters) { {} }

  subject do
    get :index, params: additional_parameters.merge({
      group_id: group,
      format: format
    })
  end

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
    group.add_owner(user)
    group.add_guest(guest)
    sign_in(user)
  end

  shared_examples 'renders a list of repositories' do
    let_it_be(:repo) { create_project_with_repo(test_group) }

    it 'returns a list of projects for json format' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_kind_of(Array)
      expect(json_response.first).to include(
        'id' => repo.id,
        'name' => repo.name
      )
    end
  end

  shared_examples 'with name parameter' do
    let_it_be(:project) { create(:project, group: test_group) }
    let_it_be(:repo) { create(:container_repository, project: project, name: 'my_searched_image') }
    let_it_be(:another_repo) { create(:container_repository, project: project, name: 'bar') }

    let(:additional_parameters) { { name: 'my_searched_image' } }

    it 'returns the searched repo' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.length).to eq 1
      expect(json_response.first).to include(
        'id' => repo.id,
        'name' => repo.name
      )
    end
  end

  shared_examples 'renders correctly' do
    context 'when user has access to registry' do
      let_it_be(:test_group) { group }

      context 'html format' do
        let(:format) { :html }

        it 'show index page', :snowplow do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect_no_snowplow_event
        end
      end

      context 'json format' do
        let(:format) { :json }
        let(:namespace) { group }
        let(:snowplow_gitlab_standard_context) { { user: user, namespace: group } }

        it 'has the correct response schema' do
          subject

          expect(response).to match_response_schema('registry/repositories')
          expect(response).to include_pagination_headers
        end

        it_behaves_like 'renders a list of repositories'

        it_behaves_like 'with name parameter'

        it_behaves_like 'a package tracking event', described_class.name, 'list_repositories'

        context 'with project in subgroup' do
          let_it_be(:test_group) { create(:group, parent: group ) }

          it_behaves_like 'renders a list of repositories'

          it_behaves_like 'with name parameter'

          context 'with project in subgroup and group' do
            let_it_be(:repo_in_test_group) { create_project_with_repo(test_group) }
            let_it_be(:repo_in_group) { create_project_with_repo(group) }

            it 'returns all the projects' do
              subject

              expect(json_response).to be_kind_of(Array)
              expect(json_response.length).to eq 2
            end

            it_behaves_like 'with name parameter'
          end
        end
      end
    end

    context 'user does not have access to container registry' do
      before do
        sign_out(user)
        sign_in(guest)
      end

      context 'json format' do
        let(:format) { :json }

        it_behaves_like 'returning response status', :not_found
      end

      context 'html format' do
        let(:format) { :html }

        it_behaves_like 'returning response status', :not_found
      end
    end
  end

  context 'GET #index' do
    it_behaves_like 'renders correctly'
  end

  context 'GET #show' do
    it_behaves_like 'renders correctly'
  end

  def create_project_with_repo(group)
    project = create(:project, group: test_group)
    create(:container_repository, project: project)
  end
end
