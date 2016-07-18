module Ci
  class CreateBuildsService
    def initialize(pipeline)
      @pipeline = pipeline
      @config = pipeline.config_processor
    end

    def execute(stage, user, status, trigger_request = nil)
      builds_attrs = @config.builds_for_stage_and_ref(stage, @pipeline.ref, @pipeline.tag, trigger_request)

      # check when to create next build
      builds_attrs = builds_attrs.select do |build_attrs|
        case build_attrs[:when]
        when 'on_success'
          status == 'success'
        when 'on_failure'
          status == 'failed'
        when 'always', 'manual'
          %w(success failed).include?(status)
        end
      end

      # don't create the same build twice
      builds_attrs.reject! do |build_attrs|
        @pipeline.builds.find_by(ref: @pipeline.ref,
                                 tag: @pipeline.tag,
                                 trigger_request: trigger_request,
                                 name: build_attrs[:name])
      end

      builds_attrs.map do |build_attrs|
        build_attrs.slice!(:name,
                           :commands,
                           :tag_list,
                           :options,
                           :allow_failure,
                           :stage,
                           :stage_idx,
                           :environment,
                           :when,
                           :yaml_variables)

        build_attrs.merge!(pipeline: @pipeline,
                           ref: @pipeline.ref,
                           tag: @pipeline.tag,
                           trigger_request: trigger_request,
                           user: user,
                           project: @pipeline.project)

        # TODO: The proper implementation for this is in
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5295
        build_attrs[:status] = 'skipped' if build_attrs[:when] == 'manual'

        ##
        # We do not persist new builds here.
        # Those will be persisted when @pipeline is saved.
        #
        @pipeline.builds.new(build_attrs)
      end
    end
  end
end
