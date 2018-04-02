module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Permissions
            extend ActiveSupport::Concern

            WRITABLE_MODE = %w[a].freeze
            READABLE_MODE = %w[r +].freeze

            included do
              attr_reader :write_lock_uuid
            end

            def initialize(job_id, size, mode = 'rb')
              if WRITABLE_MODE.any? { |m| mode.include?(m) }
                @write_lock_uuid = Gitlab::ExclusiveLease
                  .new(write_lock_key(job_id), timeout: 1.hour.to_i).try_obtain

                raise IOError, 'Already opened by another process' unless write_lock_uuid
              end

              super
            end

            def close
              if write_lock_uuid
                Gitlab::ExclusiveLease.cancel(write_lock_key(job_id), write_lock_uuid)
              end

              super
            end

            def read(*args)
              can_read!

              super
            end

            def readline(*args)
              can_read!

              super
            end

            def each_line(*args)
              can_read!

              super
            end

            def write(*args)
              can_write!

              super
            end

            def truncate(*args)
              can_write!

              super
            end

            def delete(*args)
              can_write!

              super
            end

            private

            def can_read!
              unless READABLE_MODE.any? { |m| mode.include?(m) }
                raise IOError, 'not opened for reading'
              end
            end

            def can_write!
              unless WRITABLE_MODE.any? { |m| mode.include?(m) }
                raise IOError, 'not opened for writing'
              end
            end

            def write_lock_key(job_id)
              "live_trace:operation:write:#{job_id}"
            end
          end
        end
      end
    end
  end
end
