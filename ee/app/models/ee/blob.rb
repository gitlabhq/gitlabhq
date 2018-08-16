# frozen_string_literal: true

module EE
  module Blob
    extend ActiveSupport::Concern

    def owners
      @owners ||= ::Gitlab::CodeOwners.for_blob(self)
    end
  end
end
