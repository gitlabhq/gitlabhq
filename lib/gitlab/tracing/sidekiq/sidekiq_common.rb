# frozen_string_literal: true

module Gitlab
  module Tracing
    module Sidekiq
      module SidekiqCommon
        include Gitlab::Tracing::Common

        def tags_from_job(job, kind)
          {
            'component' =>     'sidekiq',
            'span.kind' =>     kind,
            'sidekiq.queue' => job['queue'],
            'sidekiq.jid' =>   job['jid'],
            'sidekiq.retry' => job['retry'].to_s,
            'sidekiq.args' =>  job['args']&.join(", ")
          }
        end
      end
    end
  end
end
