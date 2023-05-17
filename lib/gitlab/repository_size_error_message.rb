# frozen_string_literal: true

module Gitlab
  class RepositorySizeErrorMessage
    include ActiveSupport::NumberHelper

    delegate :current_size, :limit, :exceeded_size, :additional_repo_storage_available?, to: :@checker

    # @param checker [RepositorySizeChecker]
    def initialize(checker, message_params = {})
      @message_params = message_params
      @checker = checker
    end

    def commit_error
      "Your changes could not be committed, #{base_message}"
    end

    def merge_error
      "This merge request cannot be merged, #{base_message}"
    end

    def push_warning
      _("##### WARNING ##### You have used %{usage_percentage} of the storage quota for %{namespace_name} " \
        "(%{current_size} of %{size_limit}). If %{namespace_name} exceeds the storage quota, " \
        "all projects in the namespace will be locked and actions will be restricted. " \
        "To manage storage, or purchase additional storage, see %{manage_storage_url}. " \
        "To learn more about restricted actions, see %{restricted_actions_url}") % push_message_params
    end

    def push_error(change_size = 0)
      "Your push has been rejected, #{base_message(change_size)}. #{more_info_message}"
    end

    def new_changes_error
      if additional_repo_storage_available?
        "Your push to this repository has been rejected because it would exceed storage limits. #{more_info_message}"
      else
        "Your push to this repository would cause it to exceed the size limit of #{formatted(limit)} so it has been rejected. #{more_info_message}"
      end
    end

    def more_info_message
      'Please contact your GitLab administrator for more information.'
    end

    def above_size_limit_message
      "The size of this repository (#{formatted(current_size)}) exceeds the limit of #{formatted(limit)} by #{formatted(exceeded_size)}. You won't be able to push new code to this project. #{more_info_message}"
    end

    private

    attr_reader :message_params

    def push_message_params
      {
        namespace_name: message_params[:namespace_name],
        manage_storage_url: help_page_url('user/usage_quotas', 'manage-your-storage-usage'),
        restricted_actions_url: help_page_url('user/read_only_namespaces', 'restricted-actions'),
        current_size: formatted(current_size),
        size_limit: formatted(limit),
        usage_percentage: usage_percentage
      }
    end

    def base_message(change_size = 0)
      "because this repository has exceeded its size limit of #{formatted(limit)} by #{formatted(exceeded_size(change_size))}"
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end

    def usage_percentage
      number_to_percentage(@checker.usage_ratio * 100, precision: 0)
    end

    def help_page_url(path, anchor = nil)
      ::Gitlab::Routing.url_helpers.help_page_url(path, anchor: anchor)
    end
  end
end
