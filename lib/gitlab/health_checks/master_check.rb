# frozen_string_literal: true

module Gitlab
  module HealthChecks
    # This check is registered on master,
    # and validated by worker
    class MasterCheck
      extend SimpleAbstractCheck

      class << self
        def register_master
          # when we fork, we pass the read pipe to child
          # child can then react on whether the other end
          # of pipe is still available
          @pipe_read, @pipe_write = IO.pipe
        end

        def finish_master
          close_read
          close_write
        end

        def register_worker
          # fork needs to close the pipe
          close_write
        end

        private

        def close_read
          @pipe_read&.close
          @pipe_read = nil
        end

        def close_write
          @pipe_write&.close
          @pipe_write = nil
        end

        def metric_prefix
          'master_check'
        end

        def successful?(result)
          result
        end

        def check
          # the lack of pipe is a legitimate failure of check
          return false unless @pipe_read

          @pipe_read.read_nonblock(1)

          true
        rescue IO::EAGAINWaitReadable
          # if it is blocked, it means that the pipe is still open
          # and there's no data waiting on it
          true
        rescue EOFError
          # the pipe is closed
          false
        end
      end
    end
  end
end
