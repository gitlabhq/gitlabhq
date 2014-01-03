# Updating Ruby from source

This guide explains how to update Ruby in case you installed it from source according to the instructions in https://gitlab.com/gitlab-org/gitlab-ce/blob/masterdoc/install/installation.md#2-ruby .

### 1. Look for Ruby versions
This guide will only update `/usr/local/bin/ruby`. You can see which Ruby binaries are installed on your system by running:

```bash
ls -l $(which -a ruby)
```

### 2. Stop GitLab

```bash
sudo service gitlab stop
```

### 3. Install or update dependencies
Here we are assuming you are using Debian/Ubuntu.

```bash
sudo apt-get install build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl
```

### 4. Download, compile and install Ruby
Find the latest stable version of Ruby 1.9 or 2.0 at https://www.ruby-lang.org/en/downloads/ . We recommend at least 2.0.0-p353, which is patched against [CVE-2013-4164](https://www.ruby-lang.org/en/news/2013/11/22/heap-overflow-in-floating-point-parsing-cve-2013-4164/).

```bash
cd /tmp
curl --progress http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz | tar xz
cd ruby-2.0.0-p353
./configure --disable-install-rdoc
make
sudo make install # overwrite the existing Ruby in /usr/local/bin
sudo gem install bundler
```

### 5. Reinstall GitLab gem bundle
Just to be sure we will reinstall the gems used by GitLab. Note that the `bundle install` command [depends on your choice of database](https://gitlab.com/gitlab-org/gitlab-ce/blob/masterdoc/install/installation.md#install-gems).

```bash
cd /home/git/gitlab
sudo -u git -H rm -rf vendor/bundle  # remove existing Gem bundle
sudo -u git -H bundle install --deployment --without development test postgres aws # Assuming MySQL
```

### 6. Start GitLab
We are now ready to restart GitLab.

```bash
sudo service gitlab start
```

### Done
