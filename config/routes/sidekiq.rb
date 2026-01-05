# frozen_string_literal: true

constraints ::Authz::AdminConstraint.new do
  mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
end
