# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DesignManagement::Delete do
  include DesignManagementTestHelpers

  let(:issue) { create(:issue) }
  let(:current_designs) { issue.designs.current }
  let(:user) { issue.author }
  let(:project) { issue.project }
  let(:design_a) { create(:design, :with_file, issue: issue) }
  let(:design_b) { create(:design, :with_file, issue: issue) }
  let(:design_c) { create(:design, :with_file, issue: issue) }
  let(:filenames) { [design_a, design_b, design_c].map(&:filename) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_const('Errors', Gitlab::Graphql::Errors, transfer_nested_constants: true)
  end

  def run_mutation
    mutation = described_class.new(object: nil, context: { current_user: user }, field: nil)
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
        let(:user) { create(:user) }

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

        it 'runs no more than 31 queries' do
          allow(Gitlab::Tracking).to receive(:event) # rubocop:disable RSpec/ExpectGitlabTracking

          filenames.each(&:present?) # ignore setup
          # Queries: as of 2022-06-15
          # -------------
          # 01. routing query
          # 02. find project by id
          # 03. project.project_features
          # 04. find namespace by id and type
          # 05,06. project.authorizations for user (same query twice)
          # 07. find issue by iid
          # 08. find project by id
          # 09. find namespace by id
          # 10. find group namespace by id
          # 11. project.authorizations for user (same query as 5)
          # 12. find user by id
          # 13. project.project_features (same query as 3)
          # 14. project.authorizations for user (same query as 5)
          # 15. current designs by filename and issue
          # 16, 17 project.authorizations for user (same query as 5)
          # 18. find design_management_repository for project
          # 19. find route by id and source_type
          # 20. find plan for standard context
          # ------------- our queries are below:
          # 21. start transaction 1
          # 22.   start transaction 2
          # 23.     find version by sha and issue
          # 24.     exists version with sha and issue?
          # 25.   leave transaction 2
          # 26.   create version with sha and issue
          # 27.   create design-version links
          # 28.   validate version.actions.present?
          # 29.   validate version.issue.present?
          # 30.   validate version.sha is unique
          # 31. leave transaction 1
          #
          expect { run_mutation }.not_to exceed_query_limit(31)
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
