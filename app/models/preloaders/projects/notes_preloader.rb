# frozen_string_literal: true

module Preloaders
  module Projects
    class NotesPreloader
      include RendersNotes

      def initialize(project, current_user)
        @project = project
        @current_user = current_user
      end

      def call(notes)
        prepare_notes_for_rendering(notes)
      end

      private

      attr_reader :current_user
    end
  end
end
