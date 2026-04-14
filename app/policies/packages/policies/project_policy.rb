# frozen_string_literal: true

module Packages
  module Policies
    class ProjectPolicy < BasePolicy
      delegate { @subject.project }

      condition(:packages_enabled_for_everyone, scope: :subject) do
        @subject.package_registry_access_level == ProjectFeature::PUBLIC &&
          Gitlab::CurrentSettings.package_registry_allow_anyone_to_pull_option
      end

      rule { packages_enabled_for_everyone }.policy do
        enable :read_package
      end
    end
  end
end
