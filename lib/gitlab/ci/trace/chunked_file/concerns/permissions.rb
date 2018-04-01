module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Permissions
            extend ActiveSupport::Concern

            included do
              PermissionError = Class.new(StandardError)

              attr_reader :write_lock_uuid

              # mode checks
              before_method :read, :can_read!
              before_method :readline, :can_read!
              before_method :each_line, :can_read!
              before_method :write, :can_write!
              before_method :truncate, :can_write!

              # write_lock
              before_method :write, :check_lock!
              before_method :truncate, :check_lock!
            end

            def initialize(job_id, size, mode = 'rb')
              if /(w|a)/ =~ mode
                @write_lock_uuid = Gitlab::ExclusiveLease
                  .new(write_lock_key, timeout: 1.hour.to_i).try_obtain

                raise PermissionError, 'Already opened by another process' unless write_lock_uuid
              end

              super
            end

            def close
              if write_lock_uuid
                Gitlab::ExclusiveLease.cancel(write_lock_key, write_lock_uuid)
              end

              super
            end

            def check_lock!
              raise PermissionError, 'Could not write without lock' unless write_lock_uuid
            end

            def can_read!
              raise IOError, 'not opened for reading' unless /(r|+)/ =~ mode
            end

            def can_write!
              raise IOError, 'not opened for writing' unless /(w|a)/ =~ mode
            end

            def write_lock_key
              "live_trace:operation:write:#{job_id}"
            end
          end
        end
      end
    end
  end
end
