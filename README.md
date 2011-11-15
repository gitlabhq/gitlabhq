# Welcome to GitLab [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://secure.travis-ci.org/gitlabhq/gitlabhq)

GitLab is a free Project/Repository management application

## Application details

rails 3.1
works only with gitosis
sqlite as default a database

## Requirements

* ruby 1.9.2
* sqlite
* git
* gitosis
* ubuntu/debian
* pygments lib - `sudo easy_install pygments`

## Install Project

```bash
git clone git://github.com/gitlabhq/gitlabhq.git

cd gitlabhq/

# install this library first
sudo easy_install pygments

# give your user access to remove git repo
# Ex.
#   If you are going to use user 'gitlabhq' for rails server
#   gitlabhq ALL = (git) NOPASSWD: /bin/rm" | sudo tee -a /etc/sudoers
#
echo "USERNAME ALL = (git) NOPASSWD: /bin/rm" | sudo tee -a /etc/sudoers

sudo gem install bundler

bundle

bundle exec rake db:setup RAILS_ENV=production

# create admin user
# login....admin@local.host
# pass.....5iveL!fe
bundle exec rake db:seed_fu RAILS_ENV=production
```

Install gitosis, edit `conf/gitosis.yml` and start server

```bash
rails s -e production
```

## Install Gitosis

```bash
sudo aptitude install gitosis

sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'git version control' \
  --group \
  --disabled-password \
  --home /home/git \
  git

ssh-keygen -t rsa

sudo -H -u git gitosis-init < ~/.ssh/id_rsa.pub

sudo chmod 755 /home/git/repositories/gitosis-admin.git/hooks/post-update
```

## Install ruby 1.9.2

```bash
sudo aptitude install git-core curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline5-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev

wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz

tar xfvz ruby-1.9.2-p290.tar.gz

cd ruby-1.9.2-p290
./configure
make
sudo checkinstall -D

sudo gem update --system

echo "gem: --no-rdoc --no-ri" > ~/.gemrc
```

## Community

[Google Group](https://groups.google.com/group/gitlabhq)

## Contribute

We develop project on our private server.
Want to help? Contact us on twitter or email to become a team member.
