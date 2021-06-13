---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Rack Attack initializer **(FREE SELF)**

[Rack Attack](https://github.com/kickstarter/rack-attack), also known as Rack::Attack, is a Ruby gem
that is meant to protect GitLab with the ability to customize throttling and
to block user IP addresses.

You can prevent brute-force passwords attacks, scrapers, or any other offenders
by throttling requests from IP addresses that are making large volumes of requests.
If you find throttling is not enough to protect you against abusive clients,
Rack Attack offers IP whitelisting, blacklisting, Fail2ban style filtering, and
tracking.

For more information on how to use these options see the [Rack Attack README](https://github.com/kickstarter/rack-attack/blob/master/README.md).

NOTE:
See
[User and IP rate limits](../user/admin_area/settings/user_and_ip_rate_limits.md)
for simpler limits that are configured in the UI.

NOTE:
Starting with GitLab 11.2, Rack Attack is disabled by default. If your
instance is not exposed to the public internet, it is recommended that you leave
Rack Attack disabled.

## Behavior

If set up as described in the [Settings](#settings) section below, two behaviors
are enabled:

- Protected paths are throttled.
- Failed authentications for Git and container registry requests trigger a temporary IP ban.

### Protected paths throttle

GitLab responds with HTTP status code `429` to POST requests at protected paths
that exceed 10 requests per minute per IP address.

By default, protected paths are:

- `/users/password`
- `/users/sign_in`
- `/api/#{API::API.version}/session.json`
- `/api/#{API::API.version}/session`
- `/users`
- `/users/confirmation`
- `/unsubscribes/`
- `/import/github/personal_access_token`
- `/admin/session`

See [User and IP rate limits](../user/admin_area/settings/user_and_ip_rate_limits.md#response-headers) for the headers responded to blocked requests.

For example, the following are limited to a maximum 10 requests per minute:

- User sign-in
- User sign-up (if enabled)
- User password reset

After 10 requests, the client must wait a minute before it can
try again.

### Git and container registry failed authentication ban

GitLab responds with HTTP status code `403` for 1 hour, if 30 failed
authentication requests were received in a 3-minute period from a single IP address.

This applies only to Git requests and container registry (`/jwt/auth`) requests
(combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 29
  failed authentication requests followed by 1 successful request, followed by 29
  more failed authentication requests would not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

## Settings

**Omnibus GitLab**

1. Open `/etc/gitlab/gitlab.rb` with your editor
1. Add the following:

   ```ruby
   gitlab_rails['rack_attack_git_basic_auth'] = {
     'enabled' => true,
     'ip_whitelist' => ["127.0.0.1"],
     'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
     'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
     'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

The following settings can be configured:

- `enabled`: By default this is set to `false`. Set this to `true` to enable Rack Attack.
- `ip_whitelist`: Whitelist any IPs from being blocked. They must be formatted as strings within a Ruby array.
  CIDR notation is supported in GitLab v12.1 and up.
  For example, `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`.
- `maxretry`: The maximum amount of times a request can be made in the
  specified time.
- `findtime`: The maximum amount of time that failed requests can count against an IP
  before it's blacklisted (in seconds).
- `bantime`: The total amount of time that a blacklisted IP is blocked (in
  seconds).

**Installations from source**

These settings can be found in `config/initializers/rack_attack.rb`. If you are
missing `config/initializers/rack_attack.rb`, the following steps need to be
taken in order to enable protection for your GitLab instance:

1. In `config/application.rb` find and uncomment the following line:

   ```ruby
   config.middleware.use Rack::Attack
   ```

1. Restart GitLab:

   ```shell
   sudo service gitlab restart
   ```

If you want more restrictive/relaxed throttle rules, edit
`config/initializers/rack_attack.rb` and change the `limit` or `period` values.
For example, you can set more relaxed throttle rules with
`limit: 3` and `period: 1.seconds`, allowing 3 requests per second.
You can also add other paths to the protected list by adding to `paths_to_be_protected`
variable. If you change any of these settings you must restart your
GitLab instance.

## Remove blocked IPs from Rack Attack via Redis

In case you want to remove a blocked IP, follow these steps:

1. Find the IPs that have been blocked in the production log:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. Since the blacklist is stored in Redis, you need to open up `redis-cli`:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. You can remove the block using the following syntax, replacing `<ip>` with
   the actual IP that is blacklisted:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. Confirm that the key with the IP no longer shows up:

   ```plaintext
   keys *rack::attack*
   ```

1. Optionally, add the IP to the whitelist to prevent it from being blacklisted
   again (see [settings](#settings)).

## Troubleshooting

### Rack attack is blacklisting the load balancer

Rack Attack may block your load balancer if all traffic appears to come from
the load balancer. In that case, you must:

1. [Configure `nginx[real_ip_trusted_addresses]`](https://docs.gitlab.com/omnibus/settings/nginx.html#configuring-gitlab-trusted_proxies-and-the-nginx-real_ip-module).
   This keeps users' IPs from being listed as the load balancer IPs.
1. Whitelist the load balancer's IP address(es) in the Rack Attack [settings](#settings).
1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [Remove the block via Redis.](#remove-blocked-ips-from-rack-attack-via-redis)
