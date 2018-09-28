# frozen_string_literal: true

class GroupSerializer < BaseSerializer
  include WithPagination

  entity GroupEntity
end
