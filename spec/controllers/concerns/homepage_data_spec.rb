# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HomepageData, feature_category: :notifications do
  let(:user) { create(:user) }
  let(:controller_class) do
    Class.new do
      include HomepageData
    end
  end

  let(:controller) { controller_class.new }

  describe '#merge_request_ids' do
    subject(:merge_request_ids) { controller.send(:merge_request_ids, user) }

    context 'when user preference is action_based' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'action_based')
      end

      it 'returns action_based IDs' do
        expect(merge_request_ids).to eq(%w[reviews_requested assigned_to_you])
      end
    end

    context 'when user preference is role_based' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'role_based')
      end

      it 'returns role_based IDs' do
        expect(merge_request_ids).to eq(%w[reviews assigned])
      end
    end
  end
end
