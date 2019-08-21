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

  describe '#page_count_for_relation' do
    let(:params) { { state: 'opened' } }

    it 'returns the number of pages' do
      relation = double(:relation, limit_value: 20)
      pages = controller.send(:page_count_for_relation, relation, 28)

      expect(pages).to eq(2)
    end
  end

  describe '#finder_options' do
    before do
      allow(controller).to receive(:cookies).and_return({})
      allow(controller).to receive(:current_user).and_return(nil)
    end

    subject { controller.send(:finder_options).to_h }

    context 'scalar params' do
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

      it 'only allows whitelisted params' do
        is_expected.to include({
          'assignee_id' => '1',
          'assignee_username' => 'user1',
          'author_id' => '2',
          'author_username' => 'user2',
          'confidential' => true,
          'label_name' => 'foo',
          'milestone_title' => 'bar',
          'my_reaction_emoji' => 'thumbsup',
          'due_date' => '2017-01-01',
          'scope' => 'all',
          'search' => 'baz',
          'sort' => 'priority',
          'state' => 'opened'
        })

        is_expected.not_to include('invalid_param')
      end
    end

    context 'array params' do
      let(:params) do
        {
          assignee_username: %w[user1 user2],
          label_name: %w[label1 label2],
          invalid_param: 'invalid_param',
          invalid_array: ['param']
        }
      end

      it 'only allows whitelisted params' do
        is_expected.to include({
          'label_name' => %w[label1 label2],
          'assignee_username' => %w[user1 user2]
        })

        is_expected.not_to include('invalid_param', 'invalid_array')
      end
    end

    context 'search using an issue iid' do
      let(:params) { { search: "#5" } }

      it 'mutates the search into a filter by iid' do
        is_expected.to include({
            'iids' => '5',
            'search' => nil
        })
      end
    end
  end
end
