# frozen_string_literal: true

module Metrics # rubocop:disable Gitlab/BoundedContexts -- Module already exists but not defined as bounded context yet
  class PatchedFilesWorker
    include ApplicationWorker

    idempotent!
    worker_has_external_dependencies!

    data_consistency :sticky
    feature_category :delivery
    urgency :low

    REDIS_KEY = 'patched_files'

    def perform
      files = patched_files
      return unless files

      Gitlab::Redis::SharedState.with do |redis|
        redis.set(REDIS_KEY, files)
      end
    end

    private

    def package_name
      Gitlab.ee? ? 'gitlab-ee' : 'gitlab-ce'
    end

    def patched_files
      output, _ = Open3.capture2("rpm --verify #{package_name}")
      return if output.include?('is not installed')

      take_lines(output, 20)
    rescue # rubocop:disable Style/RescueStandardError -- Open3.capture2 can raise an exception
    end

    def take_lines(string, lines)
      string.each_line.reject do |line|
        line.ends_with?("/db/structure.sql\n") ||
          line.include?('/lib/ruby/gems/')
      end.first(lines).join
    end
  end
end
