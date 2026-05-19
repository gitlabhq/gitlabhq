# frozen_string_literal: true

module RapidDiffs
  class DiffRefsEntity < Grape::Entity
    expose :base_sha
    expose :start_sha
    expose :head_sha
  end
end
