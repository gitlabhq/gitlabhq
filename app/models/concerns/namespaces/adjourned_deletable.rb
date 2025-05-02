# frozen_string_literal: true

module Namespaces
  module AdjournedDeletable
    extend ActiveSupport::Concern

    def adjourned_deletion?
      adjourned_deletion_configured?
    end

    def adjourned_deletion_configured?
      deletion_adjourned_period > 0
    end

    def marked_for_deletion?
      marked_for_deletion_on.present?
    end

    def self_or_ancestor_marked_for_deletion
      return self if marked_for_deletion?

      ancestors(hierarchy_order: :asc).joins(:deletion_schedule).first
    end

    def deletion_adjourned_period
      ::Gitlab::CurrentSettings.deletion_adjourned_period
    end
  end
end
