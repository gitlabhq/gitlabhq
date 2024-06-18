# frozen_string_literal: true

module DesignManagement
  class DeleteDesignsService < DesignService
    include RunsDesignActions
    include OnSuccessCallbacks
    include Gitlab::InternalEventsTracking

    def initialize(project, user, params = {})
      super

      @designs = params.fetch(:designs)
    end

    def execute
      return error('Forbidden!') unless can_delete_designs?

      version = delete_designs!
      EventCreateService.new.destroy_designs(designs, current_user)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_designs_removed_action(
        author: current_user,
        project: project
      )
      TodosDestroyer::DestroyedDesignsWorker.perform_async(designs.map(&:id))

      success(version: version)
    end

    def commit_message
      n = designs.size

      <<~MSG
      Removed #{n} #{'designs'.pluralize(n)}

      #{formatted_file_list}
      MSG
    end

    private

    attr_reader :designs

    def delete_designs!
      DesignManagement::Version.with_lock(project.id, repository) do
        run_actions(build_actions)
      end
    end

    def can_delete_designs?
      Ability.allowed?(current_user, :destroy_design, issue)
    end

    def build_actions
      designs.map { |d| design_action(d) }
    end

    def design_action(design)
      on_success do
        track_internal_event('delete_design_management_design', user: current_user, project: project)
      end

      DesignManagement::DesignAction.new(design, :delete)
    end

    def formatted_file_list
      designs.map { |design| "- #{design.full_path}" }.join("\n")
    end
  end
end

DesignManagement::DeleteDesignsService.prepend_mod_with('DesignManagement::DeleteDesignsService')
