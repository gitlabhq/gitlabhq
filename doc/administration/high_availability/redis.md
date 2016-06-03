# Configuring Redis for GitLab HA

You can choose to install and manage Redis yourself, or you can use GitLab
Omnibus packages to help.

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

      # Disable all components except PostgreSQL
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
