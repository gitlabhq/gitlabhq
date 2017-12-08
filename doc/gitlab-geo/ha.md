# GitLab Geo High Availability

This document describes a possible configuration on how to set up Geo
in a Highly Available environment. If your HA setup differs from the one
described in this document, you still can use the instructions and adapt them
to your needs.

## Architecture overview

![Active/Active HA Diagram](../administration/img/high_availability/active-active-diagram.png)

This documentation assumes all machines used in this HA setup can
communicate over the network using internal IP addresses.

NOTE: **Note:**
`external_url` must be the same for every machine, and `https` should be used.

## Services machine

One machine, called the Services machine will be used to run:

- NFS shares
- PostgreSQL
- Redis
- HAProxy

### Prerequisites

Make sure you have GitLab EE installed using the
[Omnibus package](https://about.gitlab.com/installation).

The following steps should be performed in the Services machine. SSH to it
and login as root:

```sh
sudo -i
```

### Step 1: Set up NFS share

1. Install the required NFS packages:

    ```sh
    apt-get install nfs-kernel-server
    ```

1. Create the required directories:

    ```sh
    mkdir -p /var/opt/gitlab/nfs/builds/    \
             /var/opt/gitlab/nfs/git-data/  \
             /var/opt/gitlab/nfs/shared/    \
             /var/opt/gitlab/nfs/uploads/
    ```

1. Make the directories available through NFS, by adding this to
   `/etc/exports` (see also the [NFS HA recommended options](../administration/high_availability/nfs.md#recommended-options)):

    ```
    /var/opt/gitlab/nfs *(rw,sync,no_root_squash)
    ```

1. Start the NFS service:

    ```sh
    systemctl start nfs-kernel-server.service
    ```

1. Apply the settings to take effect:

    ```sh
    exportfs -a
    ```

### Step 2: Set up PostgreSQL server

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    postgresql['enable'] = true

    ##
    ## Replace 1.2.3.4 with the internal IP address of the current machine and
    ## 2.3.4.5 and 3.4.5.6 with the internal IP addresses of the machines
    ## running the Application server(s).
    ##
    postgresql['listen_address'] = '1.2.3.4'
    postgresql['trust_auth_cidr_addresses'] = ['1.2.3.4/32', '2.3.4.5/32', '3.4.5.6/32']

    gitlab_rails['auto_migrate'] = true
    gitlab_rails['db_password'] = 'DB password'
    ```

1. **Only for secondary nodes** Also add this to `/etc/gitlab/gitlab.rb`:

    ```ruby
    geo_postgresql['enable'] = true

    ##
    ## Replace 1.2.3.4 with the internal IP address of the current machine and
    ## 2.3.4.5 and 3.4.5.6 with the internal IP addresses of the machines
    ## running the Application server(s).
    ##
    geo_postgresql['listen_address'] = '1.2.3.4'
    geo_postgresql['trust_auth_cidr_addresses'] = ['1.2.3.4/32', '2.3.4.5/32', '3.4.5.6/32']

    geo_secondary['auto_migrate'] = true
    geo_secondary['db_host'] = '1.2.3.4'
    geo_secondary['db_password'] = 'Geo tracking DB password'
    ```

### Step 3: Set up Redis

Edit `/etc/gitlab/gitlab.rb` and add the following:

 ```ruby
redis['enable'] = true
redis['password'] = 'Redis password'

##
## Replace 1.2.3.4 with the internal IP address of the current machine
##
redis['bind'] = '1.2.3.4'
redis['port'] = 6379

##
## Needed because 'gitlab-ctl reconfigure' runs 'rake cache:clear:redis'
##
gitlab_rails['redis_password'] = 'Redis password'
```

### Step 4: HAProxy

We'll be using HAProxy to balance the load between the Application machines.

1. Manually stop Nginx (we will disable it in `/etc/gitlab/gitlab.rb` later):

    ```sh
    gitlab-ctl stop nginx
    ```

1. Install the HAProxy package:

    ```sh
    apt-get install haproxy
    ```

1. Make sure you have a single SSL `pem` file containing the
   certificate and the private key.

    ```sh
    cat /etc/ssl/cert.pem /etc/ssl/privkey.pem > /etc/ssl/aio.pem
    ```

1. Edit `/etc/haproxy/haproxy.cfg` and overwrite it with the following:

    ```
    global
        log 127.0.0.1 local0
        log 127.0.0.1 local1 notice
        maxconn 4096
        user haproxy
        group haproxy
        daemon

    defaults
        log global
        mode http
        option httplog
        option dontlognull
        option forwardfor
        option http-server-close
        stats enable
        stats uri /haproxy?stats

    frontend www-http
        bind *:80
        reqadd X-Forwarded-Proto:\ http
        default_backend www-backend

    frontend www-https
        bind 0.0.0.0:443 ssl crt /etc/ssl/aio.pem
        reqadd X-Forwarded-Proto:\ https
        default_backend www-backend

    backend www-backend
        redirect scheme https if !{ ssl_fc }
        balance leastconn
        option httpclose
        option forwardfor
        cookie JSESSIONID prefix

        ##
        ## Enter the IPs of your Application servers here
        ##
        server nodeA 2.3.4.5:80 cookie A check
        server nodeB 3.4.5.6:80 cookie A check
    ```

1. Start the HAProxy service:

    ```sh
    service haproxy start
    ```

### Step 5: Apply settings

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    nginx['enable'] = false
    sidekiq['enable'] = false
    unicorn['enable'] = false

    ##
    ## These are optional/untested/irrelevant
    ##
    gitaly['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false
    prometheus['enable'] = false
    ```

1. [Reconfigure GitLab][] for the changes to take effect.

1. Until [Omnibus#2797](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2797)
   gets fixed, you will need to manually restart PostgreSQL:

    ```sh
    gitlab-ctl restart postgresql geo-postgresql
    ```

### Step 6: Step up database replication

Database replication will operate between the Services machines.
Follow the [Setup the database replication](database.md) instructions
to set up.

## Application machine

Repeat these steps for every machine running `gitlab-rails`.

The following steps should be performed in the Application machine. SSH to it
and login as root:

```sh
sudo -i
```

### Step 1: Add NFS mount

1. Install the required NFS packages:

    ```sh
    apt-get install nfs-common
    ```

1. Create the mount point directory:

    ```sh
    mkdir -p /mnt/nfs
    ```

1. Edit `/etc/fstab` and add the following lines
   (where `1.2.3.4` is the internal IP of the Services machine):

    ```
    1.2.3.4:/var/opt/gitlab/nfs /mnt/nfs nfs defaults,nfsvers=4,soft,rsize=1048576,wsize=1048576,noatime
    ```

1. Mount the share:

    ```sh
    mount -a -t nfs
    ```

You can check if the mount is working by checking the existence of the
directories `builds/`, `git-data/`, `shared/`, and `uploads/` in
`/mnt/nfs`:

```
ls /mnt/nfs
```

### Step 2: Configure proxied SSL

The load balancer will take care of the SSL termination, so configure nginx to
work with proxied SSL.

Follow the instructions to [configure proxied SSL](https://docs.gitlab.com/omnibus/settings/nginx.html#supporting-proxied-ssl).

### Step 3: Configure connections to the Services machine

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    ##
    ## Use the NFS mount to store data
    ##
    gitlab_rails['uploads_directory'] = '/mnt/nfs/uploads'
    gitlab_rails['shared_path'] = '/mnt/nfs/shared'
    gitlab_ci['builds_directory'] = '/mnt/nfs/builds'
    git_data_dirs({
      'default': {
        'path': '/mnt/nfs/git-data'
      }
    })

    high_availability['mountpoint'] = '/mnt/nfs'

    ##
    ## Disable PostgreSQL on the local machine and connect to the remote
    ##
    postgresql['enable'] = false
    gitlab_rails['auto_migrate'] = false
    gitlab_rails['db_host'] = '1.2.3.4'
    gitlab_rails['db_password'] = 'DB password'

    ##
    ## Disable Redis on the local machine and connect to the remote
    ##
    redis['enable'] = false
    gitlab_rails['redis_host'] = '1.2.3.4'
    gitlab_rails['redis_password'] = 'Redis password'
    ```

1. **[Only for primary nodes]** Add the following to `/etc/gitlab/gitlab.rb`:

    ```ruby
    geo_primary_role['enable'] = true
    ```

1. **[Only for secondary nodes]** Add the following to `/etc/gitlab/gitlab.rb`:

    ```ruby
    geo_secondary_role['enable'] = true

    geo_postgresql['enable'] = true # TODO set to false when https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2980 is fixed
    geo_secondary['auto_migrate'] = false
    geo_secondary['db_host'] = '1.2.3.4'
    geo_secondary['db_password'] = 'Geo tracking DB password'
    ```

1. Copy the database encryption key. Follow the instructions of
   [Step 1. Copying the database encryption key](configuration.md#step-1-copying-the-database-encryption-key)

1. [Reconfigure GitLab][] for the changes to take effect (if you haven't done
   this yet in previous step).

1. [Restart GitLab][] to start the processes with the correct connections.

## Troubleshooting

### HAProxy

You can connect to `https://example.com/haproxy?stats` to monitor the
load balancing between the Application machines.

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-restart
