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

    def title
      label? ? label.name : list_type.humanize
    end

    private

    def can_be_destroyed
      throw(:abort) unless destroyable? # rubocop:disable Cop/BanCatchThrow
    end
  end
end
