## Migrate GitLab CI to GitLab CE/EE

## Notice

**You need to have working GitLab CI 7.14 to perform migration.
The older versions are not supported and will most likely break migration procedure.**

This migration can't be done online and takes significant amount of time.
Make sure to plan it ahead.

If you are running older version please follow the upgrade guide first:
https://gitlab.com/gitlab-org/gitlab-ci/blob/master/doc/update/7.13-to-7.14.md

The migration is divided into a two parts:
1. **[CI]** You will be making a changes to GitLab CI instance.
1. **[CE]** You will be making a changes to GitLab CE/EE instance.

### 1. Stop CI server [CI]

    sudo service gitlab_ci stop
    
### 2. Backup [CI]

**The migration procedure is database breaking.
You need to create backup if you still want to access GitLab CI in case of failure.**

```bash
cd /home/gitlab_ci/gitlab-ci
sudo -u gitlab_ci -H bundle exec backup:create RAILS_ENV=production
```

### 3. Prepare GitLab CI database to migration [CI]
    
Copy and paste the command in terminal to rename all tables.
This also breaks your database structure disallowing you to use it anymore.

    cat <<EOF | bundle exec rails dbconsole production
    ALTER TABLE application_settings RENAME TO ci_application_settings;
    ALTER TABLE builds RENAME TO ci_builds;
    ALTER TABLE commits RENAME TO ci_commits;
    ALTER TABLE events RENAME TO ci_events;
    ALTER TABLE jobs RENAME TO ci_jobs;
    ALTER TABLE projects RENAME TO ci_projects;
    ALTER TABLE runner_projects RENAME TO ci_runner_projects;
    ALTER TABLE runners RENAME TO ci_runners;
    ALTER TABLE services RENAME TO ci_services;
    ALTER TABLE tags RENAME TO ci_tags;
    ALTER TABLE taggings RENAME TO ci_taggings;
    ALTER TABLE trigger_requests RENAME TO ci_trigger_requests;
    ALTER TABLE triggers RENAME TO ci_triggers;
    ALTER TABLE variables RENAME TO ci_variables;
    ALTER TABLE web_hooks RENAME TO ci_web_hooks;
    EOF

### 4. Remove CI cronjob

```
cd /home/gitlab_ci/gitlab-ci
sudo -u gitlab_ci -H bundle exec whenever --clear-crontab
```

### 5. Dump GitLab CI database [CI]

First check used database and credentials on GitLab CI and GitLab CE/EE:

1. To check it on GitLab CI:

    cat /home/gitlab_ci/gitlab-ci/config/database.yml
    
1. To check it on GitLab CE/EE:

    cat /home/git/gitlab/config/database.yml

Please first check the database engine used for GitLab CI and GitLab CE/EE.

1. If your GitLab CI uses **mysql2** and GitLab CE/EE uses it too.
Please follow **Dump MySQL** guide.

1. If your GitLab CI uses **postgres** and GitLab CE/EE uses **postgres**.
Please follow **Dump PostgreSQL** guide.

1. If your GitLab CI uses **mysql2** and GitLab CE/EE uses **postgres**.
Please follow **Dump MySQL and migrate to PostgreSQL** guide.

**Remember credentials stored for accessing GitLab CI.
You will need to put these credentials into commands executed below.**

    $ cat config/database.yml                                                                                                                                                                                                                        [10:06:55]
    #
    # PRODUCTION
    #
    production:
      adapter: postgresql or mysql2
      encoding: utf8
      reconnect: false
      database: GITLAB_CI_DATABASE
      pool: 5
      username: DB_USERNAME
      password: DB_PASSWORD
      host: DB_HOSTNAME
      port: DB_PORT
      # socket: /tmp/mysql.sock

#### a. Dump MySQL
 
    mysqldump --default-character-set=utf8 --complete-insert --no-create-info \
      --host=DB_USERNAME --port=DB_PORT --user=DB_HOSTNAME -p 
      GITLAB_CI_DATABASE \
      ci_application_settings ci_builds ci_commits ci_events ci_jobs ci_projects \
      ci_runner_projects ci_runners ci_services ci_tags ci_taggings ci_trigger_requests \
      ci_triggers ci_variables ci_web_hooks > gitlab_ci.sql
      
#### b. Dump PostgreSQL
  
    pg_dump -h DB_HOSTNAME -U DB_USERNAME -p DB_PORT --data-only GITLAB_CI_DATABASE -t "ci_*" > gitlab_ci.sql

#### c. Dump MySQL and migrate to PostgreSQL

    # Dump existing MySQL database first
    mysqldump --default-character-set=utf8 --compatible=postgresql --complete-insert \
      --host=DB_USERNAME --port=DB_PORT --user=DB_HOSTNAME -p 
      GITLAB_CI_DATABASE \
      ci_application_settings ci_builds ci_commits ci_events ci_jobs ci_projects \
      ci_runner_projects ci_runners ci_services ci_tags ci_taggings ci_trigger_requests \
      ci_triggers ci_variables ci_web_hooks > gitlab_ci.sql.tmp
      
    # Convert database to be compatible with PostgreSQL
    git clone https://github.com/gitlabhq/mysql-postgresql-converter.git -b gitlab
    python mysql-postgresql-converter/db_converter.py gitlab_ci.sql.tmp gitlab_ci.sql.tmp2
    ed -s gitlab_ci.sql.tmp2 < mysql-postgresql-converter/move_drop_indexes.ed
    
    # Filter to only include INSERT statements
    grep "^\(START\|SET\|INSERT\|COMMIT\)" gitlab_ci.sql.tmp2 > gitlab_ci.sql
    
