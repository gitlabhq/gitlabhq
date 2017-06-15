class IssueLink < ActiveRecord::Base
  belongs_to :source, class_name: 'Issue'
  belongs_to :target, class_name: 'Issue'

  validates :source, presence: true
  validates :target, presence: true
  validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
  validate :check_self_relation

  private

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end
end
