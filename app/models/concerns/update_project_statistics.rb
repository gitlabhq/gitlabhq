# frozen_string_literal: true

# This module is providing helpers for updating `ProjectStatistics` with `after_save` and `before_destroy` hooks.
#
# It deals with `ProjectStatistics.increment_statistic` making sure not to update statistics on a cascade delete from the
# project, and keeping track of value deltas on each save. It updates the DB only when a change is needed.
#
# How to use
# - Invoke `update_project_statistics stat: :a_project_statistics_column, attribute: :an_attr_to_track` in a model class body.
#
# Expectation
# - `attribute` must be an ActiveRecord attribute
# - The model must implement `project` and `project_id`. i.e. direct Project relationship or delegation
module UpdateProjectStatistics
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :statistic_name, :statistic_attribute

    # Configure the model to update +stat+ on ProjectStatistics when +attribute+ changes
    #
    # +stat+:: a column of ProjectStatistics to update
    # +attribute+:: an attribute of the current model, default to +:size+
    def update_project_statistics(stat:, attribute: :size)
      @statistic_name = stat
      @statistic_attribute = attribute

      after_save(:update_project_statistics_after_save, if: :update_project_statistics_attribute_changed?)
      after_destroy(:update_project_statistics_after_destroy, unless: :project_destroyed?)
    end
    private :update_project_statistics
  end

  included do
    private

    def project_destroyed?
      project.pending_delete?
    end

    def update_project_statistics_attribute_changed?
      attribute_changed?(self.class.statistic_attribute)
    end

    def update_project_statistics_after_save
      attr = self.class.statistic_attribute
      delta = read_attribute(attr).to_i - attribute_was(attr).to_i

      update_project_statistics(delta)
    end

    def update_project_statistics_after_destroy
      update_project_statistics(-read_attribute(self.class.statistic_attribute).to_i)
    end

    def update_project_statistics(delta)
      ProjectStatistics.increment_statistic(project_id, self.class.statistic_name, delta)
    end
  end
end
