# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/push_options'

RSpec.describe ::Gitlab::Housekeeper::PushOptions do
  describe '#initialize' do
    it 'sets ci_skip to false by default' do
      push_options = described_class.new
      expect(push_options.ci_skip).to be false
    end
  end
end
