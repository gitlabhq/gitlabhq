module SystemCheck
  module Geo
    class LicenseCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo is available'

      def check?
        Gitlab::Geo.license_allows?
      end

      def show_error
        try_fixing_it(
          'Upload a new license that includes the GitLab Geo feature'
        )

        for_more_information('https://about.gitlab.com/features/gitlab-geo/')
      end
    end
  end
end
