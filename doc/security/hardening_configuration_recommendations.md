---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - Configuration Recommendations
---

General hardening guidelines are outlined in the [main hardening documentation](hardening.md).

Some hardening recommendations for GitLab instances involve additional
services or control through configuration files. As a reminder, any time you are
making changes to configuration files, make backup copies of
them before editing. Additionally, if you are making a lot of changes it is
recommended you do not do all of the changes at once, and test them after each
change to ensure everything is working.

## NGINX

NGINX is used to serve up the web interface used to access the GitLab instance. As
NGINX is controlled and integrated into GitLab, modification of the
`/etc/gitlab/gitlab.rb` file used for adjustments. Here are a few recommendations for helping to improve
the security of NGINX itself:

1. Create the [Diffie-Hellman key](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_dhparam):

   ```shell
   sudo openssl dhparam -out /etc/gitlab/ssl/dhparam.pem 4096
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   #
   # Only strong ciphers are used
   #
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"
   #
   # Follow preferred ciphers and the order listed as preference
   #
   nginx['ssl_prefer_server_ciphers'] = "on"
   #
   # Only allow TLSv1.2 and TLSv1.3
   #
   nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"

   ##! **Recommended in: https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_cache'] = "builtin:1000  shared:SSL:10m"

   ##! **Default according to https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_timeout'] = "5m"

   # Should prevent logjam attack etc
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparam.pem" # changed from nil

   # Turn off session ticket reuse
   nginx['ssl_session_tickets'] = "off"
   # Pick our own curve instead of what openssl hands us
   nginx['ssl_ecdh_curve'] = "secp384r1"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Consul

Consul can be integrated into a GitLab environment, and is intended for larger
deployments. In general for self-managed and standalone deployments with less than
1000 users, Consul may not be needed. If it is needed, first review the
[documentation on Consul](../administration/consul.md), but
more importantly ensure that encryption is used during communications. For more
detailed information on Consul visit the
[HashiCorp website](https://developer.hashicorp.com/consul/docs) to understand how it
works, and review the information on
[encryption security](https://developer.hashicorp.com/consul/docs/security/encryption).

## Environment Variables

You can customize multiple
[environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html)
on self-managed systems. The main environment variable to
take advantage of from a security perspective is `GITLAB_ROOT_PASSWORD` during the
installation process. If you are installing the self-managed system with a
public-facing IP address exposed to the Internet, make sure the password is set to
something strong. Historically, setting up any type of public-facing service - whether
it is GitLab or some other application - has shown that opportunistic attacks occur
as soon as those systems are discovered, so the hardening process should start during
the installation process.

As mentioned in the [operating system recommendations](hardening_operating_system_recommendations.md)
ideally there should be firewall rules already in place before the GitLab
installation begins, but you should still set a secure password before the
installation through `GITLAB_ROOT_PASSWORD`.

## Git Protocols

To ensure that only authorized users are using SSH for Git access, add the following
to your `/etc/ssh/sshd_config` file:

```shell
# Ensure only authorized users are using Git
AcceptEnv GIT_PROTOCOL
```

This ensures that users cannot pull down projects using SSH unless they have a valid
GitLab account that can perform `git` operations over SSH. More details can be found
under [Configuring Git Protocol](../administration/git_protocol.md).

## Incoming Email

You can configure GitLab Self-Managed to allow for incoming email to be
used for commenting or creating issues and merge requests by registered users on
the GitLab instance. In a hardened environment you should not configure
this feature as it involves outside communications sending in information.

If the feature is required, follow the instructions in the
[incoming email documentation](../administration/incoming_email.md), with
the following recommendations to ensure maximum security:

- Dedicate an email address specifically for inbound emails to the instance.
- Use [email sub-addressing](../administration/incoming_email.md).
- Email accounts used by users to send emails should require and have multi-factor authentication (MFA) enabled on those accounts.
- For Postfix specifically, follow the [set up Postfix for incoming email documentation](../administration/reply_by_email_postfix_setup.md).

## Redis Replication and Failover

Redis is used on a Linux package installation for replication and failover, and can be
set up when scaling requires that capability. Bear in mind that this opens TCP ports
`6379` for Redis and `26379` for Sentinel. Follow the
[replication and failover documentation](../administration/redis/replication_and_failover.md)
but note the IP addresses of all of the nodes, and set up firewall rules between
nodes that only allow the other node to access those particular ports.

## Sidekiq Configuration

In the [instructions for configuring an external Sidekiq](../administration/sidekiq/_index.md)
there are numerous references to configuring IP ranges. You must
[configure HTTPS](../administration/sidekiq/_index.md#enable-https),
and consider restricting those IP addresses to specific systems that Sidekiq talks to.
You might have to adjust firewall rules at the operating system level as well.

## S/MIME Signing of Email

If the GitLab instance is configured for sending out email notifications to users,
configure S/MIME signing to help the recipients ensure that the emails are
legitimate. Follow the instructions on [signing outgoing email](../administration/smime_signing_email.md).

## Container registry

If Lets Encrypt is configured, the container registry is enabled by default. This
allows projects to store their own Docker images. Follow the instructions for
configuring the [container registry](../administration/packages/container_registry.md),
so you can do things like restrict automatic enablement on new projects and
disabling the container registry entirely. You may have to adjust firewall rules to
allow access - if a completely standalone system, you should restrict access to the
Container Registry to localhost only. Specific examples of ports used and their
configuration are also included in the documentation.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
