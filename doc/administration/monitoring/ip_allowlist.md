---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IP allowlist
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides some [monitoring endpoints](health_check.md)
that provide health check information when probed.

To control access to those endpoints through IP allowlisting, you can add single
hosts or use IP ranges:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Open `/etc/gitlab/gitlab.rb` and add or uncomment the following:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab for the changes to take effect.

:::TabTitle Helm chart (Kubernetes)

You can set the required IPs under the `gitlab.webservice.monitoring.ipWhitelist` key. For example:

```yaml
gitlab:
   webservice:
      monitoring:
         # Monitoring IP allowlist
         ipWhitelist:
         - 0.0.0.0/0 # Default
```

:::TabTitle Self-compiled (source)

1. Edit `config/gitlab.yml`:

   ```yaml
   monitoring:
     # by default only local IPs are allowed to access monitoring resources
     ip_whitelist:
       - 127.0.0.0/8
       - 192.168.0.1
   ```

1. Save the file and [restart](../restart_gitlab.md#self-compiled-installations) GitLab for the changes to take effect.

::EndTabs
