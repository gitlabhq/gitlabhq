# Welcome to GitLab [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://secure.travis-ci.org/gitlabhq/gitlabhq)

GitLab is a free Project/Repository management application


<img src="http://gitlabhq.com/front.png" width="900" height="471">


## Application details

rails 3.1
works only with gitolite
sqlite as default a database

## Requirements

* ruby 1.9.2
* sqlite
* git
* gitolite
* ubuntu/debian
* pygments lib - `sudo easy_install pygments`

## Install Project

```bash
git clone git://github.com/gitlabhq/gitlabhq.git

cd gitlabhq/

# install this library first
sudo pip install pygments
sudo apt-get install python-dev

sudo gem install bundler

bundle install --without development test

bundle exec rake db:setup RAILS_ENV=production

# create admin user
# login....admin@local.host
# pass.....5iveL!fe
bundle exec rake db:seed_fu RAILS_ENV=production
```

Install gitolite (with repo umask 0007), edit `config/gitlab.yml` and start server

```bash
bundle exec rails s -e production
```


## Install Gitolite


```bash


# create git user
sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'git version control' \
  --group \
  --disabled-password \
  --home /home/git \
  git


# Add your user to git group
usermod -a -G git gitlabhq_user_name 

```

### !!! IMPORTANT !!! Gitolite should have repository umask 0007 so users from git group has read/write access to repo

```bash

# copy your pub key to git home
cp ~/.ssh/id_rsa.pub /home/git/rails.pub

# enter user git
sudo -i -u git 

# clone gitolite
git clone git://github.com/gitlabhq/gitolite

# install gitolite
gitolite/src/gl-system-install


# Setup (Dont forget to set umask as 0007!!)
gl-setup ~/rails.pub


```


## Install ruby 1.9.2

```bash
sudo aptitude install git-core openssh-server curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline5-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev

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
