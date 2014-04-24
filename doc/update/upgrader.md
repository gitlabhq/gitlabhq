# GitLab Upgrader

GitLab Upgrader - a ruby script that allows you easily upgrade GitLab to latest minor version.

For example it can update your application from 6.4 to latest GitLab 6 version (like 6.6.1).

You still need to create a backup and manually restart GitLab after running the script but all other operations are done by this upgrade script.

If you have local changes to your GitLab repository the script will stash them and you need to use `git stash pop` after running the script.

**GitLab Upgrader is available only for GitLab version 6.4.2 or higher.**

## 0. Backup

    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

## 1. Stop server

    sudo service gitlab stop

## 2. Run GitLab upgrade tool

    # Starting with GitLab version 7.0 upgrader script has been moved to bin directory
    cd /home/git/gitlab
    if [ -f bin/upgrade.rb ]; then sudo -u git -H ruby bin/upgrade.rb; else sudo -u git -H ruby script/upgrade.rb; fi

    # to perform a non-interactive install (no user input required) you can add -y
    # if [ -f bin/upgrade.rb ]; then sudo -u git -H ruby bin/upgrade.rb -y; else sudo -u git -H ruby script/upgrade.rb -y; fi

## 3. Start application

    sudo service gitlab start
    sudo service nginx restart

## 4. Check application status

Check if GitLab and its dependencies are configured correctly:

    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations upgrade is complete!

## 5. Upgrade GitLab Shell (if needed)

If the `gitlab:check` task reports an outdated version of `gitlab-shell` you should upgrade it.

Upgrade it by running the commands below after replacing 1.9.4 with the correct version number:

```
cd /home/git/gitlab-shell
sudo -u git -H git fetch
sudo -u git -H git checkout v1.9.4
```

## One line upgrade command

You've read through the entire guide and probably already did all the steps one by one.

Here is a one line command with step 1 to 4 for the next time you upgrade:

```bash
cd /home/git/gitlab; sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production; \
  sudo service gitlab stop; \
  if [ -f bin/upgrade.rb ]; then sudo -u git -H ruby bin/upgrade.rb -y; else sudo -u git -H ruby script/upgrade.rb -y; fi; \
  sudo service gitlab start; \
  sudo service nginx restart; sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```
