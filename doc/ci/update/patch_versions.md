# Universal update guide for patch versions. For example from 4.0.0 to 4.0.1, also see the [semantic versioning specification](http://semver.org/).

### 1. Stop CI server

    sudo service gitlab_ci stop

### 2. Switch to your gitlab_ci user

```
sudo su gitlab_ci
cd /home/gitlab_ci/gitlab-ci
```

### 3. Get latest code

```
git pull origin STABLE_BRANCH
```

### 4. Install libs, migrations etc

```
bundle install --without development test --deployment
bundle exec rake db:migrate RAILS_ENV=production
```

### 5. Start web application

    sudo service gitlab_ci start


# One line upgrade command

You have read through the entire guide and probably already did all the steps one by one.

Here is a one line command with all above steps for the next time you upgrade:

```
    sudo service gitlab_ci stop && \
      cd /home/gitlab_ci/gitlab-ci && \
      sudo -u gitlab_ci -H git pull origin `git rev-parse --abbrev-ref HEAD` && \
      sudo -u gitlab_ci -H bundle install --without development test --deployment && \
      sudo -u gitlab_ci -H bundle exec rake db:migrate RAILS_ENV=production && \
      cd && \
      sudo service gitlab_ci start
```

Since when we start this `gitlab_ci` service, the document `db/schema.rb` is shown always as modified for git, you could even do like this, **if and only if**, you are sure you only have that modification:

```
    sudo service gitlab_ci stop && \
      cd /home/gitlab_ci/gitlab-ci && \
      sudo -u gitlab_ci -H git checkout -f `git rev-parse --abbrev-ref HEAD` && \
      sudo -u gitlab_ci -H git pull origin `git rev-parse --abbrev-ref HEAD` && \
      sudo -u gitlab_ci -H bundle install --without development test --deployment && \
      sudo -u gitlab_ci -H bundle exec rake db:migrate RAILS_ENV=production && \
      cd && \
      sudo service gitlab_ci start
```
