# frozen_string_literal: true

module ProjectScopedCommitSignature
  extend ActiveSupport::Concern

  class_methods do
    extend ::Gitlab::Utils::Override

    override :safe_create!
    def safe_create!(attributes)
      create_with(attributes)
        .safe_find_or_create_by!( # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- This overrides an existent class method defined in CommitSignature concern
          project_id: attributes[:project].id,
          commit_sha: attributes[:commit_sha]
        )
    end
  end
end
