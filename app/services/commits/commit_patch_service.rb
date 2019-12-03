# frozen_string_literal: true

module Commits
  class CommitPatchService < CreateService
    # Requires:
    # - project: `Project` to be committed into
    # - user: `User` that will be the committer
    # - params:
    #   - branch_name: `String` the branch that will be committed into
    #   - start_branch: `String` the branch that will be started from
    #   - patches: `Gitlab::Git::Patches::Collection` that contains the patches
    def initialize(*args)
      super

      @patches = Gitlab::Git::Patches::Collection.new(Array(params[:patches]))
    end

    private

    def new_branch?
      !repository.branch_exists?(@branch_name)
    end

    def create_commit!
      if @start_branch && new_branch?
        prepare_branch!
      end

      Gitlab::Git::Patches::CommitPatches
        .new(current_user, project.repository, @branch_name, @patches)
        .commit
    end

    def prepare_branch!
      branch_result = ::Branches::CreateService.new(project, current_user)
                        .execute(@branch_name, @start_branch)

      if branch_result[:status] != :success
        raise ChangeError, branch_result[:message]
      end
    end

    # Overridden from the Commits::CreateService, to skip some validations we
    # don't need:
    # - validate_on_branch!
    #   Not needed, the patches are applied on top of HEAD if the branch did not
    #   exist
    # - validate_branch_existence!
    #   Not needed because we continue applying patches on the branch if it
    #   already existed, and create it if it did not exist.
    def validate!
      validate_patches!
      validate_new_branch_name! if new_branch?
      validate_permissions!
    end

    def validate_patches!
      raise_error("Patches are too big") unless @patches.valid_size?
    end
  end
end
