sudo adduser \
  --gecos 'gitlab dev user' \
  --disabled-password \
  --home /home/gitlabdev \
  gitlabdev

sudo -i -u gitlabdev -H  sh -c "ssh-keygen -t rsa"
