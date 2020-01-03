# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Bridge < Source
              def content
                return unless @command.bridge

                @command.bridge.yaml_for_downstream
              end

              def source
                :bridge_source
              end
            end
          end
        end
      end
    end
  end
end
