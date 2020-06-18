# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SortingPreference do
  let(:user) { create(:user) }

  let(:controller_class) do
    Class.new do
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
      let(:params) { {} }

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

        expect(cookies['issue_sort']).to eq(value: 'popularity', secure: false, httponly: false)
      end
    end

    context 'when cookie exists' do
      let(:cookies) { { 'issue_sort' => 'id_asc' } }
      let(:params) { {} }

      it 'sets the cookie with the right values and flags' do
        subject

        expect(cookies['issue_sort']).to eq(value: 'created_asc', secure: false, httponly: false)
      end
    end
  end
end
