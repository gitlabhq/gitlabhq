# frozen_string_literal: true

module DesignManagement
  # Parameter object which is a tuple of the database record and the
  # last gitaly call made to change it. This serves to perform the
  # logical mapping from git action to database representation.
  class DesignAction
    include ActiveModel::Validations

    EVENT_FOR_GITALY_ACTION = {
      create: DesignManagement::Action.events[:creation],
      update: DesignManagement::Action.events[:modification],
      delete: DesignManagement::Action.events[:deletion]
    }.freeze

    attr_reader :design, :action, :content

    delegate :issue_id, to: :design

    validates :design, presence: true
    validates :action, presence: true, inclusion: { in: EVENT_FOR_GITALY_ACTION.keys }
    validates :content,
      absence: { if: :forbids_content?,
                  message: 'this action forbids content' },
      presence: { if: :needs_content?,
                  message: 'this action needs content' }

    # Parameters:
    # - design [DesignManagement::Design]: the design that was changed
    # - action [Symbol]: the action that gitaly performed
    def initialize(design, action, content = nil)
      @design = design
      @action = action
      @content = content
      validate!
    end

    def row_attrs(version)
      { design_id: design.id, version_id: version.id, event: event }
    end

    def gitaly_action
      { action: action, file_path: design.full_path, content: content }.compact
    end

    # This action has been performed - do any post-creation actions
    # such as clearing method caches.
    def performed
      design.clear_version_cache
    end

    private

    def needs_content?
      action != :delete
    end

    def forbids_content?
      action == :delete
    end

    def event
      EVENT_FOR_GITALY_ACTION[action]
    end
  end
end
