# frozen_string_literal: true

module Terraform
  class StateProtectionRule < ApplicationRecord
    belongs_to :project, inverse_of: :terraform_state_protection_rules

    enum :minimum_access_level_for_write, {
      developer: Gitlab::Access::DEVELOPER,
      maintainer: Gitlab::Access::MAINTAINER,
      owner: Gitlab::Access::OWNER,
      admin: Gitlab::Access::ADMIN
    }, prefix: true

    enum :allowed_from, {
      anywhere: 0,
      ci_only: 1,
      ci_on_protected_branch_only: 2
    }, prefix: true

    validates :state_name, presence: true, length: { maximum: 255 },
      uniqueness: { scope: :project_id }
    validates :minimum_access_level_for_write, presence: true
    validates :allowed_from, presence: true
  end
end
