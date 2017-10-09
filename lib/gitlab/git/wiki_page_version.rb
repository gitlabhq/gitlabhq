module Gitlab
  module Git
    class WikiPageVersion
      attr_reader :commit, :format

      # This class is meant to be serializable so that it can be constructed
      # by Gitaly and sent over the network to GitLab.
      #
      # Both 'commit' (a Gitlab::Git::Commit) and 'format' (a string) are
      # serializable.
      def initialize(commit, format)
        @commit = commit
        @format = format
      end

      delegate :message, :sha, :id, :author_name, :authored_date, to: :commit
    end
  end
end
