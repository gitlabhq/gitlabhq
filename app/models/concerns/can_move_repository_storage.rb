# frozen_string_literal: true

module CanMoveRepositoryStorage
  extend ActiveSupport::Concern

  RepositoryReadOnlyError = Class.new(StandardError)

  # Tries to set repository as read_only, checking for existing Git transfers in
  # progress beforehand. Setting a repository read-only will fail if it is
  # already in that state.
  #
  # It is assumed that `with_lock` is used here to ensure that no race condition
  # appears between reading and writing the read-only column.
  #
  # @return nil. Failures will raise an exception
  def set_repository_read_only!(skip_git_transfer_check: false)
    with_lock do
      raise RepositoryReadOnlyError, _('Git transfer in progress') if
        !skip_git_transfer_check && git_transfer_in_progress?

      raise RepositoryReadOnlyError, _('Repository already read-only') if
        safe_read_repository_read_only_column

      raise ActiveRecord::RecordNotSaved, _('Database update failed') unless
        update_repository_read_only_column(true)

      nil
    end
  end

  # Set repository as writable again. Unlike setting it read-only, this will
  # succeed if the repository is already writable.
  def set_repository_writable!
    raise ActiveRecord::RecordNotSaved, _('Database update failed') unless
      update_repository_read_only_column(false)
  end

  def git_transfer_in_progress?
    reference_counter(type: repository.repo_type).value > 0
  end

  def reference_counter(type:)
    Gitlab::ReferenceCounter.new(type.identifier_for_container(self))
  end

  private

  # Not all resources that can move repositories have the `repository_read_only`
  # in their table, for example groups. We need these methods to override the
  # behavior in those classes in order to access the column.
  def safe_read_repository_read_only_column
    # This was added originally this way because of
    # https://gitlab.com/gitlab-org/gitlab/-/commit/43f9b98302d3985312c9f8b66018e2835d8293d2
    self.class.where(id: id).pick(:repository_read_only)
  end

  def update_repository_read_only_column(value)
    update_column(:repository_read_only, value)
  end
end
