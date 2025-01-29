# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::BuildInfosFinder do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package) { create(:generic_package) }
  let_it_be(:build_infos) { create_list(:package_build_info, 5, :with_pipeline, package: package) }
  let_it_be(:build_info_with_empty_pipeline) { create(:package_build_info, package: package) }

  let_it_be(:other_package) { create(:generic_package) }
  let_it_be(:other_build_infos) { create_list(:package_build_info, 5, :with_pipeline, package: other_package) }
  let_it_be(:other_build_info_with_empty_pipeline) { create(:package_build_info, package: other_package) }

  let_it_be(:all_build_infos) { build_infos + other_build_infos }

  let(:finder) { described_class.new(packages, params) }
  let(:packages) { nil }
  let(:first) { nil }
  let(:last) { nil }
  let(:after) { nil }
  let(:before) { nil }
  let(:max_page_size) { nil }
  let(:support_next_page) { false }
  let(:params) do
    {
      first: first,
      last: last,
      after: after,
      before: before,
      max_page_size: max_page_size,
      support_next_page: support_next_page
    }
  end

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'returning the expected build infos' do
      let(:expected_build_infos) do
        expected_build_infos_indexes.map do |idx|
          all_build_infos[idx]
        end
      end

      let(:after) do
        all_build_infos[after_index].pipeline_id if after_index
      end

      let(:before) do
        all_build_infos[before_index].pipeline_id if before_index
      end

      it { is_expected.to eq(expected_build_infos) }
    end

    context 'with nil packages' do
      let(:packages) { nil }

      it { is_expected.to be_empty }
    end

    context 'with [] packages' do
      let(:packages) { [] }

      it { is_expected.to be_empty }
    end

    context 'with empy scope packages' do
      let(:packages) { Packages::Package.none }

      it { is_expected.to be_empty }
    end

    context 'with a single package' do
      let(:packages) { package.id }

      # rubocop: disable Layout/LineLength
      where(:first, :last, :after_index, :before_index, :max_page_size, :support_next_page, :expected_build_infos_indexes) do
        # F   L     AI    BI    MPS   SNP
        nil | nil | nil | nil | nil | false | [4, 3, 2, 1, 0]
        nil | nil | nil | nil | 10  | false | [4, 3, 2, 1, 0]
        nil | nil | nil | nil | 2   | false | [4, 3]
        2   | nil | nil | nil | nil | false | [4, 3]
        2   | nil | nil | nil | nil | true  | [4, 3, 2]
        2   | nil | 3   | nil | nil | false | [2, 1]
        2   | nil | 3   | nil | nil | true  | [2, 1, 0]
        3   | nil | 4   | nil | 2   | false | [3, 2]
        3   | nil | 4   | nil | 2   | true  | [3, 2, 1]
        nil | 2   | nil | nil | nil | false | [1, 0]
        nil | 2   | nil | nil | nil | true  | [2, 1, 0]
        nil | 2   | nil | 1   | nil | false | [3, 2]
        nil | 2   | nil | 1   | nil | true  | [4, 3, 2]
        nil | 3   | nil | 0   | 2   | false | [2, 1]
        nil | 3   | nil | 0   | 2   | true  | [3, 2, 1]
      end
      # rubocop: enable Layout/LineLength

      with_them do
        it_behaves_like 'returning the expected build infos'
      end
    end

    context 'with many packages' do
      let(:packages) { [package.id, other_package.id] }

      # using after_index/before_index when receiving multiple packages doesn't
      # make sense but we still verify here that the behavior is coherent.
      # rubocop: disable Layout/LineLength
      where(:first, :last, :after_index, :before_index, :max_page_size, :support_next_page, :expected_build_infos_indexes) do
        # F   L     AI    BI    MPS   SNP
        nil | nil | nil | nil | nil | false | [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
        nil | nil | nil | nil | 10  | false | [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
        nil | nil | nil | nil | 2   | false | [9, 8, 4, 3]
        2   | nil | nil | nil | nil | false | [9, 8, 4, 3]
        2   | nil | nil | nil | nil | true  | [9, 8, 7, 4, 3, 2]
        2   | nil | 3   | nil | nil | false | [2, 1]
        2   | nil | 3   | nil | nil | true  | [2, 1, 0]
        3   | nil | 4   | nil | 2   | false | [3, 2]
        3   | nil | 4   | nil | 2   | true  | [3, 2, 1]
        nil | 2   | nil | nil | nil | false | [6, 5, 1, 0]
        nil | 2   | nil | nil | nil | true  | [7, 6, 5, 2, 1, 0]
        nil | 2   | nil | 1   | nil | false | [6, 5, 3, 2]
        nil | 2   | nil | 1   | nil | true  | [7, 6, 5, 4, 3, 2]
        nil | 3   | nil | 0   | 2   | false | [6, 5, 2, 1]
        nil | 3   | nil | 0   | 2   | true  | [7, 6, 5, 3, 2, 1]
      end

      with_them do
        it_behaves_like 'returning the expected build infos'
      end
      # rubocop: enable Layout/LineLength
    end
  end
end
