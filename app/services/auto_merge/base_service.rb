# frozen_string_literal: true

module AutoMerge
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(merge_request)
      merge_request.merge_params.merge!(params)
      merge_request.auto_merge_enabled = true
      merge_request.merge_user = current_user
      merge_request.auto_merge_strategy = strategy

      return :failed unless merge_request.save

      yield if block_given?

      # Notify the event that auto merge is enabled or merge param is updated
      AutoMergeProcessWorker.perform_async(merge_request.id)

      strategy.to_sym
    end

    def update(merge_request)
      merge_request.merge_params.merge!(params)

      return :failed unless merge_request.save

      strategy.to_sym
    end

    def cancel(merge_request)
      if clear_auto_merge_parameters(merge_request)
        yield if block_given?

        success
      else
        error("Can't cancel the automatic merge", 406)
      end
    end

    def abort(merge_request, reason)
      if clear_auto_merge_parameters(merge_request)
        yield if block_given?

        success
      else
        error("Can't abort the automatic merge", 406)
      end
    end

    private

    def strategy
      strong_memoize(:strategy) do
        self.class.name.demodulize.remove('Service').underscore
      end
    end

    def clear_auto_merge_parameters(merge_request)
      merge_request.auto_merge_enabled = false
      merge_request.merge_user = nil

      merge_request.merge_params&.except!(
        'should_remove_source_branch',
        'commit_message',
        'squash_commit_message',
        'auto_merge_strategy'
      )

      merge_request.save
    end
  end
end
