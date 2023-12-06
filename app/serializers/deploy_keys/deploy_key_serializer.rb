# frozen_string_literal: true

module DeployKeys
  class DeployKeySerializer < BaseSerializer
    entity DeployKeyEntity
    include WithPagination
  end
end
