# frozen_string_literal: true

module Types
  module Ci
    class PipelineScheduleSortEnum < BaseEnum
      graphql_name 'PipelineScheduleSort'
      description 'Values for sorting pipeline schedules.'

      value 'ID_DESC', 'Sort pipeline schedules by ID in descending order.', value: :id_desc
      value 'ID_ASC', 'Sort pipeline schedules by ID in ascending order.', value: :id_asc
      value 'DESCRIPTION_DESC', 'Sort pipeline schedules by description in descending order.', value: :description_desc
      value 'DESCRIPTION_ASC', 'Sort pipeline schedules by description in ascending order.', value: :description_asc
      value 'REF_DESC', 'Sort pipeline schedules by target in descending order.', value: :ref_desc
      value 'REF_ASC', 'Sort pipeline schedules by target in ascending order.', value: :ref_asc
      value 'NEXT_RUN_AT_DESC', 'Sort pipeline schedules by next run in descending order.', value: :next_run_at_desc
      value 'NEXT_RUN_AT_ASC', 'Sort pipeline schedules by next run in ascending order.', value: :next_run_at_asc
      value 'CREATED_AT_DESC', 'Sort pipeline schedules by created date in descending order.', value: :created_at_desc
      value 'CREATED_AT_ASC', 'Sort pipeline schedules by created date in ascending order.', value: :created_at_asc
      value 'UPDATED_AT_DESC', 'Sort pipeline schedules by updated date in descending order.', value: :updated_at_desc
      value 'UPDATED_AT_ASC', 'Sort pipeline schedules by updated date in ascending order.', value: :updated_at_asc
    end
  end
end
