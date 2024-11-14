# frozen_string_literal: true

module IssuableLinks
  class CreateService < BaseService
    attr_reader :issuable, :current_user, :params, :new_links

    def initialize(issuable, user, params)
      @issuable = issuable
      @current_user = user
      @params = params.dup
      @errors = []
      @new_links = []
    end

    def execute
      # If ALL referenced issues are already assigned to the given epic it renders a conflict status,
      # otherwise create issue links for the issues which
      # are still not assigned and return success message.
      if render_conflict_error?
        return error(issuables_already_assigned_message, 409)
      end

      if render_no_permission_error?
        return error(issuables_no_permission_error_message, 403)
      end

      if render_not_found_error?
        return error(issuables_not_found_message, 404)
      end

      references = create_links

      if @errors.present?
        return error(@errors.join('. '), 422)
      end

      track_event

      success(created_references: references)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def relate_issuables(referenced_issuable)
      link = link_class.find_or_initialize_by(source: issuable, target: referenced_issuable)

      set_link_type(link)

      if link.changed? && link.save
        new_links << link
        create_notes(link)
      end

      link
    end

    # rubocop: enable CodeReuse/ActiveRecord

    private

    def render_conflict_error?
      referenced_issuables.present? && (referenced_issuables - previous_related_issuables).empty?
    end

    def render_no_permission_error?
      readonly_issuables(referenced_issuables).present? && linkable_issuables(referenced_issuables).empty?
    end

    def render_not_found_error?
      linkable_issuables(referenced_issuables).empty?
    end

    def create_links
      objects = linkable_issuables(referenced_issuables)
      link_issuables(objects)
    end

    def link_issuables(target_issuables)
      target_issuables.map do |referenced_object|
        link = relate_issuables(referenced_object)

        if link.errors.any?
          @errors << (_("%{ref} cannot be added: %{error}") % {
            ref: referenced_object.to_reference,
            error: link.errors.messages.values.flatten.to_sentence
          })
        else
          after_create_for(link)
        end

        link
      end
    end

    def referenced_issuables
      @referenced_issuables ||= begin
        target_issuable = params[:target_issuable]

        if params[:issuable_references].present?
          extract_references
        elsif target_issuable
          Array.wrap(target_issuable)
        else
          []
        end
      end
    end

    def extract_references
      issuable_references = params[:issuable_references]
      text = issuable_references.join(' ')

      extractor = Gitlab::ReferenceExtractor.new(issuable.project, current_user)
      extractor.analyze(text, extractor_context)

      references(extractor)
    end

    def references(extractor)
      extractor.issues + extractor.work_items
    end

    def extractor_context
      {}
    end

    def issuables_already_assigned_message
      error_message.already_assigned
    end

    def issuables_no_permission_error_message
      error_message.no_permission_error
    end

    def issuables_not_found_message
      error_message.not_found
    end

    def error_message
      ::Gitlab::WorkItems::IssuableLinks::ErrorMessage.new(target_type: target_issuable_type, container_type: 'project')
    end

    def target_issuable_type
      'issue'
    end

    def create_notes(issuable_link)
      SystemNoteService.relate_issuable(issuable_link.source, issuable_link.target, current_user)
      SystemNoteService.relate_issuable(issuable_link.target, issuable_link.source, current_user)
    end

    def linkable_issuables(objects)
      raise NotImplementedError
    end

    def readonly_issuables(_issuables)
      [] # default to empty for non-issues
    end

    def previous_related_issuables
      raise NotImplementedError
    end

    def link_class
      raise NotImplementedError
    end

    def set_link_type(_link)
      # no-op
    end

    # Override on child classes to perform
    # actions when the service is executed.
    def track_event
      # no-op
    end

    # Override on child classes to
    # perform actions for each object created.
    def after_create_for(_link)
      # no-op
    end
  end
end

IssuableLinks::CreateService.prepend_mod_with('IssuableLinks::CreateService')
