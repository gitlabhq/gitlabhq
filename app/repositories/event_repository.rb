module EventRepository
  included do
    scope :recent, order("created_at DESC")
    scope :code_push, where(action: Pushed)
  end
end
