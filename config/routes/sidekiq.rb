# frozen_string_literal: true

constraints ::Constraints::AdminConstrainer.new do
  mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
end
