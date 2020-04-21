# frozen_string_literal: true

module API
  module Entities
    class ContainerExpirationPolicy < Grape::Entity
      expose :cadence
      expose :enabled
      expose :keep_n
      expose :older_than
      expose :name_regex
      expose :name_regex_keep
      expose :next_run_at
    end
  end
end
