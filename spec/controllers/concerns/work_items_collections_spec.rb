# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemsCollections, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }

  let(:controller) do
    klass = Class.new(ApplicationController) do
      def self.helper_method(name); end

      include WorkItemsCollections

      def finder_type
        WorkItems::WorkItemsFinder
      end
    end

    controller = klass.new

    allow(controller).to receive_messages(
      params: ActionController::Parameters.new(params),
      current_user: user
    )

    controller
  end

  describe '#finder_options' do
    before do
      allow(controller).to receive_messages(
        cookies: {},
        current_user: nil,
        set_sort_order: 'priority',
        sort_value_recently_updated: 'updated_desc',
        sort_value_created_date: 'created_desc'
      )
    end

    subject { controller.send(:finder_options).to_h }

    context 'with scalar params' do
      let(:params) do
        {
          assignee_id: '1',
          assignee_username: 'user1',
          author_id: '2',
          author_username: 'user2',
          confidential: true,
          due_date: '2017-01-01',
          group_id: '3',
          iids: '4',
          label_name: 'foo',
          milestone_title: 'bar',
          my_reaction_emoji: AwardEmoji::THUMBS_UP,
          non_archived: 'true',
          project_id: '5',
          scope: 'all',
          search: 'baz',
          sort: 'priority',
          state: 'opened',
          invalid_param: 'invalid_param'
        }
      end

      it 'only allows allowlisted params' do
        is_expected.to include({
          'assignee_id' => '1',
          'assignee_username' => 'user1',
          'author_id' => '2',
          'author_username' => 'user2',
          'confidential' => nil,
          'label_name' => 'foo',
          'milestone_title' => 'bar',
          'my_reaction_emoji' => AwardEmoji::THUMBS_UP,
          'due_date' => '2017-01-01',
          'scope' => 'all',
          'search' => 'baz',
          'sort' => 'priority',
          'state' => 'opened'
        })

        is_expected.not_to include('invalid_param')
      end
    end

    context 'with array params' do
      let(:params) do
        {
          assignee_username: %w[user1 user2],
          label_name: %w[label1 label2],
          invalid_param: 'invalid_param',
          invalid_array: ['param']
        }
      end

      it 'only allows allowlisted params' do
        is_expected.to include({
          'label_name' => %w[label1 label2],
          'assignee_username' => %w[user1 user2]
        })

        is_expected.not_to include('invalid_param', 'invalid_array')
      end
    end

    context 'with search using a work item iid' do
      let(:params) { { search: "#5" } }

      it 'mutates the search into a filter by iid' do
        is_expected.to include({
          'iids' => '5',
          'search' => nil
        })
      end
    end

    context 'with type filtering' do
      let(:params) { { type: %w[task incident] } }

      it 'mutates the search into a filter by type' do
        is_expected.to include({ issue_types: %w[task incident] })
      end
    end

    context 'with negated type filtering' do
      let(:params) { { not: { type: %w[task incident] } } }

      it 'mutates the search into a filter by type' do
        is_expected.to include({ not: { issue_types: %w[task incident] } })
      end
    end
  end
end
