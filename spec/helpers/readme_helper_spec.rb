# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReadmeHelper, feature_category: :source_code_management do
  it 'returns a hash' do
    expect(helper.vue_readme_header_additional_data).to be_a(Hash)
  end
end
