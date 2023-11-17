# frozen_string_literal: true

require "spec_helper"

RSpec.describe Repositories::TreeFinder, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user) }

  let(:repository) { project.repository }
  let(:tree_finder) { described_class.new(project, params) }
  let(:params) { {} }
  let(:first_page_ids) { tree_finder.execute.map(&:id) }
  let(:second_page_token) { first_page_ids.last }

  describe "#execute" do
    subject { tree_finder.execute(gitaly_pagination: true) }

    it "returns an array" do
      is_expected.to be_an(Array)
    end

    it "includes 20 items by default" do
      expect(subject.size).to eq(20)
    end

    it "accepts a gitaly_pagination argument" do
      expect(repository).to receive(:tree).with(anything, anything, recursive: nil, rescue_not_found: nil, pagination_params: { limit: 20, page_token: nil }).and_call_original
      expect(tree_finder.execute(gitaly_pagination: true)).to be_an(Array)

      expect(repository).to receive(:tree).with(anything, anything, recursive: nil, rescue_not_found: nil).and_call_original
      expect(tree_finder.execute(gitaly_pagination: false)).to be_an(Array)
    end

    context "commit doesn't exist" do
      let(:params) do
        { ref: "nonesuchref" }
      end

      it "raises an error" do
        expect { subject }.to raise_error(described_class::CommitMissingError)
      end
    end

    describe "pagination_params" do
      let(:params) do
        { per_page: 5, page_token: nil }
      end

      it "has the per_page number of items" do
        expect(subject.size).to eq(5)
      end

      it "doesn't include any of the first page records" do
        first_page_ids = subject.map(&:id)
        second_page = described_class.new(project, { per_page: 5, page_token: first_page_ids.last }).execute(gitaly_pagination: true)

        expect(second_page.map(&:id)).not_to include(*first_page_ids)
      end
    end
  end

  describe '#next_cursor' do
    subject { tree_finder.next_cursor }

    it 'always nil before #execute call' do
      is_expected.to be_nil
    end

    context 'after #execute' do
      context 'with gitaly pagination' do
        before do
          tree_finder.execute(gitaly_pagination: true)
        end

        context 'without pagination params' do
          it { is_expected.to be_present }
        end

        context 'with pagination params' do
          let(:params) { { per_page: 5 } }

          it { is_expected.to be_present }

          context 'when all objects can be returned on the same page' do
            let(:params) { { per_page: 100 } }

            it { is_expected.to eq('') }
          end
        end
      end

      context 'without gitaly pagination' do
        before do
          tree_finder.execute(gitaly_pagination: false)
        end

        context 'without pagination params' do
          it { is_expected.to be_nil }
        end

        context 'with pagination params' do
          let(:params) { { per_page: 5 } }

          it { is_expected.to be_nil }

          context 'when all objects can be returned on the same page' do
            let(:params) { { per_page: 100 } }

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end

  describe "#total", :use_clean_rails_memory_store_caching do
    subject { tree_finder.total }

    it { is_expected.to be_an(Integer) }

    it "only calculates the total once" do
      expect(repository).to receive(:tree).once.and_call_original

      2.times { tree_finder.total }
    end
  end

  describe "#commit_exists?" do
    subject { tree_finder.commit_exists? }

    context "ref exists" do
      let(:params) do
        { ref: project.default_branch }
      end

      it { is_expected.to be(true) }
    end

    context "ref is missing" do
      let(:params) do
        { ref: "nonesuchref" }
      end

      it { is_expected.to be(false) }
    end
  end
end
