# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EmojiSkinTone'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('EmojiSkinTone') }

  it 'exposes every skin tone the preference can store' do
    expect(described_class.values.keys).to match_array(UserPreference.emoji_skin_tones.keys.map(&:upcase))
  end

  it 'maps each value to the stored enum key' do
    UserPreference.emoji_skin_tones.each_key do |tone|
      expect(described_class.values[tone.upcase].value).to eq(tone)
    end
  end
end
