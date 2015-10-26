# Installation at FreeBSD

## Important Notes

This guide is long because it covers many cases and includes all commands you need.

This installation guide was created for and tested on **FreeBSD** operating systems. Please read [doc/install/requirements.md](./requirements.md) for hardware and operating system requirements.

This is the official installation guide to set up a production server. To set up a **development installation** or for many other installation options please see [the installation section of the readme](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md#installation).

The following steps have been known to work. Please **use caution when you deviate** from this guide. Make sure you don't violate any assumptions GitLab makes about its environment. For example many people run into permission problems because they changed the location of directories or run services as the wrong user.

If not mentioned otherwise, please perform the commands as **root**!

If you find a bug/error in this guide please **submit a merge request**
following the
[contributing guide](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md).

## Overview

The GitLab installation consists of setting up the following components:

1. Package or Port
1. Database
1. Redis
1. GitLab
1. Nginx

## 1. Package or Port

There are two methods to install Gitlab: as binary package (fast, easy) or compile it from the source (relatively easy).

It is adviced to use the binary package installation. All dependencies will be installed automatically:

    pkg install www/gitlab

You are free to build it from the source. Please checkout the latest ports-tree and follow this steps:

    cd /usr/ports/www/gitlab
    make install

## 2. Database

We recommend using a PostgreSQL database. For MySQL check [MySQL setup guide](database_mysql.md). *Note*: because we need to make use of extensions you need at least pgsql 9.1.

    # Install the database packages
    # If you want newer versions change them appropriately to: postgresql92-server, postgresql93-server, etc.
    pkg install postgresql91-server postgresql91-client

    # Login to PostgreSQL
    psql -U pgsql -d template1

    # Create a user for GitLab
    # Do not type the 'template1=#', this is part of the prompt
    template1=# CREATE USER git CREATEDB;

    # Create the GitLab production database & grant all privileges on database
    template1=# CREATE DATABASE gitlabhq_production OWNER git;

    # Quit the database session
    template1=# \q

    # Try connecting to the new database with the new user
    psql -U git -d gitlabhq_production

    # Quit the database session
    gitlabhq_production> \q

## 3. Redis

Redis is automatically installed, when installing Gitlab. But some Configuration is needed.

    # Enable Redis socket
    echo 'unixsocket /var/run/redis/redis.sock' >> /usr/local/etc/redis.conf
  
    # Grant permission to the socket to all members of the redis group
    echo 'unixsocketperm 770' >> /usr/local/etc/redis.conf

    # Allow Redis to be started
    echo 'redis_enable="YES"' >> /etc/rc.conf

    # Activate the changes to redis.conf
    service redis restart

    # Add git user to redis group
    pw groupmod redis -m git

## 4. GitLab

### Configure It

    # Become git user
    su git

    # Go to GitLab installation folder
    cd /usr/local/www/gitlab

    # Update GitLab config file, follow the directions at top of file
    vi config/gitlab.yml

    # Find number of cores
    sysctl hw.ncpu

    # Enable cluster mode if you expect to have a high load instance
    # Ex. change amount of workers to 3 for 2GB RAM server
    # Set the number of workers to at least the number of cores
    vi config/unicorn.rb

    # Configure Git global settings for git user, used when editing via web editor
    git config --global core.autocrlf input

    # Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
    vi config/resque.yml

**Important Note:** Make sure to edit both `gitlab.yml` and `unicorn.rb` to match your setup.

**Note:** If you want to use HTTPS, see [Using HTTPS](#using-https) for the additional steps.

### Configure GitLab DB Settings

    # Remote PostgreSQL only:
    # Update username/password in config/database.yml.
    # You only need to adapt the production settings (first part).
    # If you followed the database guide then please do as follows:
    # Change 'secure password' with the value you have given to $password
    # You can keep the double quotes around the password
    vi config/database.yml

### Install GitLab Shell

GitLab Shell is an SSH access and repository management software developed specially for GitLab.

    # Become git user and go into the installation path
    su git
    cd /usr/local/www/gitlab

    # Run the installation task for gitlab-shell (replace `REDIS_URL` if needed):
    rake gitlab:shell:install[v2.6.3] REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production

    # By default, the gitlab-shell config is generated from your main GitLab config.
    # You can review (and modify) the gitlab-shell config as follows:
    vi /home/git/gitlab-shell/config.yml

**Note:** If you want to use HTTPS, see [Using HTTPS](#using-https) for the additional steps.

**Note:** Make sure your hostname can be resolved on the machine itself by either a proper DNS record or an additional line in /etc/hosts ("127.0.0.1  hostname"). This might be necessary for example if you set up gitlab behind a reverse proxy. If the hostname cannot be resolved, the final installation check will fail with "Check GitLab API access: FAILED. code: 401" and pushing commits will be rejected with "[remote rejected] master -> master (hook declined)".  
  
### Initialize Database and Activate Advanced Features

    # make sure you are still using the git user
    rake gitlab:setup RAILS_ENV=production

    # Type 'yes' to create the database tables.

    # When done you see 'Administrator account created:'

**Note:** You can set the Administrator/root password by supplying it in environmental variable `GITLAB_ROOT_PASSWORD` as seen below. If you don't set the password (and it is set to the default one) please wait with exposing GitLab to the public internet until the installation is done and you've logged into the server the first time. During the first login you'll be forced to change the default password.

    rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=yourpassword

### Check Application Status

Check if GitLab and its environment are configured correctly:

    rake gitlab:env:info RAILS_ENV=production

### Compile Assets

    rake assets:precompile RAILS_ENV=production

### Start Your GitLab Instance

    # If you are still using the git user, type `exit` to change back to root
    # then start the GitLab
    service gitlab start
    # or
    /usr/local/etc/rc.d/gitlab restart
 
## 7. Nginx

**Note:** Nginx is the officially supported web server for GitLab. If you cannot or do not want to use Nginx as your web server, have a look at the [GitLab recipes](https://gitlab.com/gitlab-org/gitlab-recipes/).

### Installation

    pkg install nginx

### Site Configuration

Just include the provided configuration in your nginx configuration.

    # do this as root:
    vi /usr/local/etc/nginx/nginx.conf

    # within the 'http' configuration block add:
    include       /usr/local/www/gitlab/lib/support/nginx/gitlab

**Note:** If you want to use HTTPS, replace the `gitlab` Nginx config with `gitlab-ssl`. See [Using HTTPS](#using-https) for HTTPS configuration details.

### Test Configuration

Validate your `gitlab` or `gitlab-ssl` Nginx config file with the following command:

    # do this as root:
    nginx -t

You should receive `syntax is okay` and `test is successful` messages. If you receive errors check your `gitlab` or `gitlab-ssl` Nginx config file for typos, etc. as indicated in the error message given.

### Restart

    service nginx restart

## Done!

### Double-check Application Status

To make sure you didn't miss anything run a more thorough check with:

    su
    su git
    rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations on successfully installing GitLab!

NOTE: Supply `SANITIZE=true` environment variable to `gitlab:check` to omit project names from the output of the check command.

### Initial Login

Visit YOUR_SERVER in your web browser for your first GitLab login. The setup has created a default admin account for you. You can use it to log in:

    root
    5iveL!fe

**Important Note:** On login you'll be prompted to change the password.

**Enjoy!**

You can use as root `service gitlab start` and `service gitlab stop` to start and stop GitLab.

## Advanced Setup Tips

### Using HTTPS

To use GitLab with HTTPS:

1. In `gitlab.yml`:
    1. Set the `port` option in section 1 to `443`.
    1. Set the `https` option in section 1 to `true`.
1. In the `config.yml` of gitlab-shell:
    1. Set `gitlab_url` option to the HTTPS endpoint of GitLab (e.g. `https://git.example.com`).
    1. Set the certificates using either the `ca_file` or `ca_path` option.
1. Use the `gitlab-ssl` Nginx example config instead of the `gitlab` config.
    1. Update `YOUR_SERVER_FQDN`.
    1. Update `ssl_certificate` and `ssl_certificate_key`.
    1. Review the configuration file and consider applying other security and performance enhancing features.

Using a self-signed certificate is discouraged but if you must use it follow the normal directions then:

1. Generate a self-signed SSL certificate:

    ```
    mkdir -p /usr/local/etc/nginx/ssl/
    cd /usr/local/etc/nginx/ssl/
    openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key
    chmod o-r gitlab.key
    ```
1. In the `config.yml` of gitlab-shell set `self_signed_cert` to `true`.

### Additional Markup Styles

Apart from the always supported markdown style there are other rich text files that GitLab can display. But you might have to install a dependency to do so. Please see the [github-markup gem readme](https://github.com/gitlabhq/markup#markups) for more information.

### Custom Redis Connection

If you'd like Resque to connect to a Redis server on a non-standard port or on a different host, you can configure its connection string via the `config/resque.yml` file.

    # example
    production: redis://redis.example.tld:6379

If you want to connect the Redis server via socket, then use the "unix:" URL scheme and the path to the Redis socket file in the `config/resque.yml` file.

    # example
    production: unix:/path/to/redis/socket

### Custom SSH Connection

If you are running SSH on a non-standard port, you must change the GitLab user's SSH config.

    # Add to /home/git/.ssh/config
    host localhost          # Give your setup a name (here: override localhost)
        user git            # Your remote git user
        port 2222           # Your port number
        hostname 127.0.0.1; # Your server name or IP

You also need to change the corresponding options (e.g. `ssh_user`, `ssh_host`, `admin_uri`) in the `config\gitlab.yml` file.

### LDAP Authentication

You can configure LDAP authentication in `config/gitlab.yml`. Please restart GitLab after editing this file. This requires building gitlab from the ports-tree with the needed option selected.

### Using Custom Omniauth Providers

See the [omniauth integration document](../integration/omniauth.md). This requires building gitlab from the ports-tree with the needed options selected.