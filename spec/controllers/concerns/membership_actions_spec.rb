# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MembershipActions, feature_category: :user_management do
  let(:controller) do
    klass = Class.new do
      def self.before_action(action = nil, params = nil); end

      include MembershipActions

      def get_source
        source
      end
    end

    klass.new
  end

  describe '#source' do
    it 'raises an error if not implemented' do
      expect { controller.get_source }.to raise_error(NotImplementedError)
    end
  end
end
