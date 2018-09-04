module EE
  module Boards
    module BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def set_assignee
        assignee = ::User.find_by(id: params.delete(:assignee_id))
        params.merge!(assignee: assignee)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def set_milestone
        milestone_id = params[:milestone_id]

        return unless milestone_id

        return if [::Milestone::None.id,
                   ::Milestone::Upcoming.id,
                   ::Milestone::Started.id].include?(milestone_id)

        finder_params =
          case parent
          when Group
            { group_ids: [parent.id] }
          when Project
            { project_ids: [parent.id], group_ids: [parent.group&.id] }
          end

        milestone = ::MilestonesFinder.new(finder_params).find_by(id: milestone_id)

        params[:milestone_id] = milestone&.id
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def set_labels
        labels = params.delete(:labels)

        return unless labels

        params[:label_ids] = labels.split(",").map do |label_name|
          label = Labels::FindOrCreateService.new(
            current_user,
            parent,
            title: label_name.strip,
            include_ancestor_groups: true
          ).execute

          label.try(:id)
        end.compact
      end
    end
  end
end
