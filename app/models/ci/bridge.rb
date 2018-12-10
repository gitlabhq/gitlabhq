# frozen_string_literal: true

module Ci
  class Bridge < CommitStatus
    include Importable
    include AfterCommitQueue
    include TokenAuthenticatable
    include Gitlab::Utils::StrongMemoize

    belongs_to :project, inverse_of: :builds

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    validates :ref, presence: true

    before_save :ensure_token

    add_authentication_token_field :token, encrypted: true

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
