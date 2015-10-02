module Ci
  class CreateBuildsService
    def execute(commit, ref, tag, push_data, config_processor, trigger_request)
      config_processor.stages.any? do |stage|
        builds_attrs = config_processor.builds_for_stage_and_ref(stage, ref, tag)
        builds_attrs.map do |build_attrs|
          # don't create the same build twice
          unless commit.builds.find_by_name_and_trigger_request(name: build_attrs[:name], ref: ref, tag: tag, trigger_request: trigger_request)
            commit.builds.create!({
                             name: build_attrs[:name],
                             commands: build_attrs[:script],
                             tag_list: build_attrs[:tags],
                             options: build_attrs[:options],
                             allow_failure: build_attrs[:allow_failure],
                             stage: build_attrs[:stage],
                             stage_idx: build_attrs[:stage_idx],
                             trigger_request: trigger_request,
                             ref: ref,
                             tag: tag,
                             push_data: push_data,
                           })
          end
        end
      end
    end
  end
end
