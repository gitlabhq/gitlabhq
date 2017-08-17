module AfterCommitQueue
  extend ActiveSupport::Concern

  included do
    after_commit :_run_after_commit_queue
    after_rollback :_clear_after_commit_queue
  end

  def run_after_commit(method = nil, &block)
    _after_commit_queue << proc { self.send(method) } if method
    _after_commit_queue << block if block
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
