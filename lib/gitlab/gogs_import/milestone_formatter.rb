module Gitlab
  module GogsImport
    class MilestoneFormatter < GithubImport::MilestoneFormatter
      def self.iid_attr
        :id
      end
    end
  end
end
