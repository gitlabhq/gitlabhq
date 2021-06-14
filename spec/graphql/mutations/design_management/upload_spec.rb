# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::DesignManagement::Upload do
  include DesignManagementTestHelpers
  include ConcurrentHelpers

  let(:issue) { create(:issue) }
  let(:user) { issue.author }
  let(:project) { issue.project }

  subject(:mutation) do
    described_class.new(object: nil, context: { current_user: user }, field: nil)
  end

  def run_mutation(files_to_upload = files, project_path = project.full_path, iid = issue.iid)
    mutation = described_class.new(object: nil, context: { current_user: user }, field: nil)
    mutation.resolve(project_path: project_path, iid: iid, files: files_to_upload)
  end

  describe "#resolve" do
    let(:files) { [fixture_file_upload('spec/fixtures/dk.png')] }

    subject(:resolve) do
      mutation.resolve(project_path: project.full_path, iid: issue.iid, files: files)
    end

    shared_examples "resource not available" do
      it "raises an error" do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context "when the feature is not available" do
      before do
        enable_design_management(false)
      end

      it_behaves_like "resource not available"
    end

    context "when the feature is available" do
      before do
        enable_design_management
      end

      describe 'contention in the design repo' do
        before do
          issue.design_collection.repository.create_if_not_exists
        end

        let(:files) do
          ['dk.png', 'rails_sample.jpg', 'banana_sample.gif']
           .cycle
           .take(Concurrent.processor_count * 2)
           .map { |f| RenameableUpload.unique_file(f) }
        end

        def creates_designs(&block)
          prior_count = DesignManagement::Design.count

          expect(&block).not_to raise_error

          expect(DesignManagement::Design.count).to eq(prior_count + files.size)
        end

        describe 'running requests in parallel' do
          it 'does not cause errors' do
            creates_designs do
              run_parallel(files.map { |f| -> { run_mutation([f]) } })
            end
          end
        end

        describe 'running requests in parallel on different issues' do
          it 'does not cause errors' do
            creates_designs do
              issues = create_list(:issue, files.size, author: user)
              issues.each { |i| i.project.add_developer(user) }
              blocks = files.zip(issues).map do |(f, i)|
                -> { run_mutation([f], i.project.full_path, i.iid) }
              end

              run_parallel(blocks)
            end
          end
        end

        describe 'running requests in serial' do
          it 'does not cause errors' do
            creates_designs do
              files.each do |f|
                run_mutation([f])
              end
            end
          end
        end
      end

      context "when the user is not allowed to upload designs" do
        let(:user) { create(:user) }

        it_behaves_like "resource not available"
      end

      context "with a valid design" do
        it "returns the updated designs" do
          expect(resolve[:errors]).to be_empty
          expect(resolve[:designs].map(&:filename)).to contain_exactly("dk.png")
        end
      end

      context "when passing an invalid project" do
        let(:project) { build(:project) }

        it_behaves_like "resource not available"
      end

      context "when passing an invalid issue" do
        let(:issue) { build(:issue) }

        it_behaves_like "resource not available"
      end

      context "when creating designs causes errors" do
        before do
          fake_service = double(::DesignManagement::SaveDesignsService)

          allow(fake_service).to receive(:execute).and_return(status: :error, message: "Something failed")
          allow(::DesignManagement::SaveDesignsService).to receive(:new).and_return(fake_service)
        end

        it "wraps the errors" do
          expect(resolve[:errors]).to eq(["Something failed"])
          expect(resolve[:designs]).to eq([])
        end
      end
    end
  end
end
