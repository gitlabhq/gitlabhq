require 'json'
require 'socket'

class IrkerWorker
  include ApplicationWorker

  def perform(project_id, chans, colors, push_data, settings)
    project = Project.find(project_id)

    # Get config parameters
    return false unless init_perform settings, chans, colors

    repo_name = push_data['repository']['name']
    committer = push_data['user_name']
    branch = push_data['ref'].gsub(%r'refs/[^/]*/', '')

    if @colors
      repo_name = "\x0304#{repo_name}\x0f"
      branch = "\x0305#{branch}\x0f"
    end

    # First messages are for branch creation/deletion
    send_branch_updates push_data, project, repo_name, committer, branch

    # Next messages are for commits
    send_commits push_data, project, repo_name, committer, branch

    close_connection
    true
  end

  private

  def init_perform(set, chans, colors)
    @colors = colors
    @channels = chans
    start_connection set['server_host'], set['server_port']
  end

  def start_connection(irker_server, irker_port)
    begin
      @socket = TCPSocket.new irker_server, irker_port
    rescue Errno::ECONNREFUSED => e
      logger.fatal "Can't connect to Irker daemon: #{e}"
      return false
    end
    true
  end

  def sendtoirker(privmsg)
    to_send = { to: @channels, privmsg: privmsg }
    @socket.puts JSON.dump(to_send)
  end

  def close_connection
    @socket.close
  end

  def send_branch_updates(push_data, project, repo_name, committer, branch)
    if Gitlab::Git.blank_ref?(push_data['before'])
      send_new_branch project, repo_name, committer, branch
    elsif Gitlab::Git.blank_ref?(push_data['after'])
      send_del_branch repo_name, committer, branch
    end
  end

  def send_new_branch(project, repo_name, committer, branch)
    repo_path = project.full_path
    newbranch = "#{Gitlab.config.gitlab.url}/#{repo_path}/branches"
    newbranch = "\x0302\x1f#{newbranch}\x0f" if @colors

    privmsg = "[#{repo_name}] #{committer} has created a new branch "
    privmsg += "#{branch}: #{newbranch}"
    sendtoirker privmsg
  end

  def send_del_branch(repo_name, committer, branch)
    privmsg = "[#{repo_name}] #{committer} has deleted the branch #{branch}"
    sendtoirker privmsg
  end

  def send_commits(push_data, project, repo_name, committer, branch)
    return if push_data['total_commits_count'] == 0

    # Next message is for number of commit pushed, if any
    if Gitlab::Git.blank_ref?(push_data['before'])
      # Tweak on push_data["before"] in order to have a nice compare URL
      push_data['before'] = before_on_new_branch push_data, project
    end

    send_commits_count(push_data, project, repo_name, committer, branch)

    # One message per commit, limited by 3 messages (same limit as the
    # github irc hook)
    commits = push_data['commits'].first(3)
    commits.each do |hook_attrs|
      send_one_commit project, hook_attrs, repo_name, branch
    end
  end

  def before_on_new_branch(push_data, project)
    commit = commit_from_id project, push_data['commits'][0]['id']
    parents = commit.parents
    # Return old value if there's no new one
    return push_data['before'] if parents.empty?

    # Or return the first parent-commit
    parents[0].id
  end

  def send_commits_count(data, project, repo, committer, branch)
    url = compare_url data, project.full_path
    commits = colorize_commits data['total_commits_count']

    new_commits = 'new commit'
    new_commits += 's' if data['total_commits_count'] > 1

    sendtoirker "[#{repo}] #{committer} pushed #{commits} #{new_commits} " \
                "to #{branch}: #{url}"
  end

  def compare_url(data, repo_path)
    sha1 = Commit.truncate_sha(data['before'])
    sha2 = Commit.truncate_sha(data['after'])
    compare_url = "#{Gitlab.config.gitlab.url}/#{repo_path}/compare"
    compare_url += "/#{sha1}...#{sha2}"
    colorize_url compare_url
  end

  def send_one_commit(project, hook_attrs, repo_name, branch)
    commit = commit_from_id project, hook_attrs['id']
    sha = colorize_sha Commit.truncate_sha(hook_attrs['id'])
    author = hook_attrs['author']['name']
    files = colorize_nb_files(files_count commit)
    title = commit.title

    sendtoirker "#{repo_name}/#{branch} #{sha} #{author} (#{files}): #{title}"
  end

  def commit_from_id(project, id)
    project.commit(id)
  end

  def files_count(commit)
    diff_size = commit.raw_deltas.size

    files = "#{diff_size} file"
    files += 's' if diff_size > 1
    files
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
