# frozen_string_literal: true

return unless defined?(::Puma::ThreadPool)

unless Gem::Version.new(::Puma::Const::PUMA_VERSION) == Gem::Version.new('8.0.2')
  raise <<~ERROR
    Gitlab::Patch::PumaIoThreadExit is pinned to puma 8.0.2!

    Puma 8.0.2 does not lower its thread count when an extra IO thread exits,
    so env['puma.mark_as_io_bound'] stops adding threads after a few requests.
    https://github.com/puma/puma/pull/3968 fixes this upstream.

    Before you bump Puma, check that the new release:
    - includes https://github.com/puma/puma/pull/3968, and
    - does not count IO threads as busy in the queue_requests false admission
      gate added by https://github.com/puma/puma/pull/3969.

    Then delete these files:
    - config/initializers/puma_io_thread_exit_patch.rb
    - lib/gitlab/patch/puma_io_thread_exit.rb
    - spec/lib/gitlab/patch/puma_io_thread_exit_spec.rb
  ERROR
end

::Puma::ThreadPool.prepend(::Gitlab::Patch::PumaIoThreadExit)
