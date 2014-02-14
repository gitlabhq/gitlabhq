# GitLab Upgrader 

GitLab Upgrader - a ruby script that allows you easily upgrade GitLab to latest minor version.
For example it can update your application from 6.4 to latest GitLab 6 version (like 6.6.1).
You still need to create a a backup and manually restart GitLab after runnning the script but all other operations are done by this upgrade script.
If you have local changes to your GitLab repository the script will stash them and you need to use `git stash pop` after running the script.

__GitLab Upgrader is available only for GitLab version 6.4.2 or higher__

### 0. Backup

    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

### 1. Stop server

    sudo service gitlab stop

### 2. Run gitlab upgrade tool

    cd /home/git/gitlab
    sudo -u git -H ruby script/upgrade.rb

    # to perform a non-interactive install (no user input required) you can add -y
    # sudo -u git -H ruby script/upgrade.rb -y

### 3. Start application

    sudo service gitlab start
    sudo service nginx restart

### 4. Check application status

Check if GitLab and its environment are configured correctly:

    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
    
To make sure you didn't miss anything run a more thorough check with:

    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
    
If all items are green, then congratulations upgrade is complete!
