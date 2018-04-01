module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Callbacks
            extend ActiveSupport::Concern

            included do
              class_attribute :_before_callbacks, :_after_callbacks,
                :instance_writer => false
              self._before_callbacks = Hash.new []
              self._after_callbacks = Hash.new []
            end

            def with_callbacks(kind, *args)
              self.class._before_callbacks[kind].each { |c| send c, *args }
              yield
              self.class._after_callbacks[kind].each { |c| send c, *args }
            end

            module ClassMethods
              def before_callback(kind, callback)
                self._before_callbacks = self._before_callbacks.
                  merge kind => _before_callbacks[kind] + [callback]
              end

              def after_callback(kind, callback)
                self._after_callbacks = self._after_callbacks.
                  merge kind => _after_callbacks[kind] + [callback]
              end
            end
          end
        end
      end
    end
  end
end
