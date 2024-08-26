# frozen_string_literal: true

module Import
  module PlaceholderReferences
    module AliasResolver
      MissingAlias = Class.new(StandardError)

      # A new version for a model should be defined when new entries must be
      # mapped in a different way to data that already exists in the database.
      # Context: https://gitlab.com/gitlab-org/gitlab/-/issues/478501
      ALIASES = {
        "Approval" => {
          1 => {
            model: Approval,
            columns: { "user_id" => "user_id" }
          }
        },
        "AwardEmoji" => {
          1 => {
            model: AwardEmoji,
            columns: { "user_id" => "user_id" }
          }
        },
        "Ci::Bridge" => {
          1 => {
            model: Ci::Bridge,
            columns: { "user_id" => "user_id" }
          }
        },
        "Ci::Build" => {
          1 => {
            model: Ci::Build,
            columns: { "user_id" => "user_id" }
          }
        },
        "Ci::Pipeline" => {
          1 => {
            model: Ci::Pipeline,
            columns: { "user_id" => "user_id" }
          }
        },
        "DesignManagement::Version" => {
          1 => {
            model: DesignManagement::Version,
            columns: { "author_id" => "author_id" }
          }
        },
        "Event" => {
          1 => {
            model: Event,
            columns: { "author_id" => "author_id" }
          }
        },
        "GenericCommitStatus" => {
          1 => {
            model: GenericCommitStatus,
            columns: { "user_id" => "user_id" }
          }
        },
        "Issue" => {
          1 => {
            model: Issue,
            columns: { "author_id" => "author_id" }
          }
        },
        "IssueAssignee" => {
          1 => {
            model: IssueAssignee,
            columns: { "user_id" => "user_id", "issue_id" => "issue_id" }
          }
        },
        "MergeRequest" => {
          1 => {
            model: MergeRequest,
            columns: { "author_id" => "author_id" }
          }
        },
        "MergeRequest::Metrics" => {
          1 => {
            model: MergeRequest::Metrics,
            columns: { "merged_by_id" => "merged_by_id" }
          }
        },
        "MergeRequestAssignee" => {
          1 => {
            model: MergeRequestAssignee,
            columns: { "user_id" => "user_id", "merge_request_id" => "merge_request_id" }
          }
        },
        "MergeRequestReviewer" => {
          1 => {
            model: MergeRequestReviewer,
            columns: { "user_id" => "user_id" }
          }
        },
        "Note" => {
          1 => {
            model: Note,
            columns: { "author_id" => "author_id" }
          }
        },
        "ResourceLabelEvent" => {
          1 => {
            model: ResourceLabelEvent,
            columns: { "user_id" => "user_id" }
          }
        },
        "ResourceMilestoneEvent" => {
          1 => {
            model: ResourceMilestoneEvent,
            columns: { "user_id" => "user_id" }
          }
        },
        "ResourceStateEvent" => {
          1 => {
            model: ResourceStateEvent,
            columns: { "user_id" => "user_id" }
          }
        },
        "Timelog" => {
          1 => {
            model: Timelog,
            columns: { "user_id" => "user_id" }
          }
        }
      }.freeze

      def self.version_for_model(model)
        return ALIASES[model].keys.max if ALIASES[model]

        track_error_for_missing(model: model)

        1
      end

      def self.aliased_model(model, version:)
        aliased_model = ALIASES.dig(model, version, :model)
        return aliased_model if aliased_model.present?

        track_error_for_missing(model: model, version: version)

        model.safe_constantize
      end

      def self.aliased_column(model, column, version:)
        aliased_column = ALIASES.dig(model, version, :columns, column)
        return aliased_column if aliased_column.present?

        track_error_for_missing(model: model, column: column, version: version)

        column
      end

      private_class_method def self.track_error_for_missing(model:, column: nil, version: nil)
        message = "ALIASES must be extended to include #{model}"
        message += ".#{column}" if column
        message += " for version #{version}" if version
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(MissingAlias.new(message))
      end
    end
  end
end
