# frozen_string_literal: true

module AfterCommitQueue
  extend ActiveSupport::Concern

  included do
    after_commit :_run_after_commit_queue
    after_rollback :_clear_after_commit_queue
  end

  def run_after_commit(&block)
    _after_commit_queue << block if block

    true
  end

  def run_after_commit_or_now(&block)
    if Gitlab::Database.main.inside_transaction?
      if ActiveRecord::Base.connection.current_transaction.records&.include?(self)
        run_after_commit(&block)
      else
        # If the current transaction does not include this record, we can run
        # the block now, even if it queues a Sidekiq job.
        Sidekiq::Worker.skipping_transaction_check do
          instance_eval(&block)
        end
      end
    else
      instance_eval(&block)
    end

    true
  end

  protected

  def _run_after_commit_queue
    while action = _after_commit_queue.pop
      self.instance_eval(&action)
    end
  end

  def _after_commit_queue
    @after_commit_queue ||= []
  end

  def _clear_after_commit_queue
    _after_commit_queue.clear
  end
end
