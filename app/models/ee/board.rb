module EE
  module Board
    extend ActiveSupport::Concern

    prepended do
      belongs_to :milestone
      belongs_to :group

      validates :group, presence: true, unless: :project
    end

    def milestone
      return nil unless project.feature_available?(:issue_board_milestone)

      if milestone_id == ::Milestone::Upcoming.id
        ::Milestone::Upcoming
      else
        super
      end
    end

    def as_json(options = {})
      milestone_attrs = options.fetch(:include, {})
                          .extract!(:milestone)
                          .dig(:milestone, :only)

      super(options).tap do |json|
        if milestone.present? && milestone_attrs.present?
          json[:milestone] = milestone_attrs.each_with_object({}) do |attr, json|
            json[attr] = milestone.public_send(attr)
          end
        end
      end
    end
  end
end
