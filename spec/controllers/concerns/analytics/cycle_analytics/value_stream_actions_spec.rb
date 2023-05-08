# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreamActions, type: :controller,
  feature_category: :team_planning do
  subject(:controller) do
    Class.new(ApplicationController) do
      include Analytics::CycleAnalytics::ValueStreamActions

      def call_namespace
        namespace
      end
    end
  end

  describe '#namespace' do
    it 'raises NotImplementedError' do
      expect { controller.new.call_namespace }.to raise_error(NotImplementedError)
    end
  end
end
