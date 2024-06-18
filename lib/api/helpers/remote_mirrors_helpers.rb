# frozen_string_literal: true

module API
  module Helpers
    module RemoteMirrorsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :mirror_branches_setting_ce do
        optional :only_protected_branches, type: Boolean, desc: 'Determines if only protected branches are mirrored'
      end

      params :mirror_branches_setting_ee do
      end

      params :mirror_branches_setting do
        use :mirror_branches_setting_ce
        use :mirror_branches_setting_ee
      end
    end
  end
end

API::Helpers::RemoteMirrorsHelpers.prepend_mod
