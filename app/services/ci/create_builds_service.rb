module Ci
  class CreateBuildsService
    def execute(commit, stage, ref, tag, user, trigger_request)
      builds_attrs = commit.config_processor.builds_for_stage_and_ref(stage, ref, tag)

      builds_attrs.map do |build_attrs|
        # don't create the same build twice
        unless commit.builds.find_by(ref: ref, tag: tag, trigger_request: trigger_request, name: build_attrs[:name])
          build_attrs.slice!(:name,
                             :commands,
                             :tag_list,
                             :options,
                             :allow_failure,
                             :stage,
                             :stage_idx)

          build_attrs.merge!(ref: ref,
                             tag: tag,
                             trigger_request: trigger_request,
                             user: user)

          commit.builds.create!(build_attrs)
        end
      end
    end
  end
end
