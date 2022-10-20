# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestonesHelper do
  let_it_be(:issuable) { build(:merge_request) }

  describe '#milestone_header_class' do
    using RSpec::Parameterized::TableSyntax

    color_primary = 'gl-bg-blue-500 gl-text-white'
    border_empty = 'gl-border-bottom-0 gl-rounded-base'

    where(:primary, :issuables, :header_color, :header_border) do
      true  | [issuable] | color_primary | ''
      true  | []         | color_primary | border_empty
      false | []         | ''            | border_empty
      false | [issuable] | ''            | ''
    end

    with_them do
      subject { helper.milestone_header_class(primary, issuables) }

      it { is_expected.to eq("#{header_color} #{header_border} gl-display-flex") }
    end
  end

  describe '#milestone_counter_class' do
    context 'when primary is set to true' do
      subject { helper.milestone_counter_class(true) }

      it { is_expected.to eq('gl-text-white') }
    end

    context 'when primary is set to false' do
      subject { helper.milestone_counter_class(false) }

      it { is_expected.to eq('gl-text-gray-500') }
    end
  end
end
