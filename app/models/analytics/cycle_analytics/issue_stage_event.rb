# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IssueStageEvent < ApplicationRecord
      include StageEventModel
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id issue_id group_id project_id start_event_timestamp], presence: true)

      alias_attribute :state, :state_id
      enum state: Issue.available_states, _suffix: true
      belongs_to :issuable, class_name: 'Issue', foreign_key: 'issue_id', inverse_of: :issue_stage_events

      scope :assigned_to, ->(user) do
        assignees_class = IssueAssignee
        condition = assignees_class.where(user_id: user)
                                   .where(arel_table[:issue_id].eq(assignees_class.arel_table[:issue_id]))
        where(condition.arel.exists)
      end

      class << self
        def project_column
          :project_id
        end

        def issuable_id_column
          :issue_id
        end

        def issuable_model
          ::Issue
        end

        def select_columns
          [
            *super,
            issuable_model.arel_table[:weight],
            issuable_model.arel_table[:sprint_id]
          ]
        end

        def column_list
          [
            *super,
            :weight,
            :sprint_id
          ]
        end

        def insert_column_list
          [
            *super,
            :weight,
            :sprint_id
          ]
        end

        def assignees_model
          IssueAssignee
        end
      end
    end
  end
end
Analytics::CycleAnalytics::IssueStageEvent.prepend_mod_with('Analytics::CycleAnalytics::IssueStageEvent')
