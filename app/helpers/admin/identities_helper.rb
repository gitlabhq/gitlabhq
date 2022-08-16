# frozen_string_literal: true

module Admin
  module IdentitiesHelper
    def label_for_identity_provider(identity)
      provider = identity.provider
      "#{Gitlab::Auth::OAuth::Provider.label_for(provider)} (#{provider})"
    end

    def provider_id_cell_testid(identity)
      'provider_id_blank'
    end

    def provider_id(identity)
      '-'
    end

    def saml_group_cell_testid(identity)
      'saml_group_blank'
    end

    def saml_group_link(identity)
      '-'
    end

    def identity_cells_to_render?(identities, _user)
      identities.present?
    end

    def scim_identities_collection(_user)
      []
    end
  end
end

Admin::IdentitiesHelper.prepend_mod
