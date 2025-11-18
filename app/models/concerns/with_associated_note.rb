# frozen_string_literal: true

# `#note_namespace_id`: This method needs to be defined in the model
module WithAssociatedNote # rubocop:disable Gitlab/BoundedContexts -- general purpose concern for ApplicationRecord
  extend ActiveSupport::Concern

  included do
    validates :namespace_id, presence: true, on: :create, unless: -> { skip_namespace_validation? }

    before_validation :ensure_namespace_id, on: :create, unless: -> { skip_namespace_validation? }

    private

    def skip_namespace_validation?
      false
    end

    def ensure_namespace_id
      self.namespace_id ||= note_namespace_id
    end

    def note_namespace_id
      raise NoMethodError, 'must implement `note_namespace_id` method'
    end
  end
end
