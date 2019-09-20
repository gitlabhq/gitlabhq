# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Convention:
        # Issue: < 100
        # MergeRequest: >= 100 && < 1000
        # Custom events for default stages: >= 1000 (legacy)
        ENUM_MAPPING = {
          StageEvents::IssueCreated => 1,
          StageEvents::IssueFirstMentionedInCommit => 2,
          StageEvents::MergeRequestCreated => 100,
          StageEvents::MergeRequestFirstDeployedToProduction => 101,
          StageEvents::MergeRequestLastBuildFinished => 102,
          StageEvents::MergeRequestLastBuildStarted => 103,
          StageEvents::MergeRequestMerged => 104,
          StageEvents::CodeStageStart => 1_000,
          StageEvents::IssueStageEnd => 1_001,
          StageEvents::PlanStageStart => 1_002
        }.freeze

        EVENTS = ENUM_MAPPING.keys.freeze

        # Defines which start_event and end_event pairs are allowed
        PAIRING_RULES = {
          StageEvents::PlanStageStart => [
            StageEvents::IssueFirstMentionedInCommit
          ],
          StageEvents::CodeStageStart => [
            StageEvents::MergeRequestCreated
          ],
          StageEvents::IssueCreated => [
            StageEvents::IssueStageEnd
          ],
          StageEvents::MergeRequestCreated => [
            StageEvents::MergeRequestMerged
          ],
          StageEvents::MergeRequestLastBuildStarted => [
            StageEvents::MergeRequestLastBuildFinished
          ],
          StageEvents::MergeRequestMerged => [
            StageEvents::MergeRequestFirstDeployedToProduction
          ]
        }.freeze

        def [](identifier)
          events.find { |e| e.identifier.to_s.eql?(identifier.to_s) } || raise(KeyError)
        end

        # hash for defining ActiveRecord enum: identifier => number
        def to_enum
          ENUM_MAPPING.each_with_object({}) { |(k, v), hash| hash[k.identifier] = v }
        end

        # will be overridden in EE with custom events
        def pairing_rules
          PAIRING_RULES
        end

        # will be overridden in EE with custom events
        def events
          EVENTS
        end

        module_function :[], :to_enum, :pairing_rules, :events
      end
    end
  end
end
