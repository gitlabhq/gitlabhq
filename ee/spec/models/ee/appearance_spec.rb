require 'spec_helper'

describe Appearance do
  subject { build(:appearance) }

  describe 'validations' do
    let(:triplet) { '#000' }
    let(:hex)     { '#AABBCC' }

    it { is_expected.to allow_value(nil).for(:message_background_color) }
    it { is_expected.to allow_value(triplet).for(:message_background_color) }
    it { is_expected.to allow_value(hex).for(:message_background_color) }
    it { is_expected.not_to allow_value('000').for(:message_background_color) }

    it { is_expected.to allow_value(nil).for(:message_font_color) }
    it { is_expected.to allow_value(triplet).for(:message_font_color) }
    it { is_expected.to allow_value(hex).for(:message_font_color) }
    it { is_expected.not_to allow_value('000').for(:message_font_color) }
  end
end
