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

      extend ::Gitlab::Utils::Override

      cache_markdown_field :note, pipeline: :note, issuable_reference_expansion_enabled: true

      redact_field :note

      self.table_name = 'abuse_report_notes'

      belongs_to :abuse_report

      alias_attribute :noteable_id, :abuse_report_id
      alias_method :noteable, :abuse_report

      validates :abuse_report, presence: true

      scope :fresh, -> { order_created_asc.with_order_id_asc }
      scope :inc_relations_for_view, ->(_abuse_report = nil) do
        relations = [
          { author: :status }, :updated_by, :award_emoji
        ]

        includes(relations)
      end

      class << self
        def parent_object_field
          :abuse_report
        end
      end

      def discussion_class(_noteable = nil)
        AntiAbuse::Reports::IndividualNoteDiscussion
      end

      override :skip_project_check?
      def skip_project_check?
        true
      end
    end
  end
end
