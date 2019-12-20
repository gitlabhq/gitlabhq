# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Runtime < Source
              def content
                @command.config_content
              end

              def source
                # The only case when this source is used is when the config content
                # is passed in as parameter to Ci::CreatePipelineService.
                # This would only occur with parent/child pipelines which is being
                # implemented.
                # TODO: change source to return :runtime_source
                # https://gitlab.com/gitlab-org/gitlab/merge_requests/21041

                nil
              end
            end
          end
        end
      end
    end
  end
end
