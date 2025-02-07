# frozen_string_literal: true

module ArchivedAbilities
  extend ActiveSupport::Concern

  ARCHIVED_ABILITIES = %i[
    admin_tag
    push_code
    push_to_delete_protected_branch
    request_access
    upload_file
    resolve_note
    create_merge_request_from
    create_merge_request_in
    award_emoji
    create_incident
  ].freeze

  ARCHIVED_FEATURES = %i[
    issue
    issue_board_list
    merge_request
    label
    milestone
    snippet
    wiki
    design
    note
    pipeline
    pipeline_schedule
    build
    trigger
    environment
    deployment
    commit_status
    container_image
    pages
    cluster
    release
    timelog
    package
  ].freeze

  class_methods do
    def archived_abilities
      ARCHIVED_ABILITIES
    end

    def archived_features
      ARCHIVED_FEATURES
    end
  end
end

ArchivedAbilities::ClassMethods.prepend_mod_with('ArchivedAbilities::ClassMethods')
