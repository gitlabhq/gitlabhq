# frozen_string_literal: true

class LooseForeignKeys::DeletedRecord < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning
end
