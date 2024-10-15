# frozen_string_literal: true

return unless Gitlab::Runtime.puma?

require 'puma'
require 'puma/cluster'

# Ruby 3.1 and 3.2 have bugs that prevents Puma from reaping child processes properly:
# https://bugs.ruby-lang.org/issues/20490
# https://bugs.ruby-lang.org/issues/19837
#
# https://github.com/puma/puma/pull/3314 fixes this in Puma, but a release
# has not been forthcoming.
if Gem::Version.new(Puma::Const::PUMA_VERSION) > Gem::Version.new('6.5')
  raise 'This patch should not be needed after Puma 6.5.0.'
end

# rubocop:disable Style/RedundantBegin -- These are upstream changes
# rubocop:disable Cop/LineBreakAfterGuardClauses -- These are upstream changes
# rubocop:disable Layout/EmptyLineAfterGuardClause -- These are upstream changes
module Puma
  class Cluster < Runner
    # loops thru @workers, removing workers that exited, and calling
    # `#term` if needed
    def wait_workers
      # Reap all children, known workers or otherwise.
      # If puma has PID 1, as it's common in containerized environments,
      # then it's responsible for reaping orphaned processes, so we must reap
      # all our dead children, regardless of whether they are workers we spawned
      # or some reattached processes.
      reaped_children = {}
      loop do
        begin
          pid, status = Process.wait2(-1, Process::WNOHANG)
          break unless pid
          reaped_children[pid] = status
        rescue Errno::ECHILD
          break
        end
      end

      @workers.reject! do |w|
        next false if w.pid.nil?
        begin
          # We may need to check the PID individually because:
          # 1. From Ruby versions 2.6 to 3.2, `Process.detach` can prevent or delay
          #    `Process.wait2(-1)` from detecting a terminated process: https://bugs.ruby-lang.org/issues/19837.
          # 2. When `fork_worker` is enabled, some worker may not be direct children,
          #    but grand children.  Because of this they won't be reaped by `Process.wait2(-1)`.
          if reaped_children.delete(w.pid) || Process.wait(w.pid, Process::WNOHANG)
            true
          else
            w.term if w.term?
            nil
          end
        rescue Errno::ECHILD
          begin
            Process.kill(0, w.pid)
            # child still alive but has another parent (e.g., using fork_worker)
            w.term if w.term?
            false
          rescue Errno::ESRCH, Errno::EPERM
            true # child is already terminated
          end
        end
      end

      # Log unknown children
      reaped_children.each do |pid, status|
        log "! reaped unknown child process pid=#{pid} status=#{status}"
      end
    end
  end
end
# rubocop:enable Style/RedundantBegin
# rubocop:enable Cop/LineBreakAfterGuardClauses
# rubocop:enable Layout/EmptyLineAfterGuardClause
