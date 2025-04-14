# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Chunker
      extend ActiveSupport::Concern

      attr_accessor :content

      def chunks
        raise NotImplementedError
      end
    end
  end
end
