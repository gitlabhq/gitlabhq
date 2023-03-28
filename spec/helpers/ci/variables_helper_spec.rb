# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariablesHelper, feature_category: :secrets_management do
  describe '#ci_variable_maskable_raw_regex' do
    it 'converts to a javascript regex' do
      expect(helper.ci_variable_maskable_raw_regex).to eq("^\\S{8,}$")
    end
  end
end
