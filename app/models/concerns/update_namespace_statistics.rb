# frozen_string_literal: true

# This module provides helpers for updating `NamespaceStatistics` with `after_save` and
# `after_destroy` hooks.
#
# Models including this module must respond to and return a `namespace`
#
# Example:
#
# class DependencyProxy::Manifest
#   include UpdateNamespaceStatistics
#
#   belongs_to :group
#   alias_attribute :namespace, :group
#
#   update_namespace_statistics namespace_statistics_name: :dependency_proxy_size
# end
module UpdateNamespaceStatistics
  extend ActiveSupport::Concern
  include AfterCommitQueue

  class_methods do
    attr_reader :namespace_statistics_name, :statistic_attribute

    # Configure the model to update `namespace_statistics_name` on NamespaceStatistics,
    # when `statistic_attribute` changes
    #
    # - namespace_statistics_name: A column of `NamespaceStatistics` to update
    # - statistic_attribute: An attribute of the current model, default to `size`
    def update_namespace_statistics(namespace_statistics_name:, statistic_attribute: :size)
      @namespace_statistics_name = namespace_statistics_name
      @statistic_attribute = statistic_attribute

      after_save(:schedule_namespace_statistics_refresh, if: :update_namespace_statistics?)
      after_destroy(:schedule_namespace_statistics_refresh)
    end

    private :update_namespace_statistics
  end

  included do
    private

    def update_namespace_statistics?
      saved_change_to_attribute?(self.class.statistic_attribute)
    end

    def schedule_namespace_statistics_refresh
      return unless namespace

      run_after_commit do
        Groups::UpdateStatisticsWorker.perform_async(namespace.id, [self.class.namespace_statistics_name.to_s])
      end
    end
  end
end
