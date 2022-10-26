---
stage: Data Stores
group: Application Performance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# IP whitelist **(FREE SELF)**

GitLab provides some [monitoring endpoints](../../user/admin_area/monitoring/health_check.md)
that provide health check information when probed.

To control access to those endpoints via IP whitelisting, you can add single
hosts or use IP ranges:

**Omnibus**

1. Open `/etc/gitlab/gitlab.rb` and add or uncomment the following:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

---

**Helm chart**

You can set the required IPs under the `gitlab.webservice.monitoring.ipWhitelist` key. For example:

```yaml
gitlab:
   webservice:
      monitoring:
         # Monitoring IP whitelist
         ipWhitelist:
         - 0.0.0.0/0 # Default
```

---

**Source**

1. Edit `config/gitlab.yml`:

   ```yaml
   monitoring:
     # by default only local IPs are allowed to access monitoring resources
     ip_whitelist:
       - 127.0.0.0/8
       - 192.168.0.1
   ```

1. Save the file and [restart](../restart_gitlab.md#installations-from-source) GitLab for the changes to take effect.
