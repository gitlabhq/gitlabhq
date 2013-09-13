# From Community edition 6.0 to Enterprise edition 6.0


### 0. Backup

Make a backup just in case things go south:
(With MySQL, this may require granting "LOCK TABLES" privileges to the GitLab user on the database version)

```bash
cd /home/git/gitlab
sudo -u git -H RAILS_ENV=production bundle exec rake gitlab:backup:create
```

### 1. Stop server

    sudo service gitlab stop

### 2. Get the EE code

```bash
cd /home/git/gitlab
sudo -u git -H git remote set-url origin https://gitlab.com/subscribers/gitlab-ee.git
sudo -u git -H git fetch --all
sudo -u git -H git checkout -t -b v6.0.0-ee
```

### 3. Run bundle

```bash
cd /home/git/gitlab
bundle install
```

### 4. Update config files

* Make `/home/git/gitlab/config/gitlab.yml` same as /home/git/gitlab/config/gitlab.yml.example but with your settings.
Note: Under LDAP settings fill in `group_base` setting.
* Make `/home/git/gitlab/config/unicorn.rb` same as /home/git/gitlab/config/unicorn.rb.example but with your settings.

### 5. Install libs, migrations, etc.

```bash
cd /home/git/gitlab

# MySQL
sudo -u git -H bundle install --without development test postgres --deployment

#PostgreSQL
sudo -u git -H bundle install --without development test mysql --deployment

sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
```

### 6. Update Init script

```bash
sudo rm /etc/init.d/gitlab
sudo curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlabhq/6-0-stable/lib/support/init.d/gitlab
sudo chmod +x /etc/init.d/gitlab
```

### 7. Start application

    sudo service gitlab start
    sudo service nginx restart

### 8. Check application status

Check if GitLab and its environment are configured correctly:

    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

To make sure you didn't miss anything run a more thorough check with:

    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations upgrade complete!

## Things went wrong? Revert to previous version (6.0)

### 1. Revert the code to the previous version
Follow the [`upgrade guide from 5.4 to 6.0`](5.4-to-6.0.md), except for the database migration 
(The backup is already migrated to the previous version)

### 2. Restore from the backup:

```bash
cd /home/git/gitlab
sudo -u git -H RAILS_ENV=production bundle exec rake gitlab:backup:restore
```
