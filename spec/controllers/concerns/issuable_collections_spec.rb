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

    controller
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

  describe '#filter_params' do
    let(:params) do
      {
        assignee_id: '1',
        assignee_username: 'user1',
        author_id: '2',
        author_username: 'user2',
        authorized_only: 'true',
        due_date: '2017-01-01',
        group_id: '3',
        iids: '4',
        label_name: 'foo',
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

    it 'filters params' do
      allow(controller).to receive(:cookies).and_return({})

      filtered_params = controller.send(:filter_params)

      expect(filtered_params).to eq({
        'assignee_id' => '1',
        'assignee_username' => 'user1',
        'author_id' => '2',
        'author_username' => 'user2',
        'authorized_only' => 'true',
        'due_date' => '2017-01-01',
        'group_id' => '3',
        'iids' => '4',
        'label_name' => 'foo',
        'milestone_title' => 'bar',
        'my_reaction_emoji' => 'thumbsup',
        'non_archived' => 'true',
        'project_id' => '5',
        'scope' => 'all',
        'search' => 'baz',
        'sort' => 'priority',
        'state' => 'opened'
      })
    end
  end
end
