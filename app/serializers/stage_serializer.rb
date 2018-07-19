# frozen_string_literal: true

class StageSerializer < BaseSerializer
  include WithPagination

  InvalidResourceError = Class.new(StandardError)

  entity StageEntity
end
