# Configuring Redis for GitLab HA

You can choose to install and manage Redis yourself, or you can use GitLab
Omnibus packages to help.

## Experimental Redis Sentinel support

Since 8.10 release, you can configure a list of Redis Sentinel servers that 
will monitor a group of Redis servers to provide you with a standard failover
support.

There is currently one exception to the Sentinel support: **mail_room**, the
component that process incoming emails.

It doesn't support Sentinel yet, but we hope to integrate a future release 
that does support it.

To get a better understanding on how to correctly setup Sentinel, please read
[Redis Sentinel documentation](http://redis.io/topics/sentinel) first, as
faling to configure it correctly can lead to data-loss.

### Redis setup

You must have at least 2 Redis servers: 1 Master, 1 or more Slaves.
They should be configured the same way and with similar server specs, as
in a failover situation, any Slave can be elected as the new Master by
the Sentinels servers.

In a minimal setup, the only required change for the slaves in `redis.conf` 
is the addition of a `slaveof` line pointing to the initial master like this:

```conf
slaveof 192.168.1.1 6379
```

You can increase the security by defining a `requirepass` configuration in
the master:

```conf
requirepass "<password>
```

and adding this line to all the slave servers:

```conf
masterauth "<password>"
```

> **Note** This setup is not safe to be used by a machine accessible by the 
internet. Use it in combination with tight firewall rules.

### Sentinel setup

The support for Sentinel in ruby have some [caveats](https://github.com/redis/redis-rb/issues/531). 
While you can give any name for the `master-group-name` part of the 
configuration, as in this example: 

```conf
sentinel monitor <master-group-name> <ip> <port> <quorum>`
```

For it to work in ruby, you have to use the "hostname" of the master redis
server otherwhise you will get an error message like this one: 
`Redis::CannotConnectError: No sentinels available.`.


Here is an example configuration file (`sentinel.conf`) for a Sentinel node:
 
```conf
port 26379
sentinel monitor master-redis.example.com 10.10.10.10 6379 1
sentinel down-after-milliseconds master-redis.example.com 10000
sentinel config-epoch master-redis.example.com 0
sentinel leader-epoch locmaster-redis.example.comalhost 0
```

### GitLab setup

You can enable or disable sentinel support at any time in new or existing
installs. From the GitLab application perspective, all it requires is
the correct credentials for the Master redis and for a few Sentinels nodes.

It doesn't require a list of all sentinel nodes, as in case of a failure,
the application will need to query only one of them.

For a source based install, you must change `/home/git/gitlab/config/resque.yml`,
following the example in `/home/git/gitlab/config/resque.yml.example` and
uncommenting the sentinels line, changing to the correct server credentials,
and resstart GitLab. 

For a Omnibus install you have to add/change this lines from the 
`/etc/gitlab/gitlab.rb` configuration file:
 
```ruby
gitlab['gitlab-rails']['redis_host'] = "master-redis.example.com"
gitlab['gitlab-rails']['redis_port'] = 6379
gitlab['gitlab-rails']['redis_password'] = "redis-secure-password-here"
gitlab['gitlab-rails']['redis_socket'] = nil
gitlab['gitlab-rails']['redis_sentinels'] = [
  {'host' => '10.10.10.1', 'port' => 26379},
  {'host' => '10.10.10.2', 'port' => 26379},
  {'host' => '10.10.10.3', 'port' => 26379}
]
```

After the change run the reconfigure command:

```bash
sudo gitlab-ctl reconfigure

```

## Configure your own Redis server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for Redis. For example, AWS offers a managed ElastiCache service
that runs Redis.

> **Note:** Redis does not require authentication by default. See
  [Redis Security](http://redis.io/topics/security) documentation for more
  information. We recommend using a combination of a Redis password and tight
  firewall rules to secure your Redis service.

## Configure using Omnibus

1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL.

    ```ruby
      external_url 'https://gitlab.example.com'

      # Disable all components except Redis
      redis['enable'] = true
      bootstrap['enable'] = false
      nginx['enable'] = false
      unicorn['enable'] = false
      sidekiq['enable'] = false
      postgresql['enable'] = false
      gitlab_workhorse['enable'] = false
      mailroom['enable'] = false

      # Redis configuration
      redis['port'] = 6379
      redis['bind'] = '0.0.0.0'

      # If you wish to use Redis authentication (recommended)
      redis['password'] = 'Redis Password'
    ```

1. Run `sudo gitlab-ctl reconfigure` to install and configure PostgreSQL.

    > **Note**: This `reconfigure` step will result in some errors.
      That's OK - don't be alarmed.
1. Run `touch /etc/gitlab/skip-auto-migrations` to prevent database migrations
   from running on upgrade. Only the primary GitLab application server should
   handle migrations.

---

Read more on high-availability configuration:

1. [Configure the database](database.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
