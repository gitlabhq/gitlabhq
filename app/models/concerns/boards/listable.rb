# frozen_string_literal: true

module Boards
  module Listable
    extend ActiveSupport::Concern

    included do
      validates :label, :position, presence: true, if: :label?
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :movable?

      before_destroy :can_be_destroyed

      scope :ordered, -> { order(:list_type, :position) }
      scope :destroyable, -> { where(list_type: list_types.slice(*destroyable_types).values) }
      scope :movable, -> { where(list_type: list_types.slice(*movable_types).values) }
      scope :with_types, ->(list_types) { where(list_type: list_types) }
      scope :positioned_at_or_after, ->(position) { where('position >= ?', position) }

      class << self
        def preload_preferences_for_user(lists, user)
          return unless user

          lists.each { |list| list.preferences_for(user) }
        end
      end
    end

    class_methods do
      def destroyable_types
        [:label]
      end

      def movable_types
        [:label]
      end
    end

    def destroyable?
      self.class.destroyable_types.include?(list_type&.to_sym)
    end

    def movable?
      self.class.movable_types.include?(list_type&.to_sym)
    end

    def collapsed?(user)
      preferences = preferences_for(user)

      preferences.collapsed?
    end

    def update_preferences_for(user, preferences = {})
      return unless user

      preferences_for(user).update(preferences)
    end

    def title
      if label?
        label.name
      elsif backlog?
        _('Open')
      else
        list_type.humanize
      end
    end

    private

    def can_be_destroyed
      throw(:abort) unless destroyable? # rubocop:disable Cop/BanCatchThrow
    end
  end
end
