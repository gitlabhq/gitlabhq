# IP whitelist

> Introduced in GitLab 9.4.

GitLab provides some [monitoring endpoints] that provide health check information
when probed.

To control access to those endpoints via IP whitelisting, you can add single
hosts or use IP ranges:

**For Omnibus installations**

1. Open `/etc/gitlab/gitlab.rb` and add or uncomment the following:

    ```ruby
    gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
    ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.

---

**For installations from source**

1. Edit `config/gitlab.yml`:

    ```yaml
    monitoring:
      # by default only local IPs are allowed to access monitoring resources
      ip_whitelist:
        - 127.0.0.0/8
        - 192.168.0.1
    ```

1. Save the file and [restart] GitLab for the changes to take effect.

[reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../restart_gitlab.md#installations-from-source
[monitoring endpoints]: ../../user/admin_area/monitoring/health_check.md
