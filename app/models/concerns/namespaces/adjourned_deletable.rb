# frozen_string_literal: true

module Namespaces
  module AdjournedDeletable
    extend ActiveSupport::Concern

    def adjourned_deletion?
      return false unless Feature.enabled?(:downtier_delayed_deletion, :instance, type: :gitlab_com_derisk)

      adjourned_deletion_configured?
    end

    def adjourned_deletion_configured?
      return false unless Feature.enabled?(:downtier_delayed_deletion, :instance, type: :gitlab_com_derisk)
      return false if try(:personal?)

      deletion_adjourned_period > 0
    end

    def marked_for_deletion?
      return false unless Feature.enabled?(:downtier_delayed_deletion, :instance, type: :gitlab_com_derisk)

      marked_for_deletion_on.present?
    end

    def self_or_ancestor_marked_for_deletion
      return unless Feature.enabled?(:downtier_delayed_deletion, :instance, type: :gitlab_com_derisk)
      return self if marked_for_deletion?

      ancestors(hierarchy_order: :asc).joins(:deletion_schedule).first
    end

    def deletion_adjourned_period
      ::Gitlab::CurrentSettings.deletion_adjourned_period
    end
  end
end
