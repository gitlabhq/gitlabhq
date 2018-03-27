# rubocop:disable GitlabSecurity/PublicSend

module API
  module Helpers
    module MembersHelpers
      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_admin_source!(source_type, source)
        authorize! :"admin_#{source_type}", source
      end
    end
  end
end
