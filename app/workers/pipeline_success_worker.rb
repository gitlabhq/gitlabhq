# frozen_string_literal: true

class PipelineSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      pipeline.all_merge_requests.preload(:merge_user).each do |merge_request|
        AutoMergeService.new(pipeline.project, merge_request.merge_user)
                        .process(merge_request)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
