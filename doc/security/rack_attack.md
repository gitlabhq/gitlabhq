---
type: reference, howto
---
# Rack Attack

[Rack Attack](https://github.com/kickstarter/rack-attack), also known as Rack::Attack, is a Ruby gem
that is meant to protect GitLab with the ability to customize throttling and
to block user IP addresses.

You can prevent brute-force passwords attacks, scrapers, or any other offenders
by throttling requests from IP addresses that are making large volumes of requests.
If you find throttling is not enough to protect you against abusive clients,
Rack Attack offers IP whitelisting, blacklisting, Fail2ban style filtering, and
tracking.

**Note:** Starting with 11.2, Rack Attack is disabled by default. To continue
using Rack Attack, please enable it by [configuring `gitlab.rb` as described in Settings](#settings).

By default, user sign-in, user sign-up (if enabled), and user password reset is
limited to 6 requests per minute. After trying for 6 times, the client will
have to wait for the next minute to be able to try again.

If you installed or upgraded GitLab by following the [official guides](../install/README.md),
Rack Attack should be disabled by default. If your instance is not exposed to any incoming
connections, it is recommended that you leave Rack Attack disabled.

For more information on how to use these options check out
[rack-attack README](https://github.com/kickstarter/rack-attack/blob/master/README.md).

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

    ```
    sudo gitlab-ctl reconfigure
    ```

The following settings can be configured:

- `enabled`: By default this is set to `false`. Set this to `true` to enable Rack Attack.
- `ip_whitelist`: Whitelist any IPs from being blocked. They must be formatted as strings within a ruby array.
   For example, `["127.0.0.1", "127.0.0.2", "127.0.0.3"]`.
- `maxretry`: The maximum amount of times a request can be made in the
   specified time.
- `findtime`: The maximum amount of time that failed requests can count against an IP
   before it's blacklisted (in seconds).
- `bantime`: The total amount of time that a blacklisted IP will be blocked (in
   seconds).

**Installations from source**

These settings can be found in `config/initializers/rack_attack.rb`. If you are
missing `config/initializers/rack_attack.rb`, the following steps need to be
taken in order to enable protection for your GitLab instance:

1. In `config/application.rb` find and uncomment the following line:

    ```ruby
    config.middleware.use Rack::Attack
    ```

1. Copy `config/initializers/rack_attack.rb.example` to `config/initializers/rack_attack.rb`
1. Open `config/initializers/rack_attack.rb`, review the
   `paths_to_be_protected`, and add any other path you need protecting
1. Restart GitLab:

    ```sh
    sudo service gitlab restart
    ```

If you want more restrictive/relaxed throttle rules, edit
`config/initializers/rack_attack.rb` and change the `limit` or `period` values.
For example, more relaxed throttle rules will be if you set
`limit: 3` and `period: 1.seconds` (this will allow 3 requests per second).
You can also add other paths to the protected list by adding to `paths_to_be_protected`
variable. If you change any of these settings do not forget to restart your
GitLab instance.

## Remove blocked IPs from Rack Attack via Redis

In case you want to remove a blocked IP, follow these steps:

1. Find the IPs that have been blocked in the production log:

    ```sh
    grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
    ```

1. Since the blacklist is stored in Redis, you need to open up `redis-cli`:

    ```sh
    /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
    ```

1. You can remove the block using the following syntax, replacing `<ip>` with
   the actual IP that is blacklisted:

    ```
    del cache:gitlab:rack::attack:allow2ban:ban:<ip>
    ```

1. Confirm that the key with the IP no longer shows up:

    ```
    keys *rack::attack*
    ```

1. Optionally, add the IP to the whitelist to prevent it from being blacklisted
   again (see [settings](#settings)).

## Troubleshooting

### Rack attack is blacklisting the load balancer

Rack Attack may block your load balancer if all traffic appears to come from
the load balancer. In that case, you will need to:

1. [Configure `nginx[real_ip_trusted_addresses]`](https://docs.gitlab.com/omnibus/settings/nginx.html#configuring-gitlab-trusted_proxies-and-the-nginx-real_ip-module).
   This will keep users' IPs from being listed as the load balancer IPs.
1. Whitelist the load balancer's IP address(es) in the Rack Attack [settings](#settings).
1. Reconfigure GitLab:

    ```
    sudo gitlab-ctl reconfigure
    ```

1. [Remove the block via Redis.](#remove-blocked-ips-from-rack-attack-via-redis)
