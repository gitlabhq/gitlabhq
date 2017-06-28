module Gitlab
  module Git
    class Branch < Ref
      def initialize(repository, name, target)
        if target.is_a?(Gitaly::FindLocalBranchResponse)
          target = target_from_gitaly_local_branches_response(target)
        end

        super(repository, name, target)
      end

      def target_from_gitaly_local_branches_response(response)
        # Git messages have no encoding enforcements. However, in the UI we only
        # handle UTF-8, so basically we cross our fingers that the message force
        # encoded to UTF-8 is readable.
        message = response.commit_subject.dup.force_encoding('UTF-8')

        # NOTE: For ease of parsing in Gitaly, we have only the subject of
        # the commit and not the full message. This is ok, since all the
        # code that uses `local_branches` only cares at most about the
        # commit message.
        # TODO: Once gitaly "takes over" Rugged consider separating the
        # subject from the message to make it clearer when there's one
        # available but not the other.
        hash = {
          id: response.commit_id,
          message: message,
          authored_date: Time.at(response.commit_author.date.seconds),
          author_name: response.commit_author.name,
          author_email: response.commit_author.email,
          committed_date: Time.at(response.commit_committer.date.seconds),
          committer_name: response.commit_committer.name,
          committer_email: response.commit_committer.email
        }

        Gitlab::Git::Commit.decorate(hash)
      end
    end
  end
end
