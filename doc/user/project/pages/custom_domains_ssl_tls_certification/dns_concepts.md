---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages DNS records
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

A Domain Name System (DNS) web service routes visitors to websites
by translating domain names (such as `www.example.com`) into the
numeric IP addresses (such as `192.0.2.1`) that computers use to
connect to each other.

A DNS record is created to point a (sub)domain to a certain location,
which can be an IP address or another domain. In case you want to use
GitLab Pages with your own (sub)domain, you need to access your domain's
registrar control panel to add a DNS record pointing it back to your
GitLab Pages site.

How to add DNS records depends on which server your domain
is hosted on. Every control panel has its own place to do it. If you are
not an administrator of your domain, and don't have access to your registrar,
you must ask the technical support of your hosting service
to do it for you.

To help you out, we've gathered some instructions on how to do that
for the most popular hosting services:

<!-- vale gitlab_base.Spelling = NO -->

- [123-reg](https://www.123-reg.co.uk/support/domains/domain-name-server-dns-management-guide/)
- [Amazon](https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html)
- [Bluehost](https://www.bluehost.com/help/article/dns-management-add-edit-or-delete-dns-entries)
- [Cloudflare](https://developers.cloudflare.com/fundamentals/setup/)
- [cPanel](https://docs.cpanel.net/cpanel/domains/zone-editor/)
- [DigitalOcean](https://docs.digitalocean.com/products/networking/dns/how-to/manage-records/)
- [DreamHost](https://help.dreamhost.com/hc/en-us/articles/360035516812)
- [Gandi](https://docs.gandi.net/en/domain_names/faq/dns_records.html)
- [Go Daddy](https://www.godaddy.com/help/add-an-a-record-19238)
- [Hostgator](https://www.hostgator.com/help/article/changing-dns-records)
- [Inmotion hosting](https://www.inmotionhosting.com/support/edu/cpanel/how-do-i-make-custom-dns-records/)
- [Microsoft](https://learn.microsoft.com/en-us/windows-server/networking/dns/manage-resource-records?tabs=powershell)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/subcategory/2237/host-records-setup/)

<!-- vale gitlab_base.Spelling = YES -->

If your hosting service is not listed above, you can just try to
search the web for `how to add dns record on <my hosting service>`.

## `A` record

A DNS `A` record maps a host to an IPv4 IP address.
It points a root domain as `example.com` to the host's IP address as
`192.192.192.192`.

Example:

- `example.com` => `A` => `192.192.192.192`

## `CNAME` record

`CNAME` records define an alias for canonical name for your server (one defined
by an `A` record). It points a subdomain to another domain.

Example:

- `www` => `CNAME` => `example.com`

This way, visitors visiting `www.example.com` are redirected to
`example.com`.

## `MX` record

MX records are used to define the mail exchanges that are used for the domain.
This helps email messages arrive at your mail server correctly.

Example:

- `MX` => `mail.example.com`

Then you can register emails for `users@mail.example.com`.

## `TXT` record

A `TXT` record can associate arbitrary text with a host or other name. A common
use is for site verification.

Example:

- `example.com`=> `TXT` => `"google-site-verification=6P08Ow5E-8Q0m6vQ7FMAqAYIDprkVV8fUf_7hZ4Qvc8"`

This way, you can verify the ownership for that domain name.

## All combined

You can have one DNS record or more than one combined:

- `example.com` => `A` => `192.192.192.192`
- `www` => `CNAME` => `example.com`
- `MX` => `mail.example.com`
- `example.com`=> `TXT` => `"google-site-verification=6P08Ow5E-8Q0m6vQ7FMAqAYIDprkVV8fUf_7hZ4Qvc8"`
