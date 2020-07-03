# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Parameter < Source
              UnsupportedSourceError = Class.new(StandardError)

              def content
                strong_memoize(:content) do
                  next unless command.content.present?
                  raise UnsupportedSourceError, "#{command.source} not a dangling build" unless command.dangling_build?

                  command.content
                end
              end

              def source
                :parameter_source
              end
            end
          end
        end
      end
    end
  end
end
