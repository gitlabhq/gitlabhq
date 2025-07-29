# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class GitInfo < Grape::Entity
          expose :repo_url, :ref, :sha, :before_sha
          expose :ref_type
          expose :refspecs
          expose :git_depth, as: :depth
          expose :repo_object_format
          expose :protected
        end
      end
    end
  end
end
