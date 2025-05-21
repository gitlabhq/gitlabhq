# frozen_string_literal: true

module Types
  module Notes
    module AbuseReport
      class NoteType < BaseObject
        graphql_name 'AbuseReportNote'

        include ActionView::Helpers::SanitizeHelper

        implements Types::Notes::BaseNoteInterface

        present_using NotePresenter

        authorize :read_note

        field :id, ::Types::GlobalIDType[::AntiAbuse::Reports::Note],
          null: false,
          description: 'ID of the note.'

        field :discussion, Types::Notes::AbuseReport::DiscussionType,
          null: true,
          description: 'Discussion the note is a part of.'
      end
    end
  end
end
