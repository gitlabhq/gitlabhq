require 'spec_helper'

describe Appearance do
  subject { build(:appearance) }

  describe 'validations' do
    let(:triplet) { '#000' }
    let(:hex)     { '#AABBCC' }

    it { is_expected.to allow_value(nil).for(:background_color) }
    it { is_expected.to allow_value(triplet).for(:background_color) }
    it { is_expected.to allow_value(hex).for(:background_color) }
    it { is_expected.not_to allow_value('000').for(:background_color) }

    it { is_expected.to allow_value(nil).for(:font_color) }
    it { is_expected.to allow_value(triplet).for(:font_color) }
    it { is_expected.to allow_value(hex).for(:font_color) }
    it { is_expected.not_to allow_value('000').for(:font_color) }
  end
end
