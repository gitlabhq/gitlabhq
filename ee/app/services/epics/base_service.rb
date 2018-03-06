module Epics
  class BaseService < IssuableBaseService
    attr_reader :group

    def initialize(group, current_user, params)
      @group, @current_user, @params = group, current_user, params
    end

    private

    def available_labels
      @available_labels ||= LabelsFinder.new(
        current_user,
        group_id: group.id,
        only_group_labels: true,
        include_ancestor_groups: true
      ).execute
    end

    def parent
      group
    end
  end
end
