---
comments: false
---

# Upgrading Community Edition and Enterprise Edition from source

NOTE: **Note:**
Users wishing to upgrade to 12.0.0 will have to take some extra steps. See the
version specific upgrade instructions for 12.0.0 for more details.

Make sure you view this update guide from the branch (version) of GitLab you
would like to install (e.g., `11.8`. You can select the version in the version
dropdown at the top left corner of GitLab (below the menu bar).

In all examples, replace `BRANCH` with the branch for the version you uprading
to (e.g. `11-8-stable` for `11.8`), and replace `PREVIOUS_BRANCH` with the
branch for the version you are upgrading from (e.g. `11-7-stable` for `11.7`).

If the highest number stable branch is unclear please check the
[GitLab Blog](https://about.gitlab.com/blog/archives.html) for installation
guide links by version.

If you are changing from GitLab Community Edition to GitLab Enterprise Edition, see
the [Upgrading from CE to EE](upgrading_from_ce_to_ee.md) documentation.

## Guidelines for all versions

This section contains all the steps necessary to upgrade Community Edition or
Enterprise Edition, regardless of the version you are upgrading to. Version
specific guidelines (should there be any) are covered separately.

### 1. Backup

NOTE: If you installed GitLab from source, make sure `rsync` is installed.

```bash
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### 2. Stop server

```bash
sudo service gitlab stop
```

### 3. Update Ruby

NOTE: Beginning in GitLab 12.2, we only support Ruby 2.6 or higher, and dropped
support for Ruby 2.5. Be sure to upgrade if necessary.

You can check which version you are running with `ruby -v`.

Download Ruby and compile it:

```bash
mkdir /tmp/ruby && cd /tmp/ruby
curl --remote-name --progress https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.5.tar.gz
echo '1416ce288fb8bfeae07a12b608540318c9cace71  ruby-2.6.5.tar.gz' | shasum -c - && tar xzf ruby-2.6.5.tar.gz
cd ruby-2.6.5

./configure --disable-install-rdoc
make
sudo make install
```

Install Bundler:

```bash
sudo gem install bundler --no-document --version '< 2'
```

### 4. Update Node

NOTE: Beginning in GitLab 11.8, we only support node 8 or higher, and dropped
support for node 6. Be sure to upgrade if necessary.

GitLab utilizes [webpack](https://webpack.js.org/) to compile frontend assets.
This requires a minimum version of node v8.10.0.

You can check which version you are running with `node -v`. If you are running
a version older than `v8.10.0` you will need to update to a newer version. You
can find instructions to install from community maintained packages or compile
from source at the nodejs.org website.

<https://nodejs.org/en/download/>

GitLab also requires the use of yarn `>= v1.10.0` to manage JavaScript
dependencies.

```bash
curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install yarn
```

More information can be found on the [yarn website](https://yarnpkg.com/en/docs/install).

### 5. Update Go

NOTE: GitLab 11.4 and higher only supports Go 1.10.x and newer, and dropped support for Go
1.9.x. Be sure to upgrade your installation if necessary.

You can check which version you are running with `go version`.

Download and install Go:

```bash
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --progress https://dl.google.com/go/go1.11.10.linux-amd64.tar.gz
echo 'aefaa228b68641e266d1f23f1d95dba33f17552ba132878b65bb798ffa37e6d0  go1.11.10.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.11.10.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/
rm go1.11.10.linux-amd64.tar.gz
```

### 6. Update Git

NOTE: **Note:**
GitLab 11.11 and higher only supports Git 2.21.x and newer, and
[dropped support for older versions](https://gitlab.com/gitlab-org/gitlab-foss/issues/54255).
Be sure to upgrade your installation if necessary.

```bash
# Make sure Git is version 2.21.0 or higher
git --version

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
make install

# Download and compile from source
cd /tmp
curl --remote-name --location --progress https://www.kernel.org/pub/software/scm/git/git-2.21.0.tar.gz
echo '85eca51c7404da75e353eba587f87fea9481ba41e162206a6f70ad8118147bee  git-2.21.0.tar.gz' | shasum -a256 -c - && tar -xzf git-2.21.0.tar.gz
cd git-2.21.0/
./configure --with-libpcre
make prefix=/usr/local all

# Install into /usr/local/bin
sudo make prefix=/usr/local install

# You should edit config/gitlab.yml, change the git -> bin_path to /usr/local/bin/git
```

### 7. Get latest code

```bash
cd /home/git/gitlab

sudo -u git -H git fetch --all --prune
sudo -u git -H git checkout -- db/schema.rb # local changes will be restored automatically
sudo -u git -H git checkout -- locale
```

For GitLab Community Edition:

```bash
cd /home/git/gitlab

sudo -u git -H git checkout BRANCH
```

OR

For GitLab Enterprise Edition:

```bash
cd /home/git/gitlab

sudo -u git -H git checkout BRANCH-ee
```

### 8. Update GitLab Shell

```bash
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### 9. Update GitLab Workhorse

Install and compile GitLab Workhorse. GitLab Workhorse uses
[GNU Make](https://www.gnu.org/software/make/).
If you are not using Linux you may have to run `gmake` instead of
`make` below.

```bash
cd /home/git/gitlab-workhorse

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_WORKHORSE_VERSION)
sudo -u git -H make
```

### 10. Update Gitaly

#### Compile Gitaly

```shell
cd /home/git/gitaly
sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITALY_SERVER_VERSION)
sudo -u git -H make
```

### 11. Update GitLab Pages

#### Only needed if you use GitLab Pages

Install and compile GitLab Pages. GitLab Pages uses
[GNU Make](https://www.gnu.org/software/make/).
If you are not using Linux you may have to run `gmake` instead of
`make` below.

```bash
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### 12. Update configuration files

#### New configuration options for `gitlab.yml`

There might be configuration options available for [`gitlab.yml`][yaml]. View
them with the command below and apply them manually to your current
`gitlab.yml`:

```sh
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:config/gitlab.yml.example origin/BRANCH:config/gitlab.yml.example
```

#### NGINX configuration

Ensure you're still up-to-date with the latest NGINX configuration changes:

```sh
cd /home/git/gitlab

# For HTTPS configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab-ssl origin/BRANCH:lib/support/nginx/gitlab-ssl

# For HTTP configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab origin/BRANCH:lib/support/nginx/gitlab
```

If you are using Strict-Transport-Security in your installation to continue
using it you must enable it in your NGINX configuration as GitLab application no
longer handles setting it.

If you are using Apache instead of NGINX please see the updated [Apache templates].
Also note that because Apache does not support upstreams behind Unix sockets you
will need to let GitLab Workhorse listen on a TCP port. You can do this
via [`/etc/default/gitlab`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/support/init.d/gitlab.default.example#L38).

#### SMTP configuration

If you're installing from source and use SMTP to deliver mail, you will need to
add the following line to `config/initializers/smtp_settings.rb`:

```ruby
ActionMailer::Base.delivery_method = :smtp
```

See [smtp_settings.rb.sample] as an example.

#### Init script

There might be new configuration options available for
[`gitlab.default.example`][gl-example]. View them with the command below and
apply them manually to your current `/etc/default/gitlab`:

```sh
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:lib/support/init.d/gitlab.default.example origin/BRANCH:lib/support/init.d/gitlab.default.example
```

Ensure you're still up-to-date with the latest init script changes:

```bash
cd /home/git/gitlab

sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

For Ubuntu 16.04.1 LTS:

```bash
sudo systemctl daemon-reload
```

### 13. Install libs, migrations, etc

```bash
cd /home/git/gitlab

sudo -u git -H bundle install --deployment --without development test mysql aws kerberos

# Optional: clean up old gems
sudo -u git -H bundle clean

# Run database migrations
sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

# Compile GetText PO files

sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production

# Update node dependencies and recompile assets
sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"

# Clean up cache
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

### 14. Start application

```bash
sudo service gitlab start
sudo service nginx restart
```

### 15. Check application status

Check if GitLab and its environment are configured correctly:

```bash
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything run a more thorough check:

```bash
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, then congratulations, the upgrade is complete!

## Version specific upgrading instructions

This section contains upgrading instructions for specific versions. When
present, first follow the upgrading guidelines for all versions. If the version
you are upgrading to is not listed here, then no additional steps are required.

<!--
Example:

### 11.8.0

Additional instructions here.
-->

## Things went south? Revert to previous version

### 1. Revert the code to the previous version

To revert to a previous version, you'll need to following the upgrading guides
for the previous version. If you upgraded to 11.8 and want to revert back to
11.7, you'll need to follow the guides for upgrading from 11.6 to 11.7. You can
use the version dropdown at the top of the page to select the right version.

When reverting, you should _not_ follow the database migration guides, as the
backup is already migrated to the previous version.

### 2. Restore from the backup

```bash
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

If you have more than one backup `*.tar` file(s) please add `BACKUP=timestamp_of_backup` to the command above.

[yaml]: https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example
[gl-example]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib/support/init.d/gitlab.default.example
[smtp_settings.rb.sample]: https://gitlab.com/gitlab-org/gitlab/blob/master/config/initializers/smtp_settings.rb.sample#L13
[Apache templates]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache
