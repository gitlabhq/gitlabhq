module API
  module Helpers
    module BadgesHelpers
      include ::API::Helpers::MembersHelpers

      def find_badge(source)
        source.badges.find(params[:badge_id])
      end

      def present_badges(source, records, options = {})
        entity_type = options[:with] || Entities::Badge
        badge_params = badge_source_params(source).merge(with: entity_type)

        present records, badge_params
      end

      def badge_source_params(source)
        project = if source.is_a?(Project)
                    source
                  else
                    GroupProjectsFinder.new(group: source, current_user: current_user).execute.first
                  end

        { project: project }
      end
    end
  end
end
