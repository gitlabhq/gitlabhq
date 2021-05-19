# frozen_string_literal: true

module ReadonlyAbilities
  extend ActiveSupport::Concern

  READONLY_ABILITIES = %i[
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

  READONLY_FEATURES = %i[
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
  ].freeze

  class_methods do
    def readonly_abilities
      READONLY_ABILITIES
    end

    def readonly_features
      READONLY_FEATURES
    end
  end
end

ReadonlyAbilities::ClassMethods.prepend_mod_with('ReadonlyAbilities::ClassMethods')
