# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Contacts
      class Base < BaseMutation
        include ResolvesIds
        include Gitlab::Graphql::Authorize::AuthorizeResource

        field :contact,
          Types::CustomerRelations::ContactType,
          null: true,
          description: 'Contact after the mutation.'

        authorize :admin_crm_contact

        def set_organization!(args)
          return unless args[:organization_id]

          args[:organization_id] = args[:organization_id].model_id
        end
      end
    end
  end
end
