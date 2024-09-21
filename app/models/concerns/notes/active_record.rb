# frozen_string_literal: true

module Notes
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      # Aliases to make application_helper#edited_time_ago_with_tooltip helper work properly with notes.
      # See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10392/diffs#note_28719102
      alias_attribute :last_edited_by, :updated_by

      belongs_to :author, class_name: "User"
      belongs_to :updated_by, class_name: "User"
      belongs_to :last_edited_by, class_name: 'User'

      has_many :todos

      delegate :name, :email, to: :author, prefix: true

      validates :note, presence: true
      validates :note, length: { maximum: Gitlab::Database::MAX_TEXT_SIZE_LIMIT }
      validates :author, presence: true
      validates :discussion_id, presence: true, format: { with: /\A\h{40}\z/ }
      validate :validate_created_after

      def validate_created_after
        return unless created_at
        return if created_at >= '1970-01-01'

        errors.add(:created_at, s_('Note|The created date provided is too far in the past.'))
      end
    end
  end
end
