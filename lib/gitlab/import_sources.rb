# Gitlab::ImportSources module
#
# Define import sources that can be used
# during the creation of new project
#
module Gitlab
  module ImportSources
    extend CurrentSettings

    class << self
      def values
        options.values
      end

      def options
        {
          'GitHub'          => 'github',
          'Bitbucket'       => 'bitbucket',
          'GitLab.com'      => 'gitlab',
          'Gitorious.org'   => 'gitorious',
          'Google Code'     => 'google_code',
          'FogBugz'         => 'fogbugz',
          'Any repo by URL' => 'git',
        }
      end

    end

  end
end
