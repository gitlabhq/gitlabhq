# frozen_string_literal: true

require 'json'
require 'socket'
require 'resolv'

module Integrations
  class IrkerWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky
    sidekiq_options retry: 3
    feature_category :integrations
    urgency :low

    def perform(project_id, channels, colors, push_data, settings)
      # Establish connection to irker server
      return false unless start_connection(
        settings['server_host'],
        settings['server_port']
      )

      @project = Project.find(project_id)
      @colors = colors
      @channels = channels

      @repo_path = @project.full_path
      @repo_name = push_data['repository']['name']
      @committer = push_data['user_name']
      @branch = push_data['ref'].gsub(%r{refs/[^/]*/}, '')

      if @colors
        @repo_name = "\x0304#{@repo_name}\x0f"
        @branch = "\x0305#{@branch}\x0f"
      end

      # First messages are for branch creation/deletion
      send_branch_updates(push_data)

      # Next messages are for commits
      send_commits(push_data)

      close_connection
      true
    end

    private

    def start_connection(irker_server, irker_port)
      ip_address = Resolv.getaddress(irker_server)
      # handle IP6 addresses
      domain = Resolv::IPv6::Regex.match?(ip_address) ? "[#{ip_address}]" : ip_address

      begin
        Gitlab::HTTP_V2::UrlBlocker.validate!(
          "irc://#{domain}",
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          schemes: ['irc'],
          deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
          outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting
        @socket = TCPSocket.new ip_address, irker_port
      rescue Errno::ECONNREFUSED, Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
        logger.fatal "Can't connect to Irker daemon: #{e}"
        return false
      end

      true
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def send_to_irker(privmsg)
      to_send = { to: @channels, privmsg: privmsg }

      @socket.puts Gitlab::Json.dump(to_send)
    end

    def close_connection
      @socket.close
    end

    def send_branch_updates(push_data)
      message =
        if Gitlab::Git.blank_ref?(push_data['before'])
          new_branch_message
        elsif Gitlab::Git.blank_ref?(push_data['after'])
          delete_branch_message
        end

      send_to_irker(message)
    end

    def new_branch_message
      newbranch = "#{Gitlab.config.gitlab.url}/#{@repo_path}/-/branches"
      newbranch = "\x0302\x1f#{newbranch}\x0f" if @colors

      "[#{@repo_name}] #{@committer} has created a new branch #{@branch}: #{newbranch}"
    end

    def delete_branch_message
      "[#{@repo_name}] #{@committer} has deleted the branch #{@branch}"
    end

    def send_commits(push_data)
      return if push_data['total_commits_count'] == 0

      # Next message is for number of commit pushed, if any
      if Gitlab::Git.blank_ref?(push_data['before'])
        # Tweak on push_data["before"] in order to have a nice compare URL
        push_data['before'] = before_on_new_branch(push_data)
      end

      send_commits_count(push_data)

      # One message per commit, limited by 3 messages (same limit as the
      # github irc hook)
      commits = push_data['commits'].first(3)
      commits.each do |commit_attrs|
        send_one_commit(commit_attrs)
      end
    end

    def before_on_new_branch(push_data)
      commit = commit_from_id(push_data['commits'][0]['id'])
      parents = commit.parents

      # Return old value if there's no new one
      return push_data['before'] if parents.empty?

      # Or return the first parent-commit
      parents[0].id
    end

    def send_commits_count(push_data)
      url = compare_url(push_data['before'], push_data['after'])
      commits = colorize_commits(push_data['total_commits_count'])
      new_commits = 'new commit'.pluralize(push_data['total_commits_count'])

      send_to_irker("[#{@repo_name}] #{@committer} pushed #{commits} #{new_commits} " \
                    "to #{@branch}: #{url}")
    end

    def compare_url(sha_before, sha_after)
      sha1 = Commit.truncate_sha(sha_before)
      sha2 = Commit.truncate_sha(sha_after)
      compare_url = "#{Gitlab.config.gitlab.url}/#{@repo_path}/-/compare" \
                    "/#{sha1}...#{sha2}"

      colorize_url(compare_url)
    end

    def send_one_commit(commit_attrs)
      commit = commit_from_id(commit_attrs['id'])
      sha = colorize_sha(Commit.truncate_sha(commit_attrs['id']))
      author = commit_attrs['author']['name']
      files = colorize_nb_files(files_count(commit))
      title = commit.title

      send_to_irker("#{@repo_name}/#{@branch} #{sha} #{author} (#{files}): #{title}")
    end

    def commit_from_id(id)
      @project.commit(id)
    end

    def files_count(commit)
      diff_size = commit.raw_deltas.size

      "#{diff_size} file".pluralize(diff_size)
    end

    def colorize_sha(sha)
      sha = "\x0314#{sha}\x0f" if @colors
      sha
    end

    def colorize_nb_files(nb_files)
      nb_files = "\x0312#{nb_files}\x0f" if @colors
      nb_files
    end

    def colorize_url(url)
      url = "\x0302\x1f#{url}\x0f" if @colors
      url
    end

    def colorize_commits(commits)
      commits = "\x02#{commits}\x0f" if @colors
      commits
    end
  end
end
