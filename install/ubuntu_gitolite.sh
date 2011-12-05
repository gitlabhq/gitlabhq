sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'git version control' \
  --group \
  --disabled-password \
  --home /home/git \
  git


PATH=/home/dzaporozhets/bin:$PATH

# Add your user to git group
sudo usermod -a -G git `eval whoami` 

# copy your pub key to git home
sudo cp ~/.ssh/id_rsa.pub /home/git/rails.pub

# clone gitolite
sudo -u git -H git clone git://github.com/gitlabhq/gitolite /home/git/gitolite

# install gitolite
sudo -u git -H /home/git/gitolite/src/gl-system-install


# Setup (Dont forget to set umask as 0007!!)
sudo -u git -H /home/git/bin/gl-setup /home/git/rails.pub

echo "Done"
