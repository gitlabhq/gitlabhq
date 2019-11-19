---
type: howto
---

# Installation from source

This is the official installation guide to set up a production GitLab server
using the source files. To set up a **development installation** or for many
other installation options, see the [main installation page](README.md).
It was created for and tested on **Debian/Ubuntu** operating systems.
Read [requirements.md](requirements.md) for hardware and operating system requirements.
If you want to install on RHEL/CentOS, we recommend using the
[Omnibus packages](https://about.gitlab.com/install/).

This guide is long because it covers many cases and includes all commands you
need, this is [one of the few installation scripts that actually work out of the box](https://twitter.com/robinvdvleuten/status/424163226532986880).
The following steps have been known to work. **Use caution when you deviate**
from this guide. Make sure you don't violate any assumptions GitLab makes about
its environment. For example, many people run into permission problems because
they changed the location of directories or run services as the wrong user.

If you find a bug/error in this guide, **submit a merge request**
following the
[contributing guide](https://gitlab.com/gitlab-org/gitlab/blob/master/CONTRIBUTING.md).

## Consider the Omnibus package installation

Since an installation from source is a lot of work and error prone we strongly recommend the fast and reliable [Omnibus package installation](https://about.gitlab.com/install/) (deb/rpm).

One reason the Omnibus package is more reliable is its use of runit to restart any of the GitLab processes in case one crashes.
On heavily used GitLab instances the memory usage of the Sidekiq background worker will grow over time.

Omnibus packages solve this by [letting the Sidekiq terminate gracefully](../administration/operations/sidekiq_memory_killer.md) if it uses too much memory.
After this termination runit will detect Sidekiq is not running and will start it.
Since installations from source don't use runit for process supervision, Sidekiq
can't be terminated and its memory usage will grow over time.

## Select a version to install

Make sure you view [this installation guide](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/install/installation.md) from the branch (version) of GitLab you would like to install (e.g., `11-7-stable`).
You can select the branch in the version dropdown in the top left corner of GitLab (below the menu bar).

If the highest number stable branch is unclear, check the [GitLab blog](https://about.gitlab.com/blog/) for installation guide links by version.

## GitLab directory structure

This is the main directory structure you will end up with following the instructions
of this page:

```
|-- home
|   |-- git
|       |-- .ssh
|       |-- gitlab
|       |-- gitlab-shell
|       |-- repositories
```

- `/home/git/.ssh` - Contains OpenSSH settings. Specifically, the `authorized_keys`
  file managed by GitLab Shell.
- `/home/git/gitlab` - GitLab core software.
- `/home/git/gitlab-shell` - Core add-on component of GitLab. Maintains SSH
  cloning and other functionality.
- `/home/git/repositories` - Bare repositories for all projects organized by
  namespace. This is where the Git repositories which are pushed/pulled are
  maintained for all projects. **This area contains critical data for projects.
  [Keep a backup](../raketasks/backup_restore.md).**

NOTE: **Note:**
The default locations for repositories can be configured in `config/gitlab.yml`
of GitLab and `config.yml` of GitLab Shell.

For a more in-depth overview, see the [GitLab architecture doc](../development/architecture.md).

## Overview

The GitLab installation consists of setting up the following components:

1. [Packages and dependencies](#1-packages-and-dependencies).
1. [Ruby](#2-ruby).
1. [Go](#3-go).
1. [Node](#4-node).
1. [System users](#5-system-users).
1. [Database](#6-database).
1. [Redis](#7-redis).
1. [GitLab](#8-gitlab).
1. [NGINX](#9-nginx).

## 1. Packages and dependencies

`sudo` is not installed on Debian by default. Make sure your system is
up-to-date and install it.

```sh
# run as root!
apt-get update -y
apt-get upgrade -y
apt-get install sudo -y
```

NOTE: **Note:**
During this installation, some files will need to be edited manually. If you are familiar with vim, set it as default editor with the commands below. If you are not familiar with vim, skip this and keep using the default editor.

```sh
# Install vim and set as default editor
sudo apt-get install -y vim
sudo update-alternatives --set editor /usr/bin/vim.basic
```

Install the required packages (needed to compile Ruby and native extensions to Ruby gems):

```sh
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
  libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev \
  libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake \
  runit
```

Ubuntu 14.04 (Trusty Tahr) doesn't have the `libre2-dev` package available, but
you can [install re2 manually](https://github.com/google/re2/wiki/Install).

If you want to use Kerberos for user authentication, install `libkrb5-dev`:

```sh
sudo apt-get install libkrb5-dev
```

NOTE: **Note:**
If you don't know what Kerberos is, you can assume you don't need it.

Make sure you have the right version of Git installed:

```sh
# Install Git
sudo apt-get install -y git-core

# Make sure Git is version 2.22.0 or higher
git --version
```

Starting with GitLab 12.0, Git is required to be compiled with `libpcre2`.
Find out if that's the case:

```sh
ldd /usr/local/bin/git | grep pcre2
```

The output should be similar to:

```
libpcre2-8.so.0 => /usr/lib/libpcre2-8.so.0 (0x00007f08461c3000)
```

Is the system packaged Git too old, or not compiled with pcre2? Remove it and compile from source:

```sh
# Remove packaged Git
sudo apt-get remove git-core

# Install dependencies
sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev build-essential

# Download and compile pcre2 from source
curl --silent --show-error --location https://ftp.pcre.org/pub/pcre/pcre2-10.33.tar.gz --output pcre2.tar.gz
tar -xzf pcre2.tar.gz
cd pcre2-10.33
chmod +x configure
./configure --prefix=/usr --enable-jit
make
sudo make install

# Download and compile from source
cd /tmp
curl --remote-name --location --progress https://www.kernel.org/pub/software/scm/git/git-2.22.0.tar.gz
echo 'a4b7e4365bee43caa12a38d646d2c93743d755d1cea5eab448ffb40906c9da0b  git-2.22.0.tar.gz' | shasum -a256 -c - && tar -xzf git-2.22.0.tar.gz
cd git-2.22.0/
./configure --with-libpcre
make prefix=/usr/local all

# Install into /usr/local/bin
sudo make prefix=/usr/local install

# When editing config/gitlab.yml (Step 5), change the git -> bin_path to /usr/local/bin/git
```

For the [Custom Favicon](../user/admin_area/appearance.md#favicon) to work, GraphicsMagick
needs to be installed.

```sh
sudo apt-get install -y graphicsmagick
```

**Note:** In order to receive mail notifications, make sure to install a mail server. By default, Debian is shipped with exim4 but this [has problems](https://gitlab.com/gitlab-org/gitlab-foss/issues/12754) while Ubuntu does not ship with one. The recommended mail server is postfix and you can install it with:

```sh
sudo apt-get install -y postfix
```

Then select 'Internet Site' and press enter to confirm the hostname.

## 2. Ruby

The Ruby interpreter is required to run GitLab.

**Note:** The current supported Ruby (MRI) version is 2.6.x. GitLab 12.2
  dropped support for Ruby 2.5.x.

The use of Ruby version managers such as [RVM], [rbenv](https://github.com/rbenv/rbenv) or [chruby] with GitLab
in production, frequently leads to hard to diagnose problems. For example,
GitLab Shell is called from OpenSSH, and having a version manager can prevent
pushing and pulling over SSH. Version managers are not supported and we strongly
advise everyone to follow the instructions below to use a system Ruby.

Linux distributions generally have older versions of Ruby available, so these
instructions are designed to install Ruby from the official source code.

Remove the old Ruby 1.8 if present:

```sh
sudo apt-get remove ruby1.8
```

Download Ruby and compile it:

```sh
mkdir /tmp/ruby && cd /tmp/ruby
curl --remote-name --progress https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz
echo '2347ed6ca5490a104ebd5684d2b9b5eefa6cd33c  ruby-2.6.3.tar.gz' | shasum -c - && tar xzf ruby-2.6.3.tar.gz
cd ruby-2.6.3

./configure --disable-install-rdoc
make
sudo make install
```

Then install the Bundler gem (a version below 2.x):

```sh
sudo gem install bundler --no-document --version '< 2'
```

## 3. Go

Since GitLab 8.0, GitLab has several daemons written in Go. To install
GitLab we need a Go compiler. The instructions below assume you use 64-bit
Linux. You can find downloads for other platforms at the [Go download
page](https://golang.org/dl).

```sh
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --progress https://dl.google.com/go/go1.11.10.linux-amd64.tar.gz
echo 'aefaa228b68641e266d1f23f1d95dba33f17552ba132878b65bb798ffa37e6d0  go1.11.10.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.11.10.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/
rm go1.11.10.linux-amd64.tar.gz
```

## 4. Node

Since GitLab 8.17, GitLab requires the use of Node to compile JavaScript
assets, and Yarn to manage JavaScript dependencies. The current minimum
requirements for these are:

- `node` >= v8.10.0. (We recommend node 12.x as it is faster)
- `yarn` >= v1.10.0.

In many distros,
the versions provided by the official package repositories are out of date, so
we'll need to install through the following commands:

```sh
# install node v12.x
curl --location https://deb.nodesource.com/setup_12.x | sudo bash -
sudo apt-get install -y nodejs

curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install yarn
```

Visit the official websites for [node](https://nodejs.org/en/download/package-manager/) and [yarn](https://yarnpkg.com/en/docs/install/) if you have any trouble with these steps.

## 5. System users

Create a `git` user for GitLab:

```sh
sudo adduser --disabled-login --gecos 'GitLab' git
```

## 6. Database

NOTE: **Note:**
Starting from GitLab 12.1, only PostgreSQL is supported. Because we need to make
use of extensions and concurrent index removal, you need at least PostgreSQL 9.2.

1. Install the database packages:

   ```sh
   sudo apt-get install -y postgresql postgresql-client libpq-dev postgresql-contrib
   ```

1. Create a database user for GitLab:

   ```sh
   sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
   ```

1. Create the `pg_trgm` extension (required for GitLab 8.6+):

   ```sh
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
   ```

1. Create the GitLab production database and grant all privileges on the database:

   ```sh
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
   ```

1. Try connecting to the new database with the new user:

   ```sh
   sudo -u git -H psql -d gitlabhq_production
   ```

1. Check if the `pg_trgm` extension is enabled:

   ```sh
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'pg_trgm'
   AND installed_version IS NOT NULL;
   ```

   If the extension is enabled this will produce the following output:

   ```
   enabled
   ---------
    t
   (1 row)
   ```

1. Quit the database session:

   ```sh
   gitlabhq_production> \q
   ```

## 7. Redis

GitLab requires at least Redis 2.8.

If you are using Debian 8 or Ubuntu 14.04 and up, you can simply install
Redis 2.8 with:

```sh
sudo apt-get install redis-server
```

Once done, you can configure Redis:

```sh
# Configure redis to use sockets
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.orig

# Disable Redis listening on TCP by setting 'port' to 0
sudo sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf

# Enable Redis socket for default Debian / Ubuntu path
echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf

# Grant permission to the socket to all members of the redis group
echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf

# Create the directory which contains the socket
sudo mkdir -p /var/run/redis
sudo chown redis:redis /var/run/redis
sudo chmod 755 /var/run/redis

# Persist the directory which contains the socket, if applicable
if [ -d /etc/tmpfiles.d ]; then
  echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf
fi

# Activate the changes to redis.conf
sudo service redis-server restart

# Add git to the redis group
sudo usermod -aG redis git
```

## 8. GitLab

```sh
# We'll install GitLab into the home directory of the user "git"
cd /home/git
```

### Clone the Source

```sh
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b X-Y-stable gitlab
```

Make sure to replace `X-Y-stable` with the stable branch that matches the
version you want to install. For example, if you want to install 11.8 you would
use the branch name `11-8-stable`.

CAUTION: **Caution:**
You can change `X-Y-stable` to `master` if you want the *bleeding edge* version, but never install `master` on a production server!

### Configure It

```sh
# Go to GitLab installation folder
cd /home/git/gitlab

# Copy the example GitLab config
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

# Update GitLab config file, follow the directions at top of the file
sudo -u git -H editor config/gitlab.yml

# Copy the example secrets file
sudo -u git -H cp config/secrets.yml.example config/secrets.yml
sudo -u git -H chmod 0600 config/secrets.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX,go-w log/
sudo chmod -R u+rwX tmp/

# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
sudo chmod -R u+rwX tmp/pids/
sudo chmod -R u+rwX tmp/sockets/

# Create the public/uploads/ directory
sudo -u git -H mkdir -p public/uploads/

# Make sure only the GitLab user has access to the public/uploads/ directory
# now that files in public/uploads are served by gitlab-workhorse
sudo chmod 0700 public/uploads

# Change the permissions of the directory where CI job logs are stored
sudo chmod -R u+rwX builds/

# Change the permissions of the directory where CI artifacts are stored
sudo chmod -R u+rwX shared/artifacts/

# Change the permissions of the directory where GitLab Pages are stored
sudo chmod -R ug+rwX shared/pages/

# Copy the example Unicorn config
sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

# Find number of cores
nproc

# Enable cluster mode if you expect to have a high load instance
# Set the number of workers to at least the number of cores
# Ex. change the amount of workers to 3 for 2GB RAM server
sudo -u git -H editor config/unicorn.rb

# Copy the example Rack attack config
sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

# Configure Git global settings for git user
# 'autocrlf' is needed for the web editor
sudo -u git -H git config --global core.autocrlf input

# Disable 'git gc --auto' because GitLab already runs 'git gc' when needed
sudo -u git -H git config --global gc.auto 0

# Enable packfile bitmaps
sudo -u git -H git config --global repack.writeBitmaps true

# Enable push options
sudo -u git -H git config --global receive.advertisePushOptions true

# Enable fsyncObjectFiles to reduce risk of repository corruption if the server crashes
sudo -u git -H git config --global core.fsyncObjectFiles true

# Configure Redis connection settings
sudo -u git -H cp config/resque.yml.example config/resque.yml

# Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
sudo -u git -H editor config/resque.yml
```

CAUTION: **Caution:**
Make sure to edit both `gitlab.yml` and `unicorn.rb` to match your setup.
If you want to use Puma web server, see [Using Puma](#using-puma) for the additional steps.

NOTE: **Note:**
If you want to use HTTPS, see [Using HTTPS](#using-https) for the additional steps.

### Configure GitLab DB Settings

```sh
sudo -u git cp config/database.yml.postgresql config/database.yml

# Remove host, username, and password lines from config/database.yml.
# Once modified, the `production` settings will be as follows:
#
#   production:
#     adapter: postgresql
#     encoding: unicode
#     database: gitlabhq_production
#     pool: 10
#
sudo -u git -H editor config/database.yml

# Remote PostgreSQL only:
# Update username/password in config/database.yml.
# You only need to adapt the production settings (first part).
# If you followed the database guide then please do as follows:
# Change 'secure password' with the value you have given to $password
# You can keep the double quotes around the password
sudo -u git -H editor config/database.yml

# Make config/database.yml readable to git only
sudo -u git -H chmod o-rwx config/database.yml
```

### Install Gems

NOTE: **Note:**
As of Bundler 1.5.2, you can invoke `bundle install -jN` (where `N` is the number of your processor cores) and enjoy parallel gems installation with measurable difference in completion time (~60% faster). Check the number of your cores with `nproc`. For more information, see this [post](https://thoughtbot.com/blog/parallel-gem-installing-using-bundler).

Make sure you have `bundle` (run `bundle -v`):

- `>= 1.5.2`, because some [issues](https://devcenter.heroku.com/changelog-items/411) were [fixed](https://github.com/bundler/bundler/pull/2817) in 1.5.2.
- `< 2.x`.

```sh
sudo -u git -H bundle install --deployment --without development test mysql aws kerberos
```

NOTE: **Note:**
If you want to use Kerberos for user authentication, omit `kerberos` in the `--without` option above.

### Install GitLab Shell

GitLab Shell is an SSH access and repository management software developed specially for GitLab.

```sh
# Run the installation task for gitlab-shell (replace `REDIS_URL` if needed):
sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true

# By default, the gitlab-shell config is generated from your main GitLab config.
# You can review (and modify) the gitlab-shell config as follows:
sudo -u git -H editor /home/git/gitlab-shell/config.yml
```

NOTE: **Note:**
If you want to use HTTPS, see [Using HTTPS](#using-https) for the additional steps.

NOTE: **Note:**
Make sure your hostname can be resolved on the machine itself by either a proper DNS record or an additional line in `/etc/hosts` ("127.0.0.1  hostname"). This might be necessary, for example, if you set up GitLab behind a reverse proxy. If the hostname cannot be resolved, the final installation check will fail with `Check GitLab API access: FAILED. code: 401` and pushing commits will be rejected with `[remote rejected] master -> master (hook declined)`.

NOTE: **Note:**
GitLab Shell application startup time can be greatly reduced by disabling RubyGems. This can be done in several ways:

- Export `RUBYOPT=--disable-gems` environment variable for the processes.
- Compile Ruby with `configure --disable-rubygems` to disable RubyGems by default. Not recommended for system-wide Ruby.
- Omnibus GitLab [replaces the *shebang* line of the `gitlab-shell/bin/*` scripts](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1707).

### Install GitLab Workhorse

GitLab-Workhorse uses [GNU Make](https://www.gnu.org/software/make/). The
following command-line will install GitLab-Workhorse in `/home/git/gitlab-workhorse`
which is the recommended location.

```sh
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

You can specify a different Git repository by providing it as an extra parameter:

```sh
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse,https://example.com/gitlab-workhorse.git]" RAILS_ENV=production
```

### Install GitLab-Elasticsearch-indexer

GitLab-Elasticsearch-Indexer uses [GNU Make](https://www.gnu.org/software/make/). The
following command-line will install GitLab-Elasticsearch-Indexer in `/home/git/gitlab-elasticsearch-indexer`
which is the recommended location.

```sh
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer]" RAILS_ENV=production
```

You can specify a different Git repository by providing it as an extra parameter:

```sh
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer,https://example.com/gitlab-elasticsearch-indexer.git]" RAILS_ENV=production
```

The source code will first be fetched to the path specified by the first parameter. Then a binary will be built under its `bin` directory.
You will then need to update `gitlab.yml`'s `production -> elasticsearch -> indexer_path` setting to point to that binary.

### Install GitLab Pages

GitLab Pages uses [GNU Make](https://www.gnu.org/software/make/). This step is optional and only needed if you wish to host static sites from within GitLab. The following commands will install GitLab Pages in `/home/git/gitlab-pages`. For additional setup steps, consult the [administration guide](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/pages/source.md) for your version of GitLab as the GitLab Pages daemon can be run several different ways.

```sh
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Install Gitaly

```sh
# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

You can specify a different Git repository by providing it as an extra parameter:

```sh
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories,https://example.com/gitaly.git]" RAILS_ENV=production
```

Next, make sure that Gitaly is configured:

```sh
# Restrict Gitaly socket access
sudo chmod 0700 /home/git/gitlab/tmp/sockets/private
sudo chown git /home/git/gitlab/tmp/sockets/private

# If you are using non-default settings you need to update config.toml
cd /home/git/gitaly
sudo -u git -H editor config.toml
```

For more information about configuring Gitaly see
[the Gitaly documentation](../administration/gitaly/index.md).

### Start Gitaly

Gitaly must be running for the next section.

```sh
gitlab_path=/home/git/gitlab
gitaly_path=/home/git/gitaly

sudo -u git -H sh -c "$gitlab_path/bin/daemon_with_pidfile $gitlab_path/tmp/pids/gitaly.pid \
  $gitaly_path/gitaly $gitaly_path/config.toml >> $gitlab_path/log/gitaly.log 2>&1 &"
```

### Initialize Database and Activate Advanced Features

```sh
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# Type 'yes' to create the database tables.

# or you can skip the question by adding force=yes
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production force=yes

# When done, you see 'Administrator account created:'
```

NOTE: **Note:**
You can set the Administrator/root password and e-mail by supplying them in environmental variables, `GITLAB_ROOT_PASSWORD` and `GITLAB_ROOT_EMAIL` respectively, as seen below. If you don't set the password (and it is set to the default one), wait to expose GitLab to the public internet until the installation is done and you've logged into the server the first time. During the first login, you'll be forced to change the default password. An Enterprise Edition license may also be installed at this time by supplying a full path in the `GITLAB_LICENSE_FILE` environment variable.

```sh
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=yourpassword GITLAB_ROOT_EMAIL=youremail GITLAB_LICENSE_FILE="/path/to/license"
```

### Secure secrets.yml

The `secrets.yml` file stores encryption keys for sessions and secure variables.
Backup `secrets.yml` someplace safe, but don't store it in the same place as your database backups.
Otherwise, your secrets are exposed if one of your backups is compromised.

### Install Init Script

Download the init script (will be `/etc/init.d/gitlab`):

```sh
sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

And if you are installing with a non-default folder or user copy and edit the defaults file:

```sh
sudo cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
```

If you installed GitLab in another directory or as a user other than the default, you should change these settings in `/etc/default/gitlab`. Do not edit `/etc/init.d/gitlab` as it will be changed on upgrade.

Make GitLab start on boot:

```sh
sudo update-rc.d gitlab defaults 21
```

### Set up Logrotate

```sh
sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
```

### Check Application Status

Check if GitLab and its environment are configured correctly:

```sh
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

### Compile GetText PO files

```sh
sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production
```

### Compile Assets

```sh
sudo -u git -H yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
```

If `rake` fails with `JavaScript heap out of memory` error, try to run it with `NODE_OPTIONS` set as follows.

```sh
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### Start Your GitLab Instance

```sh
sudo service gitlab start
# or
sudo /etc/init.d/gitlab restart
```

## 9. NGINX

NOTE: **Note:**
NGINX is the officially supported web server for GitLab. If you cannot or do not want to use NGINX as your web server, see [GitLab recipes](https://gitlab.com/gitlab-org/gitlab-recipes/).

### Installation

```sh
sudo apt-get install -y nginx
```

### Site Configuration

Copy the example site config:

```sh
sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
```

Make sure to edit the config file to match your setup. Also, ensure that you match your paths to GitLab, especially if installing for a user other than the `git` user:

```sh
# Change YOUR_SERVER_FQDN to the fully-qualified
# domain name of your host serving GitLab.
#
# Remember to match your paths to GitLab, especially
# if installing for a user other than 'git'.
#
# If using Ubuntu default nginx install:
# either remove the default_server from the listen line
# or else sudo rm -f /etc/nginx/sites-enabled/default
sudo editor /etc/nginx/sites-available/gitlab
```

If you intend to enable GitLab Pages, there is a separate NGINX config you need
to use. Read all about the needed configuration at the
[GitLab Pages administration guide](../administration/pages/index.md).

**Note:** If you want to use HTTPS, replace the `gitlab` NGINX config with `gitlab-ssl`. See [Using HTTPS](#using-https) for HTTPS configuration details.

### Test Configuration

Validate your `gitlab` or `gitlab-ssl` NGINX config file with the following command:

```sh
sudo nginx -t
```

You should receive `syntax is okay` and `test is successful` messages. If you receive errors check your `gitlab` or `gitlab-ssl` NGINX config file for typos, etc. as indicated in the error message given.

NOTE: **Note:**
Verify that the installed version is greater than 1.12.1 by running `nginx -v`. If it's lower, you may receive the error below:
`nginx: [emerg] unknown "start$temp=[filtered]$rest" variable
nginx: configuration file /etc/nginx/nginx.conf test failed`

### Restart

```sh
sudo service nginx restart
```

## Post-install

### Double-check Application Status

To make sure you didn't miss anything run a more thorough check with:

```sh
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, congratulations on successfully installing GitLab!

NOTE: Supply `SANITIZE=true` environment variable to `gitlab:check` to omit project names from the output of the check command.

### Initial Login

Visit YOUR_SERVER in your web browser for your first GitLab login.

If you didn't [provide a root password during setup](#initialize-database-and-activate-advanced-features),
you'll be redirected to a password reset screen to provide the password for the
initial administrator account. Enter your desired password and you'll be
redirected back to the login screen.

The default account's username is **root**. Provide the password you created
earlier and login. After login, you can change the username if you wish.

**Enjoy!**

You can use `sudo service gitlab start` and `sudo service gitlab stop` to start and stop GitLab.

## Advanced Setup Tips

### Relative URL support

See the [Relative URL documentation](relative_url.md) for more information on
how to configure GitLab with a relative URL.

### Using HTTPS

To use GitLab with HTTPS:

1. In `gitlab.yml`:
   1. Set the `port` option in section 1 to `443`.
   1. Set the `https` option in section 1 to `true`.
1. In the `config.yml` of GitLab Shell:
   1. Set `gitlab_url` option to the HTTPS endpoint of GitLab (e.g. `https://git.example.com`).
   1. Set the certificates using either the `ca_file` or `ca_path` option.
1. Use the `gitlab-ssl` NGINX example config instead of the `gitlab` config.
   1. Update `YOUR_SERVER_FQDN`.
   1. Update `ssl_certificate` and `ssl_certificate_key`.
   1. Review the configuration file and consider applying other security and performance enhancing features.

Using a self-signed certificate is discouraged but if you must use it, follow the normal directions. Then:

1. Generate a self-signed SSL certificate:

   ```sh
   mkdir -p /etc/nginx/ssl/
   cd /etc/nginx/ssl/
   sudo openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key
   sudo chmod o-r gitlab.key
   ```

1. In the `config.yml` of GitLab Shell set `self_signed_cert` to `true`.

### Enable Reply by email

See the ["Reply by email" documentation](../administration/reply_by_email.md) for more information on how to set this up.

### LDAP Authentication

You can configure LDAP authentication in `config/gitlab.yml`. Restart GitLab after editing this file.

### Using Custom OmniAuth Providers

See the [OmniAuth integration documentation](../integration/omniauth.md).

### Build your projects

GitLab can build your projects. To enable that feature, you need GitLab Runners to do that for you.
See the [GitLab Runner section](https://about.gitlab.com/product/continuous-integration/#gitlab-runner) to install it.

### Adding your Trusted Proxies

If you are using a reverse proxy on a separate machine, you may want to add the
proxy to the trusted proxies list. Otherwise users will appear signed in from the
proxy's IP address.

You can add trusted proxies in `config/gitlab.yml` by customizing the `trusted_proxies`
option in section 1. Save the file and [reconfigure GitLab](../administration/restart_gitlab.md)
for the changes to take effect.

### Custom Redis Connection

If you'd like to connect to a Redis server on a non-standard port or a different host, you can configure its connection string via the `config/resque.yml` file.

```
# example
production:
  url: redis://redis.example.tld:6379
```

If you want to connect the Redis server via socket, use the "unix:" URL scheme and the path to the Redis socket file in the `config/resque.yml` file.

```
# example
production:
  url: unix:/path/to/redis/socket
```

Also, you can use environment variables in the `config/resque.yml` file:

```
# example
production:
  url: <%= ENV.fetch('GITLAB_REDIS_URL') %>
```

### Custom SSH Connection

If you are running SSH on a non-standard port, you must change the GitLab user's SSH config.

```
# Add to /home/git/.ssh/config
host localhost          # Give your setup a name (here: override localhost)
    user git            # Your remote git user
    port 2222           # Your port number
    hostname 127.0.0.1; # Your server name or IP
```

You also need to change the corresponding options (e.g. `ssh_user`, `ssh_host`, `admin_uri`) in the `config\gitlab.yml` file.

### Additional Markup Styles

Apart from the always supported Markdown style, there are other rich text files that GitLab can display. But you might have to install a dependency to do so. See the [`github-markup` gem README](https://github.com/gitlabhq/markup#markups) for more information.

### Using Puma

Puma is a multi-threaded HTTP 1.1 server for Ruby applications.

To use GitLab with Puma:

1. Finish GitLab setup so you have it up and running.
1. Copy the supplied example Puma config file into place:

   ```sh
   cd /home/git/gitlab

   # Copy config file for the web server
   sudo -u git -H cp config/puma.rb.example config/puma.rb
   ```

1. Edit the system `init.d` script to use `EXPERIMENTAL_PUMA=1` flag. If you have `/etc/default/gitlab`, then you should edit it instead.
1. Restart GitLab.

## Troubleshooting

### "You appear to have cloned an empty repository."

If you see this message when attempting to clone a repository hosted by GitLab,
this is likely due to an outdated NGINX or Apache configuration, or a missing or
misconfigured GitLab Workhorse instance. Double-check that you've
[installed Go](#3-go), [installed GitLab Workhorse](#install-gitlab-workhorse),
and correctly [configured NGINX](#site-configuration).

### `google-protobuf` "LoadError: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.14' not found"

This can happen on some platforms for some versions of the
`google-protobuf` gem. The workaround is to install a source-only
version of this gem.

First, you must find the exact version of `google-protobuf` that your
GitLab installation requires:

```sh
cd /home/git/gitlab

# Only one of the following two commands will print something. It
# will look like: * google-protobuf (3.2.0)
bundle list | grep google-protobuf
bundle check | grep google-protobuf
```

Below, `3.2.0` is used as an example. Replace it with the version number
you found above:

```sh
cd /home/git/gitlab
sudo -u git -H gem install google-protobuf --version 3.2.0 --platform ruby
```

Finally, you can test whether `google-protobuf` loads correctly. The
following should print 'OK'.

```sh
sudo -u git -H bundle exec ruby -rgoogle/protobuf -e 'puts :OK'
```

If the `gem install` command fails, you may need to install the developer
tools of your OS.

On Debian/Ubuntu:

```sh
sudo apt-get install build-essential libgmp-dev
```

On RedHat/CentOS:

```sh
sudo yum groupinstall 'Development Tools'
```

[RVM]: https://rvm.io/ "RVM Homepage"
[chruby]: https://github.com/postmodern/chruby "chruby on GitHub"
