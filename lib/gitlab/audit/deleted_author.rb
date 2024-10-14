# frozen_string_literal: true

module Gitlab
  module Audit
    class DeletedAuthor < Gitlab::Audit::NullAuthor
      def impersonated?
        false
      end
    end
  end
end
