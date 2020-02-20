# frozen_string_literal: true

module DeleteWithLimit
  extend ActiveSupport::Concern

  class_methods do
    def delete_with_limit(maximum)
      limit(maximum).delete_all
    end
  end
end
