# frozen_string_literal: true

require 'spec_helper'

describe IssuableCollections do
  let(:user) { create(:user) }

  let(:controller) do
    klass = Class.new do
      def self.helper_method(name); end

      include IssuableCollections

      def finder_type
        IssuesFinder
      end
    end

    controller = klass.new

    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(params))
    allow(controller).to receive(:current_user).and_return(user)

    controller
  end

  describe '#set_sort_order_from_user_preference' do
    describe 'when sort param given' do
      let(:params) { { sort: 'updated_desc' } }

      context 'when issuable_sorting_field is defined' do
        before do
          controller.class.define_method(:issuable_sorting_field) { :issues_sort}
        end

        it 'sets user_preference with the right value' do
          controller.send(:set_sort_order_from_user_preference)

          expect(user.user_preference.reload.issues_sort).to eq('updated_desc')
        end
      end

      context 'when no issuable_sorting_field is defined on the controller' do
        it 'does not touch user_preference' do
          allow(user).to receive(:user_preference)

          controller.send(:set_sort_order_from_user_preference)

          expect(user).not_to have_received(:user_preference)
        end
      end
    end

    context 'when a user sorting preference exists' do
      let(:params) { {} }

      before do
        controller.class.define_method(:issuable_sorting_field) { :issues_sort }
      end

      it 'returns the set preference' do
        user.user_preference.update(issues_sort: 'updated_asc')

        sort_preference = controller.send(:set_sort_order_from_user_preference)

        expect(sort_preference).to eq('updated_asc')
      end
    end
  end

  describe '#set_set_order_from_cookie' do
    describe 'when sort param given' do
      let(:cookies) { {} }
      let(:params) { { sort: 'downvotes_asc' } }

      it 'sets the cookie with the right values and flags' do
        allow(controller).to receive(:cookies).and_return(cookies)

        controller.send(:set_sort_order_from_cookie)

        expect(cookies['issue_sort']).to eq({ value: 'popularity', secure: false, httponly: false })
      end
    end

    describe 'when cookie exists' do
      let(:cookies) { { 'issue_sort' => 'id_asc' } }
      let(:params) { {} }

      it 'sets the cookie with the right values and flags' do
        allow(controller).to receive(:cookies).and_return(cookies)

        controller.send(:set_sort_order_from_cookie)

        expect(cookies['issue_sort']).to eq({ value: 'created_asc', secure: false, httponly: false })
      end
    end
  end

  describe '#page_count_for_relation' do
    let(:params) { { state: 'opened' } }

    it 'returns the number of pages' do
      relation = double(:relation, limit_value: 20)
      pages = controller.send(:page_count_for_relation, relation, 28)

      expect(pages).to eq(2)
    end
  end

  describe '#finder_options' do
    let(:params) do
      {
        assignee_id: '1',
        assignee_username: 'user1',
        author_id: '2',
        author_username: 'user2',
        authorized_only: 'yes',
        confidential: true,
        due_date: '2017-01-01',
        group_id: '3',
        iids: '4',
        label_name: ['foo'],
        milestone_title: 'bar',
        my_reaction_emoji: 'thumbsup',
        non_archived: 'true',
        project_id: '5',
        scope: 'all',
        search: 'baz',
        sort: 'priority',
        state: 'opened',
        invalid_param: 'invalid_param'
      }
    end

    it 'only allows whitelisted params' do
      allow(controller).to receive(:cookies).and_return({})
      allow(controller).to receive(:current_user).and_return(nil)

      finder_options = controller.send(:finder_options)

      expect(finder_options).to eq(ActionController::Parameters.new({
        'assignee_id' => '1',
        'assignee_username' => 'user1',
        'author_id' => '2',
        'author_username' => 'user2',
        'confidential' => true,
        'label_name' => ['foo'],
        'milestone_title' => 'bar',
        'my_reaction_emoji' => 'thumbsup',
        'due_date' => '2017-01-01',
        'scope' => 'all',
        'search' => 'baz',
        'sort' => 'priority',
        'state' => 'opened'
      }).permit!)
    end
  end
end
