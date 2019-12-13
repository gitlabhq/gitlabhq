# frozen_string_literal: true

class VariableEntity < Grape::Entity
  prepend ::EE::VariableEntity # rubocop: disable Cop/InjectEnterpriseEditionModule

  expose :id
  expose :key
  expose :value

  expose :protected?, as: :protected
  expose :masked?, as: :masked
end
