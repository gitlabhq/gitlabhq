# Configuring Gitaly for Scaled and High Availability

Gitaly does not yet support full high availability. However, Gitaly is quite
stable and is in use on GitLab.com. Scaled and highly available GitLab environments
should consider using Gitaly on a separate node. 

See the [Gitaly HA Epic](https://gitlab.com/groups/gitlab-org/-/epics/289) to 
track plans and progress toward high availability support. 

This document is relevant for [Scaled Architecture](./README.md#scalable-architecture-examples)
environments and [High Availability Architecture](./README.md#high-availability-architecture-examples). 

## Running Gitaly on its own server

Starting with GitLab 11.4, Gitaly is a replacement for NFS except
when the [Elastic Search indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer)
is used.

NOTE: **Note:** While Gitaly can be used as a replacement for NFS, we do not recommend using EFS as it may impact GitLab's performance. Please review the [relevant documentation](nfs.md#avoid-using-awss-elastic-file-system-efs) for more details.

NOTE: **Note:** Gitaly network traffic is unencrypted so we recommend a firewall to
restrict access to your Gitaly server.

The steps below are the minimum necessary to configure a Gitaly server with
Omnibus:

1. SSH into the Gitaly server.
1. [Download/install](https://about.gitlab.com/installation) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
     - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

    Gitaly must trigger some callbacks to GitLab via GitLab Shell. As a result,
    the GitLab Shell secret must be the same between the other GitLab servers and
    the Gitaly server. The easiest way to accomplish this is to copy `/etc/gitlab/gitlab-secrets.json`
    from an existing GitLab server to the Gitaly server. Without this shared secret,
    Git operations in GitLab will result in an API error.

    > **NOTE:** In most or all cases the storage paths below end in `repositories` which is
    different than `path` in `git_data_dirs` of Omnibus installations. Check the
    directory layout on your Gitaly server to be sure.

    ```ruby
    # Enable Gitaly
    gitaly['enable'] = true

    ## Disable all other services
    sidekiq['enable'] = false
    gitlab_workhorse['enable'] = false
    unicorn['enable'] = false
    postgresql['enable'] = false
    nginx['enable'] = false
    prometheus['enable'] = false
    alertmanager['enable'] = false
    pgbouncer_exporter['enable'] = false
    redis_exporter['enable'] = false
    gitlab_monitor['enable'] = false

    # Prevent database connections during 'gitlab-ctl reconfigure'
    gitlab_rails['rake_cache_clear'] = false
    gitlab_rails['auto_migrate'] = false

    # Configure the gitlab-shell API callback URL. Without this, `git push` will
    # fail. This can be your 'front door' GitLab URL or an internal load
    # balancer.
    gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

    # Make Gitaly accept connections on all network interfaces. You must use
    # firewalls to restrict access to this address/port.
    gitaly['listen_addr'] = "0.0.0.0:8075"
    gitaly['auth_token'] = 'abc123secret'

    gitaly['storage'] = [
      { 'name' => 'default', 'path' => '/mnt/gitlab/default/repositories' },
      { 'name' => 'storage1', 'path' => '/mnt/gitlab/storage1/repositories' },
    ]

    # To use tls for gitaly you need to add
    gitaly['tls_listen_addr'] = "0.0.0.0:9999"
    gitaly['certificate_path'] = "path/to/cert.pem"
    gitaly['key_path'] = "path/to/key.pem"
    ```

Again, reconfigure (Omnibus) or restart (source).

Continue configuration of other components by going back to:

- [Scaled Architectures](./README.md#scalable-architecture-examples)
- [High Availability Architectures](./README.md#high-availability-architecture-examples)
