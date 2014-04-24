# Rack attack

To prevent abusive clients doing damage GitLab uses rack-attack gem.

If you installed or upgraded GitLab by following the official guides this should be enabled by default.

If you are missing `config/initializers/rack_attack.rb` the following steps need to be taken in order to enable protection for your GitLab instance:

1.  In config/application.rb find and uncomment the following line:

        config.middleware.use Rack::Attack

1.  Rename `config/initializers/rack_attack.rb.example` to `config/initializers/rack_attack.rb`.

1.  Review the `paths_to_be_protected` and add any other path you need protecting.

1.  Restart GitLab instance.

By default, user sign-in, user sign-up(if enabled) and user password reset is limited to 6 requests per minute. After trying for 6 times, client will have to wait for the next minute to be able to try again. These settings can be found in `config/initializers/rack_attack.rb`

If you want more restrictive/relaxed throttle rule change the `limit` or `period` values. For example, more relaxed throttle rule will be if you set limit: 3 and period: 1.second(this will allow 3 requests per second). You can also add other paths to the protected list by adding to `paths_to_be_protected` variable. If you change any of these settings do not forget to restart your GitLab instance.

In case you find throttling is not enough to protect you against abusive clients, rack-attack gem offers IP whitelisting, blacklisting, Fail2ban style filter and tracking.

For more information on how to use these options check out [rack-attack README](https://github.com/kickstarter/rack-attack/blob/master/README.md).
