# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DesignManagement::Delete, feature_category: :api do
  include DesignManagementTestHelpers
  include GraphqlHelpers

  let(:issue) { create(:issue) }
  let(:current_designs) { issue.designs.current }
  let(:current_user) { issue.author }
  let(:project) { issue.project }
  let(:design_a) { create(:design, :with_file, issue: issue) }
  let(:design_b) { create(:design, :with_file, issue: issue) }
  let(:design_c) { create(:design, :with_file, issue: issue) }
  let(:filenames) { [design_a, design_b, design_c].map(&:filename) }

  let(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  before do
    stub_const('Errors', Gitlab::Graphql::Errors, transfer_nested_constants: true)
  end

  def run_mutation
    mutation = described_class.new(object: nil, context: query_context, field: nil)
    mutation.resolve(project_path: project.full_path, iid: issue.iid, filenames: filenames)
  end

  describe '#resolve' do
    let(:expected_response) do
      { errors: [], version: DesignManagement::Version.for_issue(issue).ordered.first }
    end

    shared_examples "failures" do |error: Gitlab::Graphql::Errors::ResourceNotAvailable|
      it "raises #{error.name}" do
        expect { run_mutation }.to raise_error(error)
      end
    end

    shared_examples "resource not available" do
      it_behaves_like "failures"
    end

    context "when the feature is not available" do
      before do
        enable_design_management(false)
      end

      it_behaves_like "resource not available"
    end

    context "when the feature is available" do
      before do
        enable_design_management(true)
      end

      context "when the user is not allowed to delete designs" do
        let(:current_user) { create(:user) }

        it_behaves_like "resource not available"
      end

      context 'deleting an already deleted file' do
        before do
          run_mutation
        end

        it 'fails with an argument error' do
          expect { run_mutation }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
        end
      end

      context "when deleting all the designs" do
        let(:response) { run_mutation }

        it "returns a new version, and no errors" do
          expect(response).to include(expected_response)
        end

        describe 'the current designs' do
          before do
            run_mutation
          end

          it 'is empty' do
            expect(current_designs).to be_empty
          end
        end

        it 'runs no more than 34 queries' do
          allow(Gitlab::Tracking).to receive(:event) # rubocop:disable RSpec/ExpectGitlabTracking
          allow(Gitlab::InternalEvents).to receive(:track_event)

          filenames.each(&:present?) # ignore setup
          # Queries: as of 2022-12-01
          # -------------
          # 01. for routes to find routes.source_id of projects matching paths
          # 02. Find projects with the above source id.
          # 03. preload routes of the above projects
          # 04. policy query: find namespace by type and id
          # 05. policy query: namespace_bans
          # 06. policy query: project.project_feature
          # 07,08. project.authorizations for user (same query twice)
          # 09. find issue by iid
          # 10. find project by id
          # 11. find namespace by id
          # 12. policy query: find namespace by type and id (same query as 4)
          # 13. project.authorizations for user (same query as 7)
          # 14. find user by id
          # 15. project.project_features (same query as 6)
          # 16. project.authorizations for user (same query as 7)
          # 17. current designs by filename and issue
          # 18, 19 project.authorizations for user (same query as 7)
          # 20. find design_management_repository for project
          # 21. find route by source_id and source_type
          # ------------- our queries are below:
          # 22. start transaction
          # 23.   create version with sha and issue
          # 24.   create design-version links
          # 25.   validate version.actions.present?
          # 26.   validate version.sha is unique
          # 27.   validate version.issue.present?
          # 28. leave transaction
          # 29. find project by id (same query as 10)
          # 30. find namespace by id (same query as 11)
          # 31. find project by id (same query as 10)
          # 32. find project by id (same query as 10)
          # 33. create event
          # 34. find plan for standard context
          # 35. find issue(work item) type, after query 09
          #
          expect { run_mutation }.not_to exceed_query_limit(35)
        end
      end

      context "when deleting a design" do
        let(:filenames) { [design_a.filename] }
        let(:response) { run_mutation }

        it "returns the expected response" do
          expect(response).to include(expected_response)
        end

        describe 'the current designs' do
          before do
            run_mutation
          end

          it 'does contain designs b and c' do
            expect(current_designs).to contain_exactly(design_b, design_c)
          end
        end
      end
    end
  end
end
