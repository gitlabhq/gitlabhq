# install all packages
sudo apt-get install git-core openssh-server curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline5-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev

# get ruby 1.9.2
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
tar xfvz ruby-1.9.2-p290.tar.gz
cd ruby-1.9.2-p290
./configure
make
sudo make install
echo "Done"
