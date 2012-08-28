#!/bin/sh

# We don't want unnecessary output
alias which='alias | which &> /dev/null'

which apt-get  && {

  sudo apt-get update && \
  sudo apt-get upgrade && \
  sudo apt-get install -y git git-core wget curl gcc libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline-gplv2-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server python-dev python-pip libyaml-dev postfix ruby ruby-dev

}
|| which yum && {

  sudo yum groupinstall -y 'Development Tools' && \
  sudo yum install -y git git-core wget curl gcc libxml2-devel libxslt-devel sqlite sqlite-devel libcurl-devel readline-devel glibc-devel openssl-devel mysql++-devel make zlib-devel libicu-devel redis openssh-server python-devel python-pip libyaml-devel postfix ruby ruby-devel
} || {
  echo "No apt-get or yum found or problem with installing packages"
  exit 1
}

echo "exit Gem::Version.new(RUBY_VERSION + '') >= Gem::Version.new('1.9.2')" | ruby || {

  which apt-get && sudo apt-get remove -y ruby ruby-dev
  which yum && sudo yum remove -y ruby ruby-devel

  wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz && \
  tar xfvz ruby-1.9.3-p194.tar.gz && \
  cd ruby-1.9.3-p194 && \
  ./configure && \
  make && \
  sudo make install || {
    echo "Error building Ruby from the source code or installing the binaries"
    exit 1
  }
}

which apt-get && {
  sudo adduser \
    --system \
    --shell /bin/sh \
    --gecos 'git version control' \
    --group \
    --disabled-password \
    --home /home/git \
    git

  sudo adduser --disabled-login --gecos 'gitlab system' gitlab

} || which yum && {

  sudo adduser \
    --shell /bin/sh \
    --comment 'git version control' \
    --user-group \
    --home /home/git \
    git

  sudo adduser -s /sbin/nologin --comment 'gitlab system' gitlab
}

sudo usermod -a -G git gitlab

sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

cd /home/git
sudo -H -u git git clone git://github.com/gitlabhq/gitolite /home/git/gitolite

sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; /home/git/gitolite/src/gl-system-install"
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
sudo chmod 777 /home/git/gitlab.pub

sudo -u git -H sed -i 's/0077/0007/g' /home/git/share/gitolite/conf/example.gitolite.rc
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gl-setup -q /home/git/gitlab.pub"

sudo chmod g+X /home/git/
sudo chmod -R g+rwX /home/git/repositories/
sudo chown -R git:git /home/git/repositories/

sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin
sudo rm -rf /tmp/gitolite-admin
