# frozen_string_literal: true

module CanMoveRepositoryStorage
  extend ActiveSupport::Concern

  RepositoryReadOnlyError = Class.new(StandardError)

  # Tries to set repository as read_only, checking for existing Git transfers in
  # progress beforehand. Setting a repository read-only will fail if it is
  # already in that state.
  #
  # @return nil. Failures will raise an exception
  def set_repository_read_only!(skip_git_transfer_check: false)
    with_lock do
      raise RepositoryReadOnlyError, _('Git transfer in progress') if
        !skip_git_transfer_check && git_transfer_in_progress?

      raise RepositoryReadOnlyError, _('Repository already read-only') if
        self.class.where(id: id).pick(:repository_read_only)

      raise ActiveRecord::RecordNotSaved, _('Database update failed') unless
        update_column(:repository_read_only, true)

      nil
    end
  end

  # Set repository as writable again. Unlike setting it read-only, this will
  # succeed if the repository is already writable.
  def set_repository_writable!
    with_lock do
      raise ActiveRecord::RecordNotSaved, _('Database update failed') unless
        update_column(:repository_read_only, false)

      nil
    end
  end

  def git_transfer_in_progress?
    reference_counter(type: repository.repo_type).value > 0
  end

  def reference_counter(type:)
    Gitlab::ReferenceCounter.new(type.identifier_for_container(self))
  end
end
