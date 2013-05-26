# Trouble Shooting Guide

## Purpose
This guide should help locate and resolve issues you might have with Gitlab.
If you don't know where to start you should begin with the *General* section below.

### Help refining this guide
Any help is welcome.

1. You have encountered a problem that is not mentioned here?
1. Visit our [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq)
1. Add the problem description and the solution to this Wiki.


## Sections

### General
GitLab can help you checking if it was set up properly and locating potential sources of problems.
The easiest way is by running the self diagnosis command (note that you must be in the gitlab directory when the command is run):
```sh
## for GitLab 3.1 and earlier
sudo -u gitlab -H bundle exec rake gitlab:app:status RAILS_ENV=production

## for GitLab 4.0 and later (uses gitlab user)
sudo -u gitlab -H bundle exec rake gitlab:check RAILS_ENV=production

## for GitLab 5.0 and later (uses git user)
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If you are **all green** you should have eliminated most of the obvious error sources.
You should also check the sections below for your issue and follow the steps to fix it.

If you still need help visit our [Support Forum](https://groups.google.com/forum/#!forum/gitlabhq) or consult the [installation guide](https://github.com/gitlabhq/gitlabhq/blob/stable/doc/install/installation.md).

### SSH

**Error:** `git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin` failing <br/>
**Problem:** running SSH on an non-standard port (i.e. not 22) <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1063#issuecomment-6854410
**Solution #2:** If you have run the gitolite setup command several times, or made some manual edits while creating the SSH keys, the "authorized_keys" files under /home/git/.ssh/ may need to be modified. Ensure that only one entry exists for the gitlab key, and that the entry is restricted to running the gitolite-shell command (e.g. command="/home/git/gitolite/src/gitolite-shell gitlab",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty)

### Gitlab Shell

**Error:**

```
$ git push origin master
/usr/local/lib/ruby/1.9.1/net/http.rb:762:in initialize': getaddrinfo: Name or service not known (SocketError)
```

**Problem:** `/home/git/gitlab-shell/config.yml` has wrong gitlab_url. Make sure it has `/` at the end of url<br />
**Solution:** Fix gitlab_url

---

**Error:**

```
$ git push origin master
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
$ ssh git@your_server_here
Server refused to allocate pty
/home/git/gitlab-shell/bin/gitlab-shell:8: undefined method 'require_relative' for main:Object (NoMethodError)
```

**Problem:** You are using system-wide RVM. <br />
**Solution:** Run the following as a user who has RVM set up correctly.:
```
env | grep -E "^(GEM_HOME|PATH|RUBY_VERSION|MY_RUBY_HOME|GEM_PATH)=" > /var/tmp/tempenv
sudo -u git -H cp /var/tmp/tempenv /home/git/.ssh/environment
echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
```

### Gitolite

**Note:** *Gitolite has been replaced by GitLab Shell in 5.0 .*

**Error:** `/home/git/.gitolite/hooks/common/post-receive exists? ............NO` <br />
**Problem:** `/home/git/.gitolite` has wrong permissions <br />
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1766#issuecomment-9760429

---

**Error:** `remote: FATAL: git config 'core.sharedRepository' not allowed` when pushing <br/>
**Error:** `error: insufficient permission for adding an object to repository database ./objects` after pushing over HTTP <br/>
**Error:** adding/removing projects and SSH keys fail <br/>
**Problem:** Gitolite is not configured properly, so file permissions are not set correctly.<br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/pull/1719

### MySQL

**Error:** `Mysql2::Error: Specified key was too long; max key length is 1000 bytes` <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/2412

**Error:** `Mysql2::Error: Got a packet bigger than 'max_allowed_packet' bytes: UPDATE `merge_requests` SET `st_diffs` = ...` <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1728

### PostgreSQL

**Error:** `ERROR:  operator does not exist: character varying = integer at character 59` <br/>
**Error:** `ActionView::Template::Error (PG::Error: ERROR:  operator does not exist: character varying = integer ...` <br/>
**Problem:** comparting integer values (in queries) to a text column (`notes.noteable_id`)<br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1957#issuecomment-10213437 <br/>
**Note:** this has been fixed since GitLab 4.0

### Sidekiq

**Error:** 'ERROR: Error fetching message: ERR unknown command 'brpop'`<br/>
**Error:** Notification emails are not sent and recently pushed commits aren't showing up in the home feed <br/>
**Problem:** brpop is only available since redis-server version 2.0.0 which is not shipped with Debian Squeeze and Ubuntu 10.04 LTS for example.<br/>
**Solution:** Install new redis-server via backports, see → https://github.com/gitlabhq/gitlabhq/issues/2675#issuecomment-12504306
#### On Debian Squeeze:
    echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> /etc/apt/sources.list
    apt-get update
    apt-get -t squeeze-backports install redis-server

#### On Ubuntu 10.04 LTS:
    sudo add-apt-repository ppa:rwky/redis
    sudo apt-get update
    sudo apt-get upgrade

If the "add-apt-repository" command is not found install it using:<br/>
    `sudo apt-get install python-software-properties`

Be sure to `stop` / `kill` all existing redis-server processes after installing the new redis-server (check via `ps -C redis-server`), restart afterwards.<br/>

---

**Error:** The following error is reported by Resque/Sidekiq when from a post receive push, if you have symlinked your `/home/git/repositories` directory.

    undefined method `id' for nil:NilClass

    /home/gitlab/gitlab/app/models/project.rb:104:in `find_with_namespace'
    /home/gitlab/gitlab/app/workers/post_receive.rb:9:in `perform'

**Problem:** A symlink as the `repositories` directory is currently not supported
**Solution:** Update config `gitolite.repos_path` to point to the actual directory (as opposed to symlink). See [#2456](https://github.com/gitlabhq/gitlabhq/issues/2456). You will need to restart both GitLab and Resque/Sidekiq for the new path to be picked up.

### Resque

**Note:** *Resque has been replaced by Sidekiq in 4.1 .*

**Error:** Notification emails are not sent <br/>
**Error:** Project Activity page is always blank (as seen in [#918](https://github.com/gitlabhq/gitlabhq/issues/918)) <br/>
**Error:** System Hooks not firing (as seen in [#1205](https://github.com/gitlabhq/gitlabhq/issues/1205)) <br/>
**Problem:** Resque is not running or the PID file has wrong file permissions/ownership <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1068#issuecomment-6904135

### GitLab

**Error:** `TypeError (can't dump anonymous class Class)` <br/>
**Problem:** wrong Ruby version (i.e. < 1.9.3) or your interpreter was not compiled with YAML support<br/>
**Solution:** update your Ruby interpreter (or recompile making sure that it links with libyaml correctly)

---

**Error:** `Missing setting 'web' in /home/gitlabhq/gitlabhq/config/gitlab.yml (Settingslogic::MissingSetting)` <br/>
**Problem:** your configuration file needs to be updated <br/>
**Solution:** see [config/gitlab.yml.example](https://github.com/gitlabhq/gitlabhq/blob/master/config/gitlab.yml.example) for how an up-to-date config file looks

---

**Error:** `no such file to load -- rb-inotify` when running rake (as seen in [#1752](https://github.com/gitlabhq/gitlabhq/issues/1752))<br/>
**Problem:** task run in wrong environment<br/>
**Solution:** add `RAILS_ENV=production` to the end of the command

---

**Error:** `no such file to load -- rb-inotify` when running `rake -T RAILS_ENV=production`<br/>
**Problem:** `RAILS_ENV` is not set during collection of tasks, but apparently needs to be<br/>
**Solution:** add `RAILS_ENV=production` to the *beginning* of the command: `RAILS_ENV=production bundle exec rake -T` (see this [comment](https://github.com/gitlabhq/gitlabhq/pull/2502#issuecomment-11954700) by [randx](https://github.com/randx))

---

**Error:** `RuntimeError: Satellite doesn't exist` <br/>
**Problem:** satellite repos don't exists <br/>
**Solution:** Run the following command:

```sh
## for GitLab 3.1 and earlier
sudo -u gitlab -H bundle exec rake gitlab:app:enable_automerge RAILS_ENV=production

## for GitLab 4.0 and later (uses gitlab user)
sudo -u gitlab -H bundle exec rake gitlab:satellites:create RAILS_ENV=production

## for GitLab 5.0 and later (uses git user)
sudo -u git -H bundle exec rake gitlab:satellites:create RAILS_ENV=production
```

You may also need to remove the `tmp/repo_satellites` directory and rerun the rake task.

---

**Error:** Merge requests stuck at `Checking for ability to automatically merge` <br/>
**Problem:** automatic merges are not enabled <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1104#issuecomment-7056318

---

**Error:** `--broken encoding: unknown` in views <br />
**Error:** `ActionView::Template::Error (could not find any magic files!)` <br/>
**Problem:** CharlockHolmes was not installed correctly <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/679#issuecomment-5282141 (please note that the required version for CharlockHolmes as of GitLab 3.1 is **0.6.9**)

---

**Error:** `.../gems/charlock_holmes-0.6.8/ext/charlock_holmes/charlock_holmes.so: undefined symbol: ucsdet_open_46` <br/>
**Problem:** your ICU library is outdated <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1587#issuecomment-8999065. Also see https://github.com/gitlabhq/gitlabhq/issues/679#issuecomment-5282141 for reinstalling CharlockHolmes.

---

**Error:** `ActionView::Template::Error (Failed to get header.)` when navigating to a directory with a README or a showing a file <br/>
**Error:** `ActionView::Template::Error (EPIPE)` in `app/models/tree.rb:5:in 'colorize'` <br/>
**Problem:** GitLab can't find Python <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/2214#issuecomment-11137058

---

**Error:** `Forbidden` when accessing Resque admin page <br/>
**Problem:** incorrect proxy settings in Nginx <br/>
**Solution:** described in https://github.com/gitlabhq/gitlabhq/issues/1158#issuecomment-7390383

---

**Error:** commits pushed to Gitlab not showing (as seen in [#365](https://github.com/gitlabhq/gitlabhq/issues/365))<br/>
**Problem:** gitlab user and group not setup properly <br/>
**Solution:** follow the appropriate steps in the [Installation Guide](https://github.com/gitlabhq/gitlabhq/blob/master/doc/installation.md#3-install-gitolite).
It may also be that the git directory containing the repo's does not have proper permissions.  If not, "chmod g+rx" it.

---

**Error:** `rake aborted! cannot load such file -- omniauth/google/oauth2` <br/>
**Solution:** Open the Gemfile and find the line:

    gem 'omniauth-google-oauth2'

replace it with:

    gem 'omniauth-google-oauth2', :require => "omniauth-google-oauth2"

Save it  and run `rake` again.

---

**Error:** `rake aborted! cannot load such file -- openssl`  (or similar) <br/>
**Problem:** Ruby is not properly compiled with OpenSSL support <br/>
**Solution:** Solutions explored in http://www.ruby-forum.com/topic/90083

---

**Error:** Page not found (404) on project page <br/>
**Problem:** Namespaces not properly migrated. <br/>
**Solution:** Open your MysqlDB console and execute following statement:

    UPDATE projects SET namespace_id = NULL WHERE namespace_id IS NOT NULL AND namespace_id NOT IN (SELECT namespaces.id FROM namespaces);

That should fix projects with non-existing namespaces.

---

**Error:** `R any gitolite-admin admin_local_host_XXXXXXXX DENIED by fallthru` <br/>
**Problem:** Admin user and Gitlab user have same SSH public keys. <br/>
**Solution:** Remove SSH key from admin user or generate new ssh keys for gitlab user and repeat migration to new version (`rm /home/gitlab/.ssh/id_rsa*` and `sudo -u gitlab -H ssh-keygen`).

---

**Error:** link_to helper failed with routing error after upgrade to GitLab 5 <br/>
**Problem:** Some users have no `username` field filled. <br/>
**Solution:** Fill `username` field.

Typical way:

```bash
RAILS_ENV=production bundle exec rails console
```

```ruby
User.where(:username => nil).each { |u| u.username = u.email.sub(/@.+/, ''); u.save! }
```

---

**Error:** File browsing does not show the last commit of file. <br />
**Error:** File browsing is not working at all. <br />
**Error:** "Loading commit data..." never end (looping forever).  <br />
**Problem:** Gitlab needs the option `follow` of the `git-lab` command which is not available in older versions of git. <br />
**Solution:** Update git for at least 1.7.10.4. <br />
