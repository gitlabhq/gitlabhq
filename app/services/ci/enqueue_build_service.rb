# frozen_string_literal: true
module Ci
  class EnqueueBuildService < BaseService
<<<<<<< HEAD
    prepend EE::Ci::EnqueueBuildService

=======
>>>>>>> upstream/master
    def execute(build)
      build.enqueue
    end
  end
end
