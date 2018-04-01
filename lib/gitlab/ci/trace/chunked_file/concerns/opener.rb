module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Opener
            extend ActiveSupport::Concern

            class_methods do
              def open(*args)
                stream = self.new(*args)

                yield stream
              ensure
                stream&.close
              end
            end
          end
        end
      end
    end
  end
end
