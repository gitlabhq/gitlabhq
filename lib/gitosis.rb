require 'lockfile'
require 'inifile'
require 'net/ssh'

class Gitosis

  def pull
    # create tmp dir
    @local_dir = File.join(Dir.tmpdir,"gitme-gitosis-#{Time.now.to_i}")

    Dir.mkdir @local_dir

    # clone repo
    `git clone #{GITOSIS['admin_uri']} #{@local_dir}/gitosis`
  end

  def push
    # add, commit, push, and remove local tmp dir
    `cd #{File.join(@local_dir,'gitosis')} ; git add keydir/* gitosis.conf`
    `cd #{File.join(@local_dir,'gitosis')} ; git commit -a -m 'updated by Gitlab Gitosis'`
    `cd #{File.join(@local_dir,'gitosis')} ; git push`

    # remove local copy
    `rm -Rf #{@local_dir}`
  end

  def configure
    File.open(File.join(Dir.tmpdir,"gitme-gitosis.lock"), "w+") do |f|
      f.flock(File::LOCK_EX)
      
      pull
      yield(self)
      push
      
      f.flock(File::LOCK_UN)
    end
  end

  def destroy_project(project)
    `rm -Rf #{project.path_to_repo}`
    
    conf = IniFile.new(File.join(@local_dir,'gitosis','gitosis.conf'))

    conf.delete_section("group #{project.path}")

    conf.write
  end

   #update or create
  def update_keys(user, key)
    File.open(File.join(@local_dir, 'gitosis/keydir',"#{user}.pub"), 'w') {|f| f.write(key.gsub(/\n/,'')) }
  end

  def delete_key(user)
    File.unlink(File.join(@local_dir, 'gitosis/keydir',"#{user}.pub"))
    `cd #{File.join(@local_dir,'gitosis')} ; git rm keydir/#{user}.pub`
  end

   #update or create
  def update_project(repo_name, name_writers)
    # write config file
    conf = IniFile.new(File.join(@local_dir,'gitosis','gitosis.conf'))

    conf["group #{repo_name}"]['writable'] = repo_name
    conf["group #{repo_name}"]['members'] = name_writers.join(' ')

    conf.write
  end

end
