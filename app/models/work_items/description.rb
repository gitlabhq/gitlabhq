# frozen_string_literal: true

module WorkItems
  class Description < ApplicationRecord
    self.table_name = 'work_item_descriptions'

    DESCRIPTION_LENGTH_MAX = 1.megabyte

    belongs_to :work_item
    belongs_to :namespace
    belongs_to :last_editing_user, foreign_key: 'last_edited_by_id', class_name: 'User', optional: true # rubocop:disable Rails/InverseOf -- The inverse relation is not necessary
    validates :namespace, presence: true
    validates :work_item, presence: true
    # we validate the description against DESCRIPTION_LENGTH_MAX only for Issuables being created and on updates if
    # the description changes to avoid breaking the existing Issuables which may have their descriptions longer
    validates :description, bytesize: { maximum: -> { DESCRIPTION_LENGTH_MAX } }, if: :validate_description_length?

    before_validation :set_namespace

    def set_namespace
      return if work_item.nil?
      return if work_item.namespace == namespace

      self.namespace = work_item.namespace
    end

    private

    # we will need to switch this validation off for record backfilling process to avoid breaking validations
    # for some of existing records which were created before we introduced a length restriction
    def validate_description_length?
      return false unless description_changed?

      previous_description = changes_to_save['description'].first
      # previous_description will be nil for new records
      return true if previous_description.blank?

      previous_description.bytesize <= DESCRIPTION_LENGTH_MAX
    end
  end
end
