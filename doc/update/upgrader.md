# GitLab Upgrader 

GitLab Upgrader - ruby script that allows you easily upgrade GitLab to latest minor version.
Ex. it can update your application from 6.4 to latest GitLab 6 version (like 6.5.1).
You still need to create backup and manually restart GitLab but all other operations can be done by upgrade tool.

__GitLab Upgrader is available only for version 6.4.2 or higher__

### 0. Backup

    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

### 1. Stop server

    sudo service gitlab stop

### 2. Run gitlab upgrade tool

    cd /home/git/gitlab
    sudo -u git -H ruby script/upgrade.rb

    # it also supports -y option to avouid user input
    # sudo -u git -H ruby script/upgrade.rb -y
   

### 3. Start application

    sudo service gitlab start
    sudo service nginx restart
