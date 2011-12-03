require 'gitolite'

require 'inifile'
require 'timeout'
require 'fileutils'

class Gitosis
  class AccessDenied < StandardError; end

  def pull
    # create tmp dir
    @local_dir = File.join(Dir.tmpdir,"gitlabhq-gitolite-#{Time.now.to_i}")

    Dir.mkdir @local_dir

    `git clone #{GITOSIS['admin_uri']} #{@local_dir}/gitolite`
  end

  def push
    Dir.chdir(File.join(@local_dir, "gitolite"))
    `git add -A`
    `git commit -am "Gitlab"`
    `git push`
    Dir.chdir(Rails.root)

    FileUtils.rm_rf(@local_dir)
  end

  def configure
    status = Timeout::timeout(20) do
      File.open(File.join(Dir.tmpdir,"gitlabhq-gitolite.lock"), "w+") do |f|
        begin 
          f.flock(File::LOCK_EX)
          pull
          yield(self)
          push
        ensure
          f.flock(File::LOCK_UN)
        end
      end
    end
  #rescue Exception => ex
    #raise Gitosis::AccessDenied.new("gitolite timeout")
  end

  def destroy_project(project)
    `sudo -u git rm -rf #{project.path_to_repo}`
    
    conf = IniFile.new(File.join(@local_dir,'gitolite', 'conf', 'gitolite.conf'))

    conf.delete_section("group #{project.path}")

    conf.write
  end

   #update or create
  def update_keys(user, key)
    File.open(File.join(@local_dir, 'gitolite/keydir',"#{user}.pub"), 'w') {|f| f.write(key.gsub(/\n/,'')) }
  end

  def delete_key(user)
    File.unlink(File.join(@local_dir, 'gitolite/keydir',"#{user}.pub"))
    `cd #{File.join(@local_dir,'gitolite')} ; git rm keydir/#{user}.pub`
  end

  #update or create
  def update_project(repo_name, name_writers)
    ga_repo = Gitolite::GitoliteAdmin.new(File.join(@local_dir,'gitolite'))
    conf = ga_repo.config

    repo = if conf.has_repo?(repo_name)
             conf.get_repo(repo_name)
           else 
             Gitolite::Config::Repo.new(repo_name)
           end

    repo.add_permission("RW+", "", name_writers) unless name_writers.blank?

    conf.add_repo(repo)

    ga_repo.save
  end
end
