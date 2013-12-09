# Universal update guide for patch versions. For example from 6.2.0 to 6.2.1, also see the [semantic versioning specification](http://semver.org/).

### 0. Backup

It's useful to make a backup just in case things go south:
(With MySQL, this may require granting "LOCK TABLES" privileges to the GitLab user on the database version)

```bash
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### 1. Stop server

    sudo service gitlab stop

### 2. Get latest code for the stable branch

```bash
cd /home/git/gitlab
sudo -u git -H git pull origin STABLE_BRANCH
```

Replace STABLE_BRANCH with the minor version you want to upgrade to, for example `6-3-stable`.

### 3. Update gitlab-shell if it is not the latest version

```bash
cd /home/git/gitlab-shell
sudo -u git -H git fetch
sudo -u git -H git checkout LATEST_TAG
```

Replace LATEST_TAG with the latest GitLab Shell tag you want to upgrade to, for example `v1.7.9`.

### 4. Install libs, migrations, etc.

```bash
cd /home/git/gitlab

# MySQL
sudo -u git -H bundle install --without development test postgres --deployment

#PostgreSQL
sudo -u git -H bundle install --without development test mysql --deployment

sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
sudo -u git -H bundle exec rake assets:clean RAILS_ENV=production
sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

### 5. Start application

    sudo service gitlab start
    sudo service nginx restart

### 6. Check application status

Check if GitLab and its environment are configured correctly:

    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

To make sure you didn't miss anything run a more thorough check with:

    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations upgrade complete!
