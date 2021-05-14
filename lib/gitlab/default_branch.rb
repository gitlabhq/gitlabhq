# frozen_string_literal: true

# Class is used while we're migrating from master to main
module Gitlab
  module DefaultBranch
    def self.value(object: nil)
      Feature.enabled?(:main_branch_over_master, object, default_enabled: :yaml) ? 'main' : 'master'
    end
  end
end
