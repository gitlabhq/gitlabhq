module EE
  module Board
    extend ActiveSupport::Concern

    prepended do
      belongs_to :group
      belongs_to :milestone

      has_many :board_labels

      # These can safely be changed to has_many when we support
      # multiple assignees on the board configuration.
      # https://gitlab.com/gitlab-org/gitlab-ee/issues/3786
      has_one :board_assignee
      has_one :assignee, through: :board_assignee

      has_many :labels, through: :board_labels

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

      case milestone_id
      when ::Milestone::Upcoming.id
        ::Milestone::Upcoming
      when ::Milestone::Started.id
        ::Milestone::Started
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
