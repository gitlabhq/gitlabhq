class StageSerializer < BaseSerializer
  include WithPagination

  InvalidResourceError = Class.new(StandardError)

  entity StageEntity
end
