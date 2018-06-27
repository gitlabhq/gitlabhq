require "flowdock-git-hook"

# Flow dock depends on Grit to compute the number of commits between two given
# commits. To make this depend on Gitaly, a monkey patch is applied
module Flowdock
  class Git
    # pass down a Repository all the way down
    def repo
      @options[:repo]
    end

    def config
      {}
    end

    def messages
      Git::Builder.new(repo: repo,
                       ref: @ref,
                       before: @from,
                       after: @to,
                       commit_url: @commit_url,
                       branch_url: @branch_url,
                       diff_url: @diff_url,
                       repo_url: @repo_url,
                       repo_name: @repo_name,
                       permanent_refs: @permanent_refs,
                       tags: tags
                      ).to_hashes
    end

    class Builder
      def commits
        @repo.commits_between(@before, @after).map do |commit|
          {
            url: @opts[:commit_url] ? @opts[:commit_url] % [commit.sha] : nil,
            id: commit.sha,
            message: commit.message,
            author: {
              name: commit.author_name,
              email: commit.author_email
            }
          }
        end
      end
    end
  end
end

class FlowdockService < Service
  prop_accessor :token
  validates :token, presence: true, if: :activated?

  def title
    'Flowdock'
  end

  def description
    'Flowdock is a collaboration web app for technical teams.'
  end

  def self.to_param
    'flowdock'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: 'Flowdock Git source token', required: true }
    ]
  end

  def self.supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    Flowdock::Git.post(
      data[:ref],
      data[:before],
      data[:after],
      token: token,
      repo: project.repository,
      repo_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}",
      commit_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/%s",
      diff_url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/compare/%s...%s"
    )
  end
end
