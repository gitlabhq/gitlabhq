# Installing a locally compiled google-protobuf gem

First we must find the exact version of google-protobuf that your
GitLab installation requires.

    cd /home/git/gitlab

    # Only one of the following two commands will print something. It
    # will look like: * google-protobuf (3.2.0)
    bundle list | grep google-protobuf
    bundle check | grep google-protobuf

Below we use `3.2.0` as an example. Replace it with the version number
you found above.

    cd /home/git/gitlab
    sudo -u git -H gem install google-protobuf --version 3.2.0 --platform ruby

Finally, you can test whether google-protobuf loads correctly. The
following should print 'OK'.

    sudo -u git -H bundle exec ruby -rgoogle/protobuf -e 'puts :OK'

If the `gem install` command fails you may need to install developer
tools. On Debian: `apt-get install build-essential libgmp-dev`, on
Centos/RedHat `yum groupinstall 'Development Tools'`.
