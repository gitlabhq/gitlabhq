class Board < ActiveRecord::Base
  belongs_to :project
  belongs_to :milestone

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all

  validates :name, :project, presence: true

  def closed_list
    lists.merge(List.closed).take
  end

  def milestone
    if milestone_id == Milestone::Upcoming.id
      Milestone::Upcoming
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
