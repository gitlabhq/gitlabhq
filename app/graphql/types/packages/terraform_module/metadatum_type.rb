# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      class MetadatumType < BaseObject
        graphql_name 'TerraformModuleMetadata'
        description 'Terraform module metadata'

        authorize :read_package

        field :created_at, Types::TimeType, null: false, description: 'Timestamp of when the metadata was created.'
        field :fields, Types::Packages::TerraformModule::Metadatum::FieldsType, null: false,
          description: 'Fields of the metadata.'
        field :id, ::Types::GlobalIDType[::Packages::TerraformModule::Metadatum], null: false,
          description: 'ID of the metadata.'
        field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the metadata was last updated.'
      end
    end
  end
end