### 6. Make sure that your GitLab CE/EE is 8.0 [CE]

Please verify that you use GitLab CE/EE 8.0.
If not, please follow the update guide: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/7.14-to-8.0.md

### 7. Stop GitLab CE/EE [CE]

Before you can migrate data you need to stop GitLab CE/EE first.

    sudo service gitlab stop
    
### 8. Backup GitLab CE/EE [CE]

This migration poses a **significant risk** of breaking your GitLab CE/EE. 
**You should create the GitLab CI/EE backup before doing it.**

    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

### 9. Copy secret tokens [CE]

The `secrets.yml` file stores encryption keys for secure variables.

You need to copy the content of `config/secrets.yml` to the same file in GitLab CE.

    sudo cp /home/gitlab_ci/gitlab-ci/config/secrets.yml /home/git/gitlab/config/secrets.yml
    sudo chown git:git /home/git/gitlab/config/secrets.yml
    sudo chown 0600 /home/git/gitlab/config/secrets.yml
    
### 10. New configuration options for `gitlab.yml` [CE]

There are new configuration options available for [`gitlab.yml`](config/gitlab.yml.example).
View them with the command below and apply them manually to your current `gitlab.yml`:

```sh
git diff origin/7-14-stable:config/gitlab.yml.example origin/8-0-stable:config/gitlab.yml.example
```

The new options include configuration of GitLab CI that are now being part of GitLab CE and EE.

### 11. Copy build logs [CE]

You need to copy the contents of `builds/` to the same directory in GitLab CE/EE.

    sudo rsync -av /home/gitlab_ci/gitlab-ci/builds /home/git/gitlab/builds
    sudo chown -R git:git /home/git/gitlab/builds

The build traces are usually quite big so it will take a significant amount of time.

### 12. Import GitLab CI database [CE]

The one of the last steps is to import existing GitLab CI database.

    sudo mv /home/gitlab_ci/gitlab-ci/gitlab_ci.sql /home/git/gitlab/gitlab_ci.sql
    sudo chown git:git /home/git/gitlab/gitlab_ci.sql
    sudo -u git -H bundle exec rake ci:migrate CI_DUMP=/home/git/gitlab/gitlab_ci.sql RAILS_ENV=production

The task does:
1. Delete data from all existing CI tables
1. Import database data
1. Fix database auto increments
1. Fix tags assigned to Builds and Runners
1. Fix services used by CI

### 13. Start GitLab [CE]

You can start GitLab CI/EE now and see if everything is working.

    sudo service gitlab start

### 14. Update nginx [CI]
    
Now get back to GitLab CI and update **Nginx** configuration in order to:
1. Have all existing runners able to communicate with a migrated GitLab CI.
1. Have GitLab able send build triggers to CI address specified in Project's settings -> Services -> GitLab CI.

You need to edit `/etc/nginx/sites-available/gitlab_ci` and paste:
    
    # GITLAB CI
    server {
      listen 80 default_server;         # e.g., listen 192.168.1.1:80;
      server_name YOUR_CI_SERVER_FQDN;  # e.g., server_name source.example.com;
    
      access_log  /var/log/nginx/gitlab_ci_access.log;
      error_log   /var/log/nginx/gitlab_ci_error.log;
    
      # expose API to fix runners
      location /api {
        proxy_read_timeout    300;
        proxy_connect_timeout 300;
        proxy_redirect        off;
        proxy_set_header      X-Real-IP $remote_addr;
    
        # You need to specify your DNS servers that are able to resolve YOUR_GITLAB_SERVER_FQDN
        resolver 8.8.8.8 8.8.4.4;
        proxy_pass $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
      }
      
      # expose build endpoint to allow trigger builds
      location ~ ^/projects/\d+/build$ {
        proxy_read_timeout    300;
        proxy_connect_timeout 300;
        proxy_redirect        off;
        proxy_set_header      X-Real-IP $remote_addr;
    
        # You need to specify your DNS servers that are able to resolve YOUR_GITLAB_SERVER_FQDN
        resolver 8.8.8.8 8.8.4.4;
        proxy_pass $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
      }
    
      # redirect all other CI requests
      location / {
        return 301 $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
      }
    
      # adjust this to match the largest build log your runners might submit,
      # set to 0 to disable limit
      client_max_body_size 10m;
    }

Make sure to fill the blanks to match your setup:
1. **YOUR_CI_SERVER_FQDN**: The existing public facing address of GitLab CI, eg. ci.gitlab.com.
1. **YOUR_GITLAB_SERVER_FQDN**: The public facing address of GitLab CE/EE, eg. gitlab.com.

**Make sure to not remove the `/ci$request_uri`. This is required to properly forward the requests.**

You should also make sure that you can do:
1. `curl https://YOUR_GITLAB_SERVER_FQDN/` from your previous GitLab CI server.
1. `curl https://YOUR_CI_SERVER_FQDN/` from your GitLab CE/EE server.

## Check your configuration

    sudo nginx -t

## Restart nginx

    sudo /etc/init.d/nginx restart

### 15. Done!

If everything went OK you should be able to access all your GitLab CI data by pointing your browser to:
https://gitlab.example.com/ci/.

The GitLab CI should also work when using the previous address, redirecting you to the GitLab CE/EE.

**Enjoy!**
