module Ci
  class CreateBuildsService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute(stage, user, status, trigger_request = nil)
      builds_attrs = config_processor.builds_for_stage_and_ref(stage, @pipeline.ref, @pipeline.tag, trigger_request)

      # check when to create next build
      builds_attrs = builds_attrs.select do |build_attrs|
        case build_attrs[:when]
        when 'on_success'
          status == 'success'
        when 'on_failure'
          status == 'failed'
        when 'always'
          %w(success failed).include?(status)
        end
      end

      builds_attrs.map do |build_attrs|
        # don't create the same build twice
        unless @pipeline.builds.find_by(ref: @pipeline.ref, tag: @pipeline.tag,
                                        trigger_request: trigger_request, name: build_attrs[:name])
          build_attrs.slice!(:name,
                             :commands,
                             :tag_list,
                             :options,
                             :allow_failure,
                             :stage,
                             :stage_idx,
                             :environment)

          build_attrs.merge!(ref: @pipeline.ref,
                             tag: @pipeline.tag,
                             trigger_request: trigger_request,
                             user: user,
                             project: @pipeline.project)

          @pipeline.builds.create!(build_attrs)
        end
      end
    end

    private

    def config_processor
      @config_processor ||= @pipeline.config_processor
    end
  end
end
