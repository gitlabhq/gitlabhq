module EE
  module Board
    extend ActiveSupport::Concern

    prepended do
      has_one :board_filter

      belongs_to :group

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
