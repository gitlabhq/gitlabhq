---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate from a relative URL to a subdomain
description: Reconfigure a GitLab instance to use a subdomain instead of a relative URL.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can migrate GitLab from a relative URL configuration to a subdomain deployment.

The downtime during migration depends on your deployment architecture and load balancer configuration:

- GitLab upgrade downtime: For single-node installations, reconfiguring GitLab requires downtime. For multi-node installations with load balancing, you can follow the [zero-downtime upgrade](../../update/zero_downtime.md) process to minimize downtime by updating nodes sequentially.
- User-facing downtime during URL switch: The impact depends on your load balancer and DNS configuration. Before applying the GitLab configuration changes, you can configure your load balancer or DNS to route both the old and new URLs to the same backend, minimizing user-facing disruption during the transition.

> [!warning]
> GitLab must be configured with the actual URL it will use. You cannot configure GitLab for one URL and use a load balancer to present a different URL to users
> because GitLab generates absolute URLs internally for API responses, emails, and UI elements.

## Migrate to a subdomain

To migrate from a relative URL to a subdomain:

1. Update your GitLab configuration to disable the relative URL configuration based on your installation type.

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

      Edit `/etc/gitlab/gitlab.rb` and update `external_url` to use the new subdomain:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

      Update the [`global.hosts`](https://docs.gitlab.com/charts/charts/globals/#configure-host-settings) configuration to use your new subdomain.

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

      Follow [Disable relative URL in GitLab](../../install/relative_url.md#disable-relative-url-in-gitlab).

   {{< /tab >}}

   {{< /tabs >}}

1. To apply the new subdomain configuration, follow the upgrade process for [upgrading a GitLab instance](../../update/_index.md) applicable to your installation type.
1. Changing the URL changes all remote URLs, so you must manually edit them in any local repository that points to your GitLab instance. Any local repositories cloned while using the relative URL have remote URLs pointing to the old path, and users must manually update these.
1. If you must preserve existing links during a transition period, [configure your load balancer to redirect](#configure-load-balancer-redirects) legacy relative URLs to the new subdomain.

## Configure load balancer redirects

After migrating GitLab from a relative URL to a subdomain, configure your load balancer to redirect old relative URLs to the new subdomain:

1. Ensure your load balancer has SSL certificates for both the old and new domains.
1. Configure DNS to resolve both domains to your load balancer.
1. Add redirect rules to your load balancer configuration that:
   - Detect requests to the old domain with paths starting with the relative URL prefix (for example, `/gitlab/`).
   - Redirect the requests to the new subdomain with a 301 (permanent redirect) status.
   - Preserve the path and query parameters by removing the relative URL prefix from the beginning of the path.
1. If you have GitLab components with separate URL configurations (like the Container Registry or Pages), add similar redirect rules for those paths.
