# frozen_string_literal: true

class FinalizeInvalidProjectMemberCleanup < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # noop: this fails because the cleanup invalid members migration(ScheduleDestroyInvalidProjectMembers)
    # cannot succeed, so we need to cleanup that first.
    #
    # issue with some details: https://gitlab.com/gitlab-org/gitlab/-/issues/365028#note_1107166816
    # # incident: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7779
  end

  def down
    # noop
  end
end
