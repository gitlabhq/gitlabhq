# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::BuildInfosFinder do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package) { create(:package) }
  let_it_be(:build_infos) { create_list(:package_build_info, 5, :with_pipeline, package: package) }
  let_it_be(:build_info_with_empty_pipeline) { create(:package_build_info, package: package) }

  let(:finder) { described_class.new(package, params) }
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
      nil | 2   | nil | nil | nil | false | [0, 1]
      nil | 2   | nil | nil | nil | true  | [0, 1, 2]
      nil | 2   | nil | 1   | nil | false | [2, 3]
      nil | 2   | nil | 1   | nil | true  | [2, 3, 4]
      nil | 3   | nil | 0   | 2   | false | [1, 2]
      nil | 3   | nil | 0   | 2   | true  | [1, 2, 3]
    end

    with_them do
      let(:expected_build_infos) do
        expected_build_infos_indexes.map do |idx|
          build_infos[idx]
        end
      end

      let(:after) do
        build_infos[after_index].pipeline_id if after_index
      end

      let(:before) do
        build_infos[before_index].pipeline_id if before_index
      end

      it { is_expected.to eq(expected_build_infos) }
    end
  end
end
