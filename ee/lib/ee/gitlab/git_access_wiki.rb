module EE
  module Gitlab
    module GitAccessWiki
      prepend GeoGitAccess

      private

      def project_or_wiki
        @project.wiki
      end
    end
  end
end
