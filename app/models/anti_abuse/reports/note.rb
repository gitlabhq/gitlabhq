# frozen_string_literal: true

module AntiAbuse
  module Reports
    class Note < ApplicationRecord
      include Notes::ActiveRecord
      include Notes::Discussion

      include AfterCommitQueue
      include Awardable
      include CacheMarkdownField
      include Editable
      include Mentionable
      include Participable
      include Redactable
      include ResolvableNote
      include Sortable

      self.table_name = 'abuse_report_notes'

      belongs_to :abuse_report

      alias_attribute :noteable_id, :abuse_report_id
      alias_method :noteable, :abuse_report

      validates :abuse_report, presence: true

      scope :fresh, -> { order_created_asc.with_order_id_asc }

      def discussion_class(_noteable = nil)
        AntiAbuse::Reports::IndividualNoteDiscussion
      end
    end
  end
end
