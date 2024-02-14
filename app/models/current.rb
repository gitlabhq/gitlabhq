# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes # rubocop:disable Gitlab/NamespacedClass -- We want this to be top level due to scope of use and no namespace due to ease of calling
  # watch background jobs need to reset on each job if using
  attribute :organization
end
