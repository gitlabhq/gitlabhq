# frozen_string_literal: true

return unless Rails.env.test?

Rails.application.configure do
  config.after_initialize do
    # We don't care about ActiveJob reloading the code in test env as we run
    # jobs inline in test env.
    # So in test, we remove this callback, which calls app.reloader.wrap, and
    # ultimately calls FileUpdateChecker#updated? which is slow on macOS
    #
    # https://github.com/rails/rails/blob/6-0-stable/activejob/lib/active_job/railtie.rb#L39-L46
    def active_job_railtie_callback?
      callbacks = ActiveJob::Callbacks.singleton_class.__callbacks[:execute]

      callbacks &&
        callbacks.send(:chain).size == 1 &&
        callbacks.first.kind == :around &&
        callbacks.first.filter.is_a?(Proc) &&
        callbacks.first.filter.source_location.first.ends_with?('lib/active_job/railtie.rb')
    end

    if active_job_railtie_callback?
      ActiveJob::Callbacks.singleton_class.reset_callbacks(:execute)
    end
  end
end
