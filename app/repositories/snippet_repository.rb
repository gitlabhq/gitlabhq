module SnippetRepository
  included do
    scope :fresh, order("created_at DESC")
    scope :non_expired, where(["expires_at IS NULL OR expires_at > ?", Time.current])
    scope :expired, where(["expires_at IS NOT NULL AND expires_at < ?", Time.current])
  end
end
