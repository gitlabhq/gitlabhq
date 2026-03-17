# frozen_string_literal: true

module MergeRequests
  class LinkedWorkItem
    include ActiveModel::Validations

    attr_reader :work_item, :external_issue, :link_type

    validates_with ExactlyOnePresentValidator, fields: %i[work_item external_issue]

    def initialize(link_type:, work_item: nil, external_issue: nil)
      @link_type = link_type
      @work_item = work_item
      @external_issue = external_issue

      validate!
    end
  end
end
