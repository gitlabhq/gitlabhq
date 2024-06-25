# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SortingPreference do
  let(:user) { create(:user) }
  let(:params) { {} }

  let(:controller_class) do
    Class.new(ApplicationController) do
      def self.helper_method(name); end

      include SortingPreference
      include SortingHelper
    end
  end

  let(:controller) { controller_class.new }

  before do
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(params))
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:legacy_sort_cookie_name).and_return('issuable_sort')
    allow(controller).to receive(:sorting_field).and_return(:issues_sort)
  end

  describe '#set_sort_order' do
    let(:group) { build(:group) }
    let(:controller_name) { 'issues' }
    let(:action_name) { 'issues' }
    let(:issue_weights_available) { true }

    before do
      allow(controller).to receive(:default_sort_order).and_return('updated_desc')
      allow(controller).to receive(:controller_name).and_return(controller_name)
      allow(controller).to receive(:action_name).and_return(action_name)
      allow(controller).to receive(:can_sort_by_issue_weight?).and_return(issue_weights_available)
      user.user_preference.update!(issues_sort: sorting_field)
    end

    subject { controller.send(:set_sort_order) }

    context 'when user preference contains allowed sorting' do
      let(:sorting_field) { 'updated_asc' }

      it 'sets sort order from user_preference' do
        is_expected.to eq('updated_asc')
      end
    end

    context 'when user preference contains weight sorting' do
      let(:sorting_field) { 'weight_desc' }

      context 'when user can sort by issue weight' do
        it 'sets sort order from user_preference' do
          is_expected.to eq('weight_desc')
        end
      end

      context 'when user cannot sort by issue weight' do
        let(:issue_weights_available) { false }

        it 'sets default sort order' do
          is_expected.to eq('updated_desc')
        end
      end
    end

    context 'when user preference contains merged date sorting' do
      let(:sorting_field) { 'merged_at_desc' }
      let(:can_sort_by_merged_date?) { false }

      before do
        allow(controller)
          .to receive(:can_sort_by_merged_date?)
          .with(can_sort_by_merged_date?)
          .and_return(can_sort_by_merged_date?)
      end

      it 'sets default sort order' do
        is_expected.to eq('updated_desc')
      end

      shared_examples 'user can sort by merged date' do
        it 'sets sort order from user_preference' do
          is_expected.to eq('merged_at_desc')
        end
      end

      context 'when controller_name is merge_requests' do
        let(:controller_name) { 'merge_requests' }
        let(:can_sort_by_merged_date?) { true }

        it_behaves_like 'user can sort by merged date'
      end

      context 'when action_name is merge_requests' do
        let(:action_name) { 'merge_requests' }
        let(:can_sort_by_merged_date?) { true }

        it_behaves_like 'user can sort by merged date'
      end
    end
  end

  describe '#set_sort_order_from_user_preference' do
    subject { controller.send(:set_sort_order_from_user_preference) }

    context 'when sort param given' do
      let(:params) { { sort: 'updated_desc' } }

      context 'when sorting_field is defined' do
        it 'sets user_preference with the right value' do
          is_expected.to eq('updated_desc')
        end
      end

      context 'when no sorting_field is defined on the controller' do
        before do
          allow(controller).to receive(:sorting_field).and_return(nil)
        end

        it 'does not touch user_preference' do
          expect(user).not_to receive(:user_preference)

          subject
        end
      end
    end

    context 'when a user sorting preference exists' do
      before do
        user.user_preference.update!(issues_sort: 'updated_asc')
      end

      it 'returns the set preference' do
        is_expected.to eq('updated_asc')
      end
    end
  end

  describe '#set_set_order_from_cookie' do
    subject { controller.send(:set_sort_order_from_cookie) }

    before do
      allow(controller).to receive(:cookies).and_return(cookies)
    end

    context 'when sort param given' do
      let(:cookies) { {} }
      let(:params) { { sort: 'downvotes_asc' } }

      it 'sets the cookie with the right values and flags' do
        subject

        expect(cookies['issue_sort']).to eq(expires: nil, value: 'popularity', secure: false, httponly: false)
      end
    end

    context 'when cookie exists' do
      let(:cookies) { { 'issue_sort' => 'id_asc' } }

      it 'sets the cookie with the right values and flags' do
        subject

        expect(cookies['issue_sort']).to eq(expires: nil, value: 'created_asc', secure: false, httponly: false)
      end
    end
  end
end
