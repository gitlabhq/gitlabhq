# frozen_string_literal: true
# Monkey patch for Grape v1.4.0: https://github.com/ruby-grape/grape/pull/2088

require 'grape'

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Grape
  module DSL
    module InsideRoute
      def stream(value = nil)
        return if value.nil? && @stream.nil?

        header 'Content-Length', nil
        header 'Transfer-Encoding', nil
        header 'Cache-Control', 'no-cache' # Skips ETag generation (reading the response up front)

        if value.is_a?(String)
          file_body = Grape::ServeStream::FileBody.new(value)
          @stream = Grape::ServeStream::StreamResponse.new(file_body)
        elsif value.respond_to?(:each)
          @stream = Grape::ServeStream::StreamResponse.new(value)
        elsif !value.is_a?(NilClass)
          raise ArgumentError, 'Stream object must respond to :each.'
        else
          @stream
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
