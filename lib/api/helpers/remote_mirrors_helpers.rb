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

      params :host_key_params do
        optional :host_keys, type: Array[String],
          desc: 'SSH host keys in bare format (ssh-ed25519 AAAA...) ' \
            'or full known_hosts format (hostname ssh-ed25519 AAAA...). ' \
            'Bare keys use the hostname from the mirror URL.'
      end
    end
  end
end

API::Helpers::RemoteMirrorsHelpers.prepend_mod
