# frozen_string_literal: true

module CheckCodeownerRules
  extend ActiveSupport::Concern

  def codeowners_check_error(project, branch_name, paths)
    ::Gitlab::CodeOwners::Validator.new(project, branch_name, paths).execute
  end
end
