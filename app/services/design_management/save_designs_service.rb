# frozen_string_literal: true

module DesignManagement
  class SaveDesignsService < DesignService
    include RunsDesignActions
    include OnSuccessCallbacks
    include Gitlab::InternalEventsTracking

    MAX_FILES = 10

    def initialize(project, user, params = {})
      super

      @files = params.fetch(:files)
    end

    def execute
      return error("Not allowed!") unless can_create_designs?
      return error("Only #{MAX_FILES} files are allowed simultaneously") if files.size > MAX_FILES
      return error("Duplicate filenames are not allowed!") if files.map(&:original_filename).uniq.length != files.length
      return error("Design copy is in progress") if design_collection.copy_in_progress?

      uploaded_designs, version = upload_designs!
      skipped_designs = designs - uploaded_designs

      create_events
      design_collection.reset_copy!

      success({ designs: uploaded_designs, version: version, skipped_designs: skipped_designs })
    rescue ::ActiveRecord::RecordInvalid => e
      error(e.message)
    end

    private

    attr_reader :files

    def upload_designs!
      DesignManagement::Version.with_lock(project.id, repository) do
        actions = build_actions

        [
          actions.map(&:design),
          actions.presence && run_actions(actions)
        ]
      end
    end

    # Returns `Design` instances that correspond with `files`.
    # New `Design`s will be created where a file name does not match
    # an existing `Design`
    def designs
      @designs ||= files.map do |file|
        collection.find_or_create_design!(filename: file.original_filename)
      end
    end

    def build_actions
      @actions ||= files.zip(designs).flat_map do |(file, design)|
        Array.wrap(build_design_action(file, design))
      end
    end

    def build_design_action(file, design)
      content = file_content(file, design.full_path)
      return if design_unchanged?(design, content)

      action = new_file?(design) ? :create : :update
      on_success do
        track_usage_metrics(action)
      end

      DesignManagement::DesignAction.new(design, action, content)
    end

    # Returns true if the design file is the same as its latest version
    def design_unchanged?(design, content)
      content == existing_blobs[design]&.data
    end

    def create_events
      by_action = @actions.group_by(&:action).transform_values { |grp| grp.map(&:design) }

      event_create_service.save_designs(current_user, **by_action)
    end

    def event_create_service
      @event_create_service ||= EventCreateService.new
    end

    def commit_message
      <<~MSG
      Updated #{files.size} #{'designs'.pluralize(files.size)}

      #{formatted_file_list}
      MSG
    end

    def formatted_file_list
      filenames.map { |name| "- #{name}" }.join("\n")
    end

    def filenames
      @filenames ||= files.map(&:original_filename)
    end

    def can_create_designs?
      Ability.allowed?(current_user, :create_design, issue)
    end

    def new_file?(design)
      !existing_blobs[design]
    end

    def file_content(file, full_path)
      transformer = ::Lfs::FileTransformer.new(project, repository, target_branch)
      transformer.new_file(full_path, file.to_io, detect_content_type: Feature.enabled?(:design_management_allow_dangerous_images, project)).content
    end

    # Returns the latest blobs for the designs as a Hash of `{ Design => Blob }`
    def existing_blobs
      @existing_blobs ||= begin
        items = designs.map { |d| [target_branch, d.full_path] }

        repository.blobs_at(items).each_with_object({}) do |blob, h|
          design = designs.find { |d| d.full_path == blob.path }

          h[design] = blob
        end
      end
    end

    def track_usage_metrics(action)
      if action == :update
        ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter
          .track_issue_designs_modified_action(author: current_user, project: project)
        track_internal_event('update_design_management_design', user: current_user, project: project)
      else
        ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter
          .track_issue_designs_added_action(author: current_user, project: project)
        track_internal_event('create_design_management_design', user: current_user, project: project)
      end
    end
  end
end

DesignManagement::SaveDesignsService.prepend_mod_with('DesignManagement::SaveDesignsService')
