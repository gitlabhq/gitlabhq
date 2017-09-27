module EE
  module Board
    extend ActiveSupport::Concern

    prepended do
      belongs_to :group
      belongs_to :milestone
      belongs_to :author, class_name: 'User'
      belongs_to :assignee, class_name: 'User'

      has_many :board_filter_labels
      has_many :labels, through: :board_filter_labels

      validates :name, presence: true
      validates :group, presence: true, unless: :project
    end

    def project_needed?
      !group
    end

    def parent
      @parent ||= group || project
    end

    def group_board?
      group_id.present?
    end

    def milestone
      return nil unless parent.feature_available?(:scoped_issue_board)

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
            json[attr] = milestone.public_send(attr) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
