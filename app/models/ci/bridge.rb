# frozen_string_literal: true

module Ci
  class Bridge < CommitStatus
    include Importable
    include AfterCommitQueue
    include Gitlab::Utils::StrongMemoize

    belongs_to :project
    validates :ref, presence: true

    def self.retry(bridge, current_user)
      raise NotImplementedError
    end

    def tags
      [:bridge]
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Bridge::Factory
        .new(self, current_user)
        .fabricate!
    end

    def predefined_variables
      raise NotImplementedError
    end

    def execute_hooks
      raise NotImplementedError
    end
  end
end
