# frozen_string_literal: true

module FeatureFlags
  class UpdateService < FeatureFlags::BaseService
    AUDITABLE_STRATEGY_ATTRIBUTES_HUMAN_NAMES = {
      'scopes' => 'environment scopes',
      'parameters' => 'parameters'
    }.freeze

    def success(**args)
      execute_hooks_after_commit(args[:feature_flag])
      super
    end

    def execute(feature_flag)
      return error('Access Denied', 403) unless can_update?(feature_flag)
      return error('Not Found', 404) unless valid_user_list_ids?(feature_flag, user_list_ids(params))

      ApplicationRecord.transaction do
        feature_flag.assign_attributes(params)

        feature_flag.strategies.each do |strategy|
          if strategy.name_changed? && strategy.name_was == ::Operations::FeatureFlags::Strategy::STRATEGY_GITLABUSERLIST
            strategy.user_list = nil
          end
        end

        # We generate the audit context before the feature flag is saved as #changed_strategies_messages depends on the strategies' states before save
        saved_audit_context = audit_context feature_flag

        if feature_flag.save
          update_last_feature_flag_updated_at!

          success(feature_flag: feature_flag, audit_context: saved_audit_context)
        else
          error(feature_flag.errors.full_messages, :bad_request)
        end
      end
    end

    private

    def execute_hooks_after_commit(feature_flag)
      return unless feature_flag.active_previously_changed?

      # The `current_user` method (defined in `BaseService`) is not available within the `run_after_commit` block
      user = current_user
      feature_flag.run_after_commit do
        HookService.new(feature_flag, user).execute
      end
    end

    def audit_context(feature_flag)
      {
        name: 'feature_flag_updated',
        message: audit_message(feature_flag),
        author: current_user,
        scope: feature_flag.project,
        target: feature_flag
      }
    end

    def audit_message(feature_flag)
      changes = changed_attributes_messages(feature_flag)
      changes += changed_strategies_messages(feature_flag)

      return if changes.empty?

      "Updated feature flag #{feature_flag.name}. " + changes.join(" ")
    end

    def changed_attributes_messages(feature_flag)
      feature_flag.changes.slice(*AUDITABLE_ATTRIBUTES).map do |attribute_name, changes|
        "Updated #{attribute_name} "\
        "from \"#{changes.first}\" to "\
        "\"#{changes.second}\"."
      end
    end

    def changed_strategies_messages(feature_flag)
      feature_flag.strategies.map do |strategy|
        if strategy.new_record?
          created_strategy_message(strategy)
        elsif strategy.marked_for_destruction?
          deleted_strategy_message(strategy)
        else
          updated_strategy_message(strategy)
        end
      end.compact # updated_strategy_message can return nil if nothing has been changed
    end

    def deleted_strategy_message(strategy)
      scopes = strategy.scopes.map { |scope| scope.environment_scope }.join(', ')
      "Deleted strategy #{strategy.name} with environment scopes #{scopes}."
    end

    def updated_strategy_message(strategy)
      changes = strategy.changes.slice(*AUDITABLE_STRATEGY_ATTRIBUTES_HUMAN_NAMES.keys)
      return if changes.empty?

      message = "Updated strategy #{strategy.name} "
      message += changes.map do |attribute_name, change|
        name = AUDITABLE_STRATEGY_ATTRIBUTES_HUMAN_NAMES[attribute_name]
        "#{name} from #{change.first} to #{change.second}"
      end.join(' ')

      message + '.'
    end

    def can_update?(feature_flag)
      Ability.allowed?(current_user, :update_feature_flag, feature_flag)
    end

    def user_list_ids(params)
      params.fetch(:strategies_attributes, [])
        .select { |s| s[:user_list_id].present? }
        .map { |s| s[:user_list_id] }
    end

    def valid_user_list_ids?(feature_flag, user_list_ids)
      user_list_ids.empty? || ::Operations::FeatureFlags::UserList.belongs_to?(feature_flag.project_id, user_list_ids)
    end
  end
end
