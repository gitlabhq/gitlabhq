# frozen_string_literal: true

class RemoteMirrorFinder
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    RemoteMirror.find_by(id: params[:id])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
