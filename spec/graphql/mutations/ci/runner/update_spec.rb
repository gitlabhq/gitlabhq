# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Update, feature_category: :runner do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project, organization: project1.organization) }

  let(:runner) do
    create(:ci_runner, :project, projects: [project1, project2], locked: false, run_untagged: true)
  end

  let(:current_ctx) { { current_user: user } }
  let(:mutated_runner) { response[:runner] }

  let(:mutation_params) do
    {
      id: runner.to_global_id,
      description: 'updated description'
    }
  end

  specify { expect(described_class).to require_graphql_authorizations(:update_runner) }

  describe '#resolve' do
    subject(:response) do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when the user cannot admin the runner' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          response
        end
      end
    end

    context 'when required arguments are missing' do
      let(:mutation_params) { {} }

      it 'raises an error' do
        expect { response }.to raise_error(ArgumentError, "missing keyword: :id")
      end
    end

    context 'when user can update runner' do
      let_it_be(:user) { create(:user) }

      let(:original_projects) { [project1, project2] }
      let(:projects_with_maintainer_access) { original_projects }

      let(:current_ctx) { { current_user: user } }

      before do
        projects_with_maintainer_access.each { |project| project.add_maintainer(user) }
      end

      context 'with valid arguments' do
        let(:mutation_params) do
          {
            id: runner.to_global_id,
            description: 'updated description',
            maintenance_note: 'updated maintenance note',
            maximum_timeout: 900,
            access_level: 'ref_protected',
            active: false,
            locked: true,
            run_untagged: false,
            tag_list: %w[tag1 tag2]
          }
        end

        it 'updates runner with correct values' do
          expected_attributes = mutation_params.except(:id, :tag_list)

          response

          expect(response[:errors]).to be_empty
          expect(response[:runner]).to be_an_instance_of(Ci::Runner)
          expect(response[:runner]).to have_attributes(expected_attributes)
          expect(response[:runner].tag_list).to contain_exactly(*mutation_params[:tag_list])
          expect(runner.reload).to have_attributes(expected_attributes)
          expect(runner.tag_list).to contain_exactly(*mutation_params[:tag_list])
        end
      end

      context 'with associatedProjects argument' do
        let_it_be(:project3) { create(:project, organization: project1.organization) }
        let_it_be(:project4) { create(:project, organization: project1.organization) }

        let(:new_projects) { [project3, project4] }
        let(:mutation_params) do
          {
            id: runner.to_global_id,
            description: 'updated description',
            associated_projects: new_projects.map { |project| project.to_global_id.to_s }
          }
        end

        context 'with id set to project runner' do
          let(:projects_with_maintainer_access) { original_projects + new_projects }

          it 'updates runner attributes and project relationships', :aggregate_failures do
            setup_service_expectations

            expected_attributes = mutation_params.except(:id, :associated_projects)

            response

            expect(response[:errors]).to be_empty
            expect(response[:runner]).to be_an_instance_of(Ci::Runner)
            expect(response[:runner]).to have_attributes(expected_attributes)
            expect(runner.reload).to have_attributes(expected_attributes)
            expect(runner.projects).to match_array([project1] + new_projects)
          end

          context 'with missing permissions on one of the new projects' do
            let(:projects_with_maintainer_access) { original_projects + [project3] }

            it 'does not update runner', :aggregate_failures do
              setup_service_expectations

              expected_attributes = mutation_params.except(:id, :associated_projects)

              response

              expect(response[:errors]).to match_array(['user is not authorized to add runners to project'])
              expect(response[:runner]).to be_nil
              expect(runner.reload).not_to have_attributes(expected_attributes)
              expect(runner.projects).to match_array(original_projects)
            end
          end
        end

        context 'with an empty list of projects' do
          let(:new_projects) { [] }

          it 'removes project relationships', :aggregate_failures do
            setup_service_expectations

            response

            expect(response[:errors]).to be_empty
            expect(response[:runner]).to be_an_instance_of(Ci::Runner)
            expect(runner.reload.projects).to contain_exactly(project1)
          end
        end

        context 'with id set to instance runner', :enable_admin_mode do
          let_it_be(:user) { create(:user, :admin) }
          let_it_be(:runner) { create(:ci_runner, :instance) }

          it 'raises error', :aggregate_failures do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
              response
            end
          end
        end

        def setup_service_expectations
          expect_next_instance_of(
            ::Ci::Runners::SetRunnerAssociatedProjectsService,
            {
              runner: runner,
              current_user: user,
              project_ids: new_projects.map(&:id)
            }
          ) do |service|
            expect(service).to receive(:execute).and_call_original
          end
        end
      end

      context 'with non-existing project ID in associatedProjects argument' do
        let(:mutation_params) do
          {
            id: runner.to_global_id,
            associated_projects: ["gid://gitlab/Project/#{non_existing_record_id}"]
          }
        end

        it 'does not change associated projects' do
          expected_attributes = mutation_params.except(:id, :associated_projects)

          response

          expect(response[:errors]).to be_empty
          expect(response[:runner]).to be_an_instance_of(Ci::Runner)
          expect(response[:runner]).to have_attributes(expected_attributes)
          expect(runner.reload).to have_attributes(expected_attributes)
          expect(runner.projects).to match_array([project1])
        end
      end

      context 'with out-of-range maximum_timeout and missing tag_list' do
        let(:mutation_params) do
          {
            id: runner.to_global_id,
            maximum_timeout: 100,
            run_untagged: false
          }
        end

        it 'returns a descriptive error' do
          expect(response[:runner]).to be_nil
          expect(response[:errors]).to contain_exactly(
            'Maximum timeout needs to be at least 10 minutes',
            'Tags list can not be empty when runner is not allowed to pick untagged jobs'
          )
        end
      end

      context 'with too long maintenance note' do
        it 'returns a descriptive error' do
          mutation_params[:maintenance_note] = '1' * 1025

          expect(response[:runner]).to be_nil
          expect(response[:errors]).to contain_exactly(
            'Maintenance note is too long (maximum is 1024 characters)'
          )
        end
      end
    end
  end
end
