# frozen_string_literal: true

# We store events about issuable label changes and weight changes in separate tables (not as
# other system notes), but we still want to display notes about label and weight changes
# as classic system notes in UI.  This service merges synthetic label and weight notes
# with classic notes and sorts them by creation time.

module ResourceEvents
  class MergeIntoNotesService
    include Gitlab::Utils::StrongMemoize

    SYNTHETIC_NOTE_BUILDER_SERVICES = [
      SyntheticLabelNotesBuilderService,
      SyntheticMilestoneNotesBuilderService,
      SyntheticStateNotesBuilderService
    ].freeze

    attr_reader :resource, :current_user, :params

    def initialize(resource, current_user, params = {})
      @resource = resource
      @current_user = current_user
      @params = params
    end

    def execute(notes = [])
      (notes + synthetic_notes).sort_by(&:created_at)
    end

    private

    def synthetic_notes
      SYNTHETIC_NOTE_BUILDER_SERVICES.flat_map do |service|
        service.new(resource, current_user, params).execute
      end
    end
  end
end

ResourceEvents::MergeIntoNotesService.prepend_mod
