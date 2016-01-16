# DNS-based Blackhole List

_**Note:** This feature was [introduced][ce-2455] in GitLab 8.4._

---

GitLab supports a DNSBL mechanism which checks for blacklisted IPs during
sign-up. In conjunction with [reCAPTCHA](../integration/recaptcha.md), it
serves as a mean to fight against spam on GitLab instances that have public
sign-up enabled.

Excerpt from [Wikipedia][wiki-dnsbl]:

> A DNS-based Blackhole List (DNSBL) or Real-time Blackhole List (RBL) is an
> effort to stop email spamming. It is a "blacklist" of locations on the
> Internet reputed to send email spam. The locations consist of IP addresses
> which are most often used to publish the addresses of computers or networks
> linked to spamming; most mail server software can be configured to reject or
> flag messages which have been sent from a site listed on one or more such
> lists. The term "Blackhole List" is sometimes interchanged with the term
> "blacklist" and "blocklist".

## How DNSBL works

| Attribute | Description |
| --------- | ----------- |
| threshold | |
| domain    | |
| weight    | |

## Enable DNSBL

The configuration is done via `gitlab.yml` and access to the server that hosts
GitLab is required.

### Enable DNSBL on source installations

Make sure your `/home/git/gitlab/config/gitlab.yml` is updated and then edit it
to match your preferences (see [How DNSBL works](#how-dnsbl-works)).

There are some defaults in place which you can use as-is. The minimal change
you need to do, is set `enabled` to `true`:

```yaml
dnsbl_check:
  enabled: true
  treshold: 0.3
  lists:
    - domain: list.blogspambl.com
      weight: 6
    - domain: all.s5h.net
      weight: 4
```

### Enable DNSBL on Omnibus installations


[ce-2455]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2455
[wiki-dnsbl]: https://en.wikipedia.org/wiki/DNSBL "Wikipedia on DNS-based Blackhole Lists"
