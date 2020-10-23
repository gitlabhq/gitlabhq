# frozen_string_literal: true

module BulkImports
  module Pipeline
    extend ActiveSupport::Concern

    included do
      include Attributes
      include Runner
    end
  end
end
