module Ci
  class CreateBuildsService
    def initialize(commit)
      @commit = commit
      @config = commit.config_processor
    end

    def execute(stage, user, status, trigger_request = nil)
      builds_attrs = @config.builds_for_stage_and_ref(stage, @commit.ref, @commit.tag, trigger_request)

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

      # don't create the same build twice
      builds_attrs.reject! do |build_attrs|
        @commit.builds.find_by(ref: @commit.ref, tag: @commit.tag,
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
                           :stage_idx)

        build_attrs.merge!(commit: @commit,
                           ref: @commit.ref,
                           tag: @commit.tag,
                           trigger_request: trigger_request,
                           user: user,
                           project: @commit.project)

        ##
        # We do not persist new builds here.
        # Those will be persisted when @commit is saved.
        #
        @commit.builds.new(build_attrs)
      end
    end
  end
end
