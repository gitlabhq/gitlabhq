require 'json'
require 'socket'

# Note: extra configuration possible, in config/gitlab.yml :
# production:
#   irker:
#     server_ip: localhost
#     server_port: 6659
#     max_channels: 3
#     # Next one has no default, this is just an example
#     default_irc_uri: irc://chat.freenode.net/
# You can place the 'irker' section just below the already-there 'extra' section

class IrkerWorker
  include Sidekiq::Worker

  def perform(project_id, chans, colors, push_data)
    project             = Project.find(project_id)

    # Get config parameters
    begin
      irker_server = Gitlab.config.irker.server_ip
      irker_port   = Gitlab.config.irker.server_port
    rescue Settingslogic::MissingSetting
      irker_server = 'localhost'
      irker_port   = 6659
    end

    logger.info "IrkerWorker: messages destination = #{chans}"
    return false unless setup_members chans, irker_server, irker_port

    repo_name = push_data['repository']['name']
    committer = push_data['user_name']
    branch    = push_data['ref'].gsub(%r'refs/[^/]*/', '')

    if colors
      repo_name = "\x0304#{repo_name}\x0f"
      branch    = "\x0305#{branch}\x0f"
    end

    # Firsts messages are for branch creation/deletion
    if push_data['before'] =~ /^000000/
      send_new_branch project.path_with_namespace, repo_name, committer, branch
    elsif push_data['after'] =~ /^000000/
      send_del_branch repo_name, committer, branch
    end

    if push_data['total_commits_count'] != 0
      send_commits push_data, project, repo_name, committer, branch, colors
    end

    @socket.close
    true
  ensure
    GC.start
  end

  def sendtoirker(privmsg)
    to_send = { to: @channels, privmsg: privmsg }
    @socket.puts JSON.dump(to_send)
  end

  def setup_members(channels, irker_server, irker_port)
    @channels = channels
    begin
      @socket = TCPSocket.new irker_server, irker_port
    rescue Errno::ECONNREFUSED => e
      logger.fatal "Can't connect to Irker daemon: #{e}"
      return false
    end
    true
  end

  def send_new_branch(repo_path, repo_name, committer, branch)
    newbranch = "#{Gitlab.config.gitlab.url}/#{repo_path}/branches"
    if colors
      newbranch = "\x0302\x1f#{newbranch}\x0f"
    end

    privmsg  = "[#{repo_name}] #{committer} has created a new branch "
    privmsg += "#{branch}: #{newbranch}"
    sendtoirker privmsg
  end

  def send_del_branch(repo_name, committer, branch)
    privmsg = "[#{repo_name}] #{committer} has deleted the branch #{branch}"
    sendtoirker privmsg
  end

  def send_commits(push_data, project, repo_name, committer, branch, colors)
    # Next message is for number of commit pushed, if any
    if push_data['before'] =~ /^000000/
      # Tweak on push_data["before"] in order to have a nice compare URL
      commit_id = push_data['commits'][0]['id']
      commit = Gitlab::Git::Commit.find(project.repository, commit_id)
      commit = Commit.new(commit)
      parents = commit.parents
      push_data['before'] = parents[0].id unless parents.empty?
    end

    send_commits_count(push_data, project, repo_name, committer,
                       branch, colors)

    # Finally, one message per commit, limited by 3 messages (same limit as the
    # github irc hook)
    commits = push_data['commits'].first(3)
    commits.each do |hook_attrs|
      send_one_commit project, hook_attrs, repo_name, branch, colors
    end
  end

  def send_commits_count(data, project, repo_name, committer, branch, colors)
    repo_path     = project.path_with_namespace
    sha1          = Commit::truncate_sha(data['before'])
    sha2          = Commit::truncate_sha(data['after'])
    compare_url   = "#{Gitlab.config.gitlab.url}/#{repo_path}/compare"
    compare_url  += "/#{sha1}...#{sha2}"
    compare_url   = "\x0302\x1f#{compare_url}\x0f" if colors
    commits_count = data['total_commits_count']
    commits_count = "\x02#{commits_count}\x0f" if colors

    new_commits   = 'new commit'
    new_commits  += 's' if data['total_commits_count'] > 1

    privmsg       = "[#{repo_name}] #{committer} pushed #{commits_count} "
    privmsg      += "#{new_commits} to #{branch}: #{compare_url}"
    sendtoirker privmsg
  end

  def send_one_commit(project, hook_attrs, repo_name, branch, colors)
    commit = Gitlab::Git::Commit.find(project.repository, hook_attrs['id'])
    commit = Commit.new(commit)
    sha    = Commit::truncate_sha(hook_attrs['id'])
    author = hook_attrs['author']['name']
    files  = "#{commit.diffs.count} file"
    files += 's' if commit.diffs.count > 1
    title  = commit.title

    if colors
      sha = "\x0314#{sha}\x0f"
      files = "\x0312#{files}\x0f"
    end

    privmsg = "#{repo_name}/#{branch} #{sha} #{author} (#{files}): #{title}"
    sendtoirker privmsg
  end
end
