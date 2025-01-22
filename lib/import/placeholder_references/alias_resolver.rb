# frozen_string_literal: true

module Import
  module PlaceholderReferences
    module AliasResolver
      extend self

      MissingAlias = Class.new(StandardError)

      NOTE_COLUMNS = { "author_id" => "author_id", "updated_by_id" => "updated_by_id",
                       "resolved_by_id" => "resolved_by_id" }.freeze
      NOTE_EXCLUSIONS = %w[updated_by_id resolved_by_id].freeze

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
            columns: { "user_id" => "user_id", "erased_by_id" => "erased_by_id" },
            columns_ignored_on_deletion: %w[user_id erased_by_id]
          }
        },
        "Ci::Build" => {
          1 => {
            model: Ci::Build,
            columns: { "user_id" => "user_id", "erased_by_id" => "erased_by_id" },
            columns_ignored_on_deletion: %w[user_id erased_by_id]
          }
        },
        "Ci::Pipeline" => {
          1 => {
            model: Ci::Pipeline,
            columns: { "user_id" => "user_id" },
            columns_ignored_on_deletion: %w[user_id]
          }
        },
        "Ci::PipelineSchedule" => {
          1 => {
            model: Ci::PipelineSchedule,
            columns: { "owner_id" => "owner_id" }
          }
        },
        "DesignManagement::Version" => {
          1 => {
            model: DesignManagement::Version,
            columns: { "author_id" => "author_id" }
          }
        },
        "DiffNote" => {
          1 => {
            model: DiffNote,
            columns: NOTE_COLUMNS,
            columns_ignored_on_deletion: NOTE_EXCLUSIONS
          }
        },
        "DiscussionNote" => {
          1 => {
            model: DiscussionNote,
            columns: NOTE_COLUMNS,
            columns_ignored_on_deletion: NOTE_EXCLUSIONS
          }
        },
        "Event" => {
          1 => {
            model: Event,
            columns: { "author_id" => "author_id" },
            columns_ignored_on_deletion: %w[author_id]
          }
        },
        "Epic" => {
          1 => {
            model: Epic,
            columns: { "author_id" => "author_id", "assignee_id" => "assignee_id", "updated_by_id" => "updated_by_id",
                       "last_edited_by_id" => "last_edited_by_id", "closed_by_id" => "closed_by_id" },
            columns_ignored_on_deletion: %w[updated_by_id]
          }
        },
        "GenericCommitStatus" => {
          1 => {
            model: GenericCommitStatus,
            columns: { "user_id" => "user_id", "erased_by_id" => "erased_by_id" },
            columns_ignored_on_deletion: %w[user_id erased_by_id]
          }
        },
        "LegacyDiffNote" => {
          1 => {
            model: LegacyDiffNote,
            columns: NOTE_COLUMNS,
            columns_ignored_on_deletion: NOTE_EXCLUSIONS
          }
        },
        "Issue" => {
          1 => {
            model: Issue,
            columns: { "author_id" => "author_id", "updated_by_id" => "updated_by_id",
                       "closed_by_id" => "closed_by_id", "last_edited_by_id" => "last_edited_by_id" },
            columns_ignored_on_deletion: %w[last_edited_by_id]
          }
        },
        "IssueAssignee" => {
          1 => {
            model: IssueAssignee,
            columns: { "user_id" => "user_id", "issue_id" => "issue_id" }
          }
        },
        "List" => {
          1 => {
            model: List,
            columns: { "user_id" => "user_id" }
          }
        },
        "MergeRequest" => {
          1 => {
            model: MergeRequest,
            columns: { "author_id" => "author_id", "updated_by_id" => "updated_by_id",
                       "last_edited_by_id" => "last_edited_by_id", "merge_user_id" => "merge_user_id" },
            columns_ignored_on_deletion: %w[last_edited_by_id]
          }
        },
        "MergeRequest::Metrics" => {
          1 => {
            model: MergeRequest::Metrics,
            columns: { "merged_by_id" => "merged_by_id", "latest_closed_by_id" => "latest_closed_by_id" }
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
            columns: NOTE_COLUMNS,
            columns_ignored_on_deletion: NOTE_EXCLUSIONS
          }
        },
        "ProtectedTag::CreateAccessLevel" => {
          1 => {
            model: ProtectedTag::CreateAccessLevel,
            columns: { "user_id" => "user_id" }
          }
        },
        "ProtectedBranch::MergeAccessLevel" => {
          1 => {
            model: ProtectedBranch::MergeAccessLevel,
            columns: { "user_id" => "user_id" }
          }
        },
        "ProtectedBranch::PushAccessLevel" => {
          1 => {
            model: ProtectedBranch::PushAccessLevel,
            columns: { "user_id" => "user_id" }
          }
        },
        "ProjectSnippet" => {
          1 => {
            model: ProjectSnippet,
            columns: { "author_id" => "author_id" }
          }
        },
        "Release" => {
          1 => {
            model: Release,
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
        "Snippet" => {
          1 => {
            model: Snippet,
            columns: { "author_id" => "author_id" }
          }
        },
        "Timelog" => {
          1 => {
            model: Timelog,
            columns: { "user_id" => "user_id" }
          }
        },
        "Vulnerability" => {
          1 => {
            model: Vulnerability,
            columns: { "author_id" => "author_id", "resolved_by_id" => "resolved_by_id",
                       "dismissed_by_id" => "dismissed_by_id", "confirmed_by_id" => "confirmed_by_id" }
          }
        },
        "WorkItem" => {
          1 => {
            model: WorkItem,
            columns: { "author_id" => "author_id", "updated_by_id" => "updated_by_id",
                       "closed_by_id" => "closed_by_id", "last_edited_by_id" => "last_edited_by_id" }
          }
        }
      }.freeze

      private_constant :ALIASES

      def aliases
        ALIASES
      end

      def version_for_model(model)
        return aliases[model].keys.max if aliases[model]

        track_error_for_missing(model: model)

        1
      end

      def aliased_model(model, version:)
        aliased_model = aliases.dig(model, version, :model)
        return aliased_model if aliased_model.present?

        track_error_for_missing(model:, version:)

        model.safe_constantize || (raise missing_alias_error(model:, version:))
      end

      def aliased_column(model, column, version:)
        aliased_column = aliases.dig(model, version, :columns, column)
        return aliased_column if aliased_column.present?

        track_error_for_missing(model: model, column: column, version: version)

        column
      end

      def models_with_data
        aliases.values
          .map { |versions| versions[versions.keys.max] }
          .map { |data| [data[:model], data] }
      end

      private_class_method def self.missing_alias_error(model:, column: nil, version: nil)
        message = "ALIASES must be extended to include #{model}"
        message += ".#{column}" if column
        message += " for version #{version}" if version
        MissingAlias.new(message)
      end

      private_class_method def self.track_error_for_missing(model:, column: nil, version: nil)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(missing_alias_error(model:, column:, version:))
      end
    end
  end
end

Import::PlaceholderReferences::AliasResolver.extend_mod
