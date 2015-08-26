# Select Version to Install
Make sure you view this installation guide from the branch (version) of GitLab CI you would like to install. In most cases
this should be the highest numbered stable branch (example shown below).

![capture](http://i.imgur.com/fmdlXxa.png)

If this is unclear check the [GitLab Blog](http://blog.gitlab.org/) for installation guide links by version.

## GitLab CI 7.12 requires GitLab 7.12 or newer

other [requirements](requirements.md)

# Setup:

## 1. Packages / Dependencies

`sudo` is not installed on Debian by default. Make sure your system is
up-to-date and install it.

    sudo apt-get update
    sudo apt-get upgrade

**Note:**
During this installation some files will need to be edited manually. If
you are familiar with vim set it as default editor with the commands
below. If you are not familiar with vim please skip this and keep using
the default editor.

    # Install vim
    sudo apt-get install vim
    sudo update-alternatives --set editor /usr/bin/vim.basic

Install the required packages:

    sudo apt-get install wget curl gcc checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev openssl nodejs
    sudo apt-get install redis-server

# 2. Ruby

Download Ruby and compile it:

    mkdir /tmp/ruby && cd /tmp/ruby
    curl --progress http://cache.ruby-lang.org/pub/ruby/ruby-2.1.6.tar.bz2 | tar xj
    cd ruby-2.1.6/
    ./configure --disable-install-rdoc
    make
    sudo make install

Install the Bundler Gem:

    sudo gem install bundler --no-ri --no-rdoc


## 3. GitLab CI user:

    sudo adduser --disabled-login --gecos 'GitLab CI' gitlab_ci


## 4. Prepare the database

We recommend PostgreSQL but you can also use MySQL

### MySQL

    # Install the database packages
    sudo apt-get install mysql-server mysql-client libmysqlclient-dev

    # Login to MySQL
    $ mysql -u root -p

    # Create the GitLab CI database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlab_ci_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Create the MySQL User change $password to a real password
    mysql> CREATE USER 'gitlab_ci'@'localhost' IDENTIFIED BY '$password';

    # Grant proper permissions to the MySQL User
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES ON `gitlab_ci_production`.* TO 'gitlab_ci'@'localhost';

    # Logout MYSQL
    mysql> exit;

### PostgreSQL

    # Install the database packages
    sudo apt-get install -y postgresql-9.1 libpq-dev

    # Login to PostgreSQL
    sudo -u postgres psql -d template1

    # Create a user for GitLab CI. We do not specify a password because we are using peer authentication.
    template1=# CREATE USER gitlab_ci;

    # Create the GitLab CI production database & grant all privileges on database
    template1=# CREATE DATABASE gitlab_ci_production OWNER gitlab_ci;

    # Quit the database session
    template1=# \q

    # Try connecting to the new database with the new user
    sudo -u gitlab_ci -H psql -d gitlab_ci_production

## 5. Get code

    cd /home/gitlab_ci/

    sudo -u gitlab_ci -H git clone https://gitlab.com/gitlab-org/gitlab-ci.git

    cd gitlab-ci

    sudo -u gitlab_ci -H git checkout 7-12-stable

## 6. Setup application

    # Edit application settings
    # Production
    sudo -u gitlab_ci -H cp config/application.yml.example config/application.yml
    sudo -u gitlab_ci -H editor config/application.yml
    # Development
    #sudo -u gitlab_ci -H cp config/application.yml.example.development config/application.yml

    # Copy the example secrets file
    sudo -u gitlab_ci -H cp config/secrets.yml.example config/secrets.yml
    sudo -u gitlab_ci -H chmod 0600 config/secrets.yml

    # Edit web server settings
    sudo -u gitlab_ci -H cp config/unicorn.rb.example config/unicorn.rb
    sudo -u gitlab_ci -H editor config/unicorn.rb

    # Create socket and pid directories
    sudo -u gitlab_ci -H mkdir -p tmp/sockets/
    sudo chmod -R u+rwX  tmp/sockets/
    sudo -u gitlab_ci -H mkdir -p tmp/pids/
    sudo chmod -R u+rwX  tmp/pids/

    # Change the permissions of the directory where build traces are stored
    sudo chmod -R u+rwX builds/

### Install gems

    # For MySQL (note, the option says "without ... postgres")
    sudo -u gitlab_ci -H bundle install --without development test postgres --deployment

    # Or for PostgreSQL (note, the option says "without ... mysql")
    sudo -u gitlab_ci -H bundle install --without development test mysql --deployment

### Setup db

    # mysql
    sudo -u gitlab_ci -H cp config/database.yml.mysql config/database.yml

    # postgres
    sudo -u gitlab_ci -H cp config/database.yml.postgresql config/database.yml

    # Edit user/password (not necessary with default Postgres setup)
    sudo -u gitlab_ci -H editor config/database.yml

    # Setup tables
    sudo -u gitlab_ci -H bundle exec rake setup RAILS_ENV=production

    # Setup schedules
    sudo -u gitlab_ci -H bundle exec whenever -w RAILS_ENV=production

### Secure secrets.yml

The `secrets.yml` file stores encryption keys for sessions and secure variables.
Backup `secrets.yml` someplace safe, but don't store it in the same place as your database backups.
Otherwise your secrets are exposed if one of your backups is compromised.

## 8. Install Init Script

Copy the init script (will be /etc/init.d/gitlab_ci):

    sudo cp /home/gitlab_ci/gitlab-ci/lib/support/init.d/gitlab_ci /etc/init.d/gitlab_ci

Make GitLab CI start on boot:

    sudo update-rc.d gitlab_ci defaults 21


Start your GitLab CI instance:

    sudo service gitlab_ci start
    # or
    sudo /etc/init.d/gitlab_ci start


# 8. Nginx


## Installation

    sudo apt-get install nginx

## Site Configuration

Download an example site config:

    sudo cp /home/gitlab_ci/gitlab-ci/lib/support/nginx/gitlab_ci /etc/nginx/sites-available/gitlab_ci
    sudo ln -s /etc/nginx/sites-available/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci

Make sure to edit the config file to match your setup:

    # Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN**
    # to the IP address and fully-qualified domain name
    # of your host serving GitLab CI
    sudo editor /etc/nginx/sites-enabled/gitlab_ci

## Check your configuration

    sudo nginx -t

## Start nginx

    sudo /etc/init.d/nginx start

# 9. GitLab OAuth2 application


Go to the admin area of GitLab, to the `Application` section. Create an application for the GitLab CI
For callback URL use: `http://ci.example.com/user_sessions/callback` if you use http, or `https://ci.example.com/user_sessions/callback` if you use https.

When `app_id` and `app_secret` are generated add them to the GitLab CI config:

```
production:
  gitlab_server:
    url: 'http://gitlab.example.com'
    app_id: XXXXXX
    app_secret: XXXXXX

```


# 10. Runners


Now you need Runners to process your builds.
Checkout the [Gitlab Runner section](https://about.gitlab.com/gitlab-ci/#gitlab-runner) to install it

# Done!


Visit YOUR_SERVER for your first GitLab CI login.
You will be asked to authorize with your GitLab credentials.

**Enjoy!**

## Advanced settings

### SMTP email settings

If you want to use SMTP do next:

    # Copy config file
    sudo -u gitlab_ci -H cp config/initializers/smtp_settings.rb.sample config/initializers/smtp_settings.rb

    # Edit it with your settings
    sudo -u gitlab_ci -H editor config/initializers/smtp_settings.rb

Restart application

### Custom Redis Connection

If you'd like Resque to connect to a Redis server on a non-standard port or on
a different host, you can configure its connection string via the
`config/resque.yml` file.

    # example
    production: redis://redis.example.tld:6379

If you want to connect the Redis server via socket, then use the "unix:" URL scheme
and the path to the Redis socket file in the `config/resque.yml` file.

    # example
    production: unix:/path/to/redis/socket
