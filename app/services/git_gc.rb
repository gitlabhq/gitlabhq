require 'open4'

class GitGc

  def cleanup
    now = Time.now
    log_file = "#{Rails.root}/log/git_gc.log"
    File.delete(log_file) if File.exist?(log_file)
    @logger = Logger.new(log_file)
    @logger.info("Starting: git gc --auto")
    repos = Dir.glob("#{Gitlab.config.gitlab_shell.repos_path}**/*.git/")
    repos.each do |repo|
      git_gc(repo)
      r = repo.split('/')
      path = r[r.count - 2] + '/' + r.last.gsub(/.git/,'')
      satellite = "#{Gitlab.config.satellites.path}" + '/' + path
      git_gc(satellite) if File.exists?(satellite)
    end
    # Next round
    GitGcWorker.schedule(now + 7 * 24 * 3600 * "#{Gitlab.config.git.gc_interval_in_weeks}".to_i)
  end

  private

  def git_gc(repo)
    t0 = Time.now
    `cd "#{repo}"`
    pid, stdin, stdout, stderr = Open4::popen4("#{Gitlab.config.git.bin_path} gc --auto")
    elapsed = (Time.now - t0).to_i
    res = ''
    stderr.each { |line| res << line }
    if res[0]
      @logger.warn(res)
      @logger.warn("FAILED #{repo} elapsed time: #{elapsed} s")
    else
      @logger.info("OK #{repo} elapsed time: #{elapsed} s")
    end
  end
end
