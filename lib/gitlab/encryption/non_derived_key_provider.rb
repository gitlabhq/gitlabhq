# frozen_string_literal: true

module Gitlab
  module Encryption
    class NonDerivedKeyProvider < ActiveRecord::Encryption::KeyProvider
      def initialize(passwords)
        super(Array(passwords).collect { |password| ActiveRecord::Encryption::Key.new(password) })
      end
    end
  end
end
