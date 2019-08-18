---
type: reference
---

# Rate limits on raw endpoints **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/30829) in GitLab 12.2.

This setting allows you to rate limit the requests to raw endpoints, defaults to `300` requests per minute. 
It can be modified in **Admin Area > Network > Performance Optimization**.

For example, requests over `300` per minute to `https://gitlab.com/gitlab-org/gitlab-ce/raw/master/app/controllers/application_controller.rb` will be blocked. Access to the raw file will be released after 1 minute.

![Rate limits on raw endpoints](img/rate_limits_on_raw_endpoints.png)

This limit is:

- Applied independently per project, per commit and per file path.
- Not applied per IP address.
- Active by default. To disable, set the option to `0`.

Requests over the rate limit are logged into `auth.log`.
