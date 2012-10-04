module NoteRepository
  included do
    scope :common, where(noteable_id: nil)
    scope :today, where("created_at >= :date", date: Date.today)
    scope :last_week, where("created_at  >= :date", date: (Date.today - 7.days))
    scope :since, lambda { |day| where("created_at  >= :date", date: (day)) }
    scope :fresh, order("created_at ASC, id ASC")
    scope :inc_author_project, includes(:project, :author)
    scope :inc_author, includes(:author)
  end
end
