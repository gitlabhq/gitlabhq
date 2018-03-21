module Ci
  class CreatePipelineStagesService < BaseService
    def execute(pipeline)
      pipeline.stage_seeds.each do |seed|
        seed.user = current_user
        seed.create!
      end
    end
  end
end
