# frozen_string_literal: true

module Gitlab
  module Git
    class TagPolicy < BasePolicy
      delegate { project }

      condition(:protected_tag, scope: :subject) do
        ProtectedTag.protected?(project, @subject.name)
      end

      rule { can?(:admin_tag) & (~protected_tag | can?(:maintainer_access)) }.enable :delete_tag

      def project
        @subject.repository.container
      end
    end
  end
end
