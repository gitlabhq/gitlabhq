# We don't want to ever call Rugged::Repository#fetch_attributes, because it has
# a lot of I/O overhead:
# <https://gitlab.com/gitlab-org/gitlab_git/commit/340e111e040ae847b614d35b4d3173ec48329015>
#
# While we don't do this from within the GitLab source itself, the Linguist gem
# has a dependency on Rugged and uses the gitattributes file when calculating
# repository-wide language statistics:
# <https://github.com/github/linguist/blob/v4.7.0/lib/linguist/lazy_blob.rb#L33-L36>
#
# The options passed by Linguist are those assumed by Gitlab::Git::Attributes
# anyway, and there is no great efficiency gain from just fetching the listed
# attributes with our implementation, so we ignore the additional arguments.
#
module Rugged
  class Repository
    module UseGitlabGitAttributes
      def fetch_attributes(name, *)
        attributes.attributes(name)
      end

      def attributes
        @attributes ||= Gitlab::Git::Attributes.new(path)
      end
    end

    prepend UseGitlabGitAttributes
  end
end
