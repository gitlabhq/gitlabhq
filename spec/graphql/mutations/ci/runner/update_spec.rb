# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Update, feature_category: :runner_fleet do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }

  let(:runner) do
    create(:ci_runner, :project, projects: [project1, project2], active: true, locked: false, run_untagged: true)
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
        expect { response }.to raise_error(ArgumentError, "Arguments must be provided: id")
      end
    end

    context 'when user can update runner', :enable_admin_mode do
      let_it_be(:admin_user) { create(:user, :admin) }

      let(:current_ctx) { { current_user: admin_user } }

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
            tag_list: %w(tag1 tag2)
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
        let_it_be(:project3) { create(:project) }

        context 'with id set to project runner' do
          let(:mutation_params) do
            {
              id: runner.to_global_id,
              description: 'updated description',
              associated_projects: [project3.to_global_id.to_s]
            }
          end

          it 'updates runner attributes and project relationships', :aggregate_failures do
            expect_next_instance_of(
              ::Ci::Runners::SetRunnerAssociatedProjectsService,
              {
                runner: runner,
                current_user: admin_user,
                project_ids: [project3.id]
              }
            ) do |service|
              expect(service).to receive(:execute).and_call_original
            end

            expected_attributes = mutation_params.except(:id, :associated_projects)

            response

            expect(response[:errors]).to be_empty
            expect(response[:runner]).to be_an_instance_of(Ci::Runner)
            expect(response[:runner]).to have_attributes(expected_attributes)
            expect(runner.reload).to have_attributes(expected_attributes)
            expect(runner.projects).to match_array([project1, project3])
          end

          context 'with user not allowed to assign runner' do
            before do
              allow(admin_user).to receive(:can?).with(:assign_runner, runner).and_return(false)
            end

            it 'does not update runner', :aggregate_failures do
              expect_next_instance_of(
                ::Ci::Runners::SetRunnerAssociatedProjectsService,
                {
                  runner: runner,
                  current_user: admin_user,
                  project_ids: [project3.id]
                }
              ) do |service|
                expect(service).to receive(:execute).and_call_original
              end

              expected_attributes = mutation_params.except(:id, :associated_projects)

              response

              expect(response[:errors]).to match_array(['user not allowed to assign runner'])
              expect(response[:runner]).to be_nil
              expect(runner.reload).not_to have_attributes(expected_attributes)
              expect(runner.projects).to match_array([project1, project2])
            end
          end
        end

        context 'with an empty list of projects' do
          let(:mutation_params) do
            {
              id: runner.to_global_id,
              associated_projects: []
            }
          end

          it 'removes project relationships', :aggregate_failures do
            expect_next_instance_of(
              ::Ci::Runners::SetRunnerAssociatedProjectsService,
              {
                runner: runner,
                current_user: admin_user,
                project_ids: []
              }
            ) do |service|
              expect(service).to receive(:execute).and_call_original
            end

            response

            expect(response[:errors]).to be_empty
            expect(response[:runner]).to be_an_instance_of(Ci::Runner)
            expect(runner.reload.projects).to contain_exactly(project1)
          end
        end

        context 'with id set to instance runner' do
          let(:instance_runner) { create(:ci_runner, :instance) }
          let(:mutation_params) do
            {
              id: instance_runner.to_global_id,
              description: 'updated description',
              associated_projects: [project2.to_global_id.to_s]
            }
          end

          it 'raises error', :aggregate_failures do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
              response
            end
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
