# frozen_string_literal: true

module Types
  module Ci
    class PipelineMergeRequestEventTypeEnum < BaseEnum
      graphql_name 'PipelineMergeRequestEventType'
      description 'Event type of the pipeline associated with a merge request'

      value 'MERGED_RESULT',
        'Pipeline run on the changes from the source branch combined with the target branch.',
        value: :merged_result
      value 'DETACHED',
        'Pipeline run on the changes in the merge request source branch.',
        value: :detached
    end
  end
end

Types::Ci::PipelineMergeRequestEventTypeEnum.prepend_mod
