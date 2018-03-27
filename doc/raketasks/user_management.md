# User management

## Add user as a developer to all projects

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## Add all users to all projects

Notes:

- admin users are added as masters

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

## Add user as a developer to all groups

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## Add all users to all groups

Notes:

- admin users are added as owners so they can add additional users to the group

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

## Maintain tight control over the number of active users on your GitLab installation

- Enable this setting to keep new users blocked until they have been cleared by the admin (default: false).


```
block_auto_created_users: false
```

## Disable Two-factor Authentication (2FA) for all users

This task will disable 2FA for all users that have it enabled. This can be
useful if GitLab's `config/secrets.yml` file has been lost and users are unable
to login, for example.

```bash
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## Rotate Two-factor Authentication (2FA) encryption key

GitLab stores the secret data enabling 2FA to work in an encrypted database
column. The encryption key for this data is known as `otp_key_base`, and is
stored in `config/secrets.yml`.


If that file is leaked, but the individual 2FA secrets have not, it's possible
to re-encrypt those secrets with a new encryption key. This allows you to change
the leaked key without forcing all users to change their 2FA details.

First, look up the old key. This is in the `config/secrets.yml` file, but
**make sure you're working with the production section**. The line you're
interested in will look like this:

```yaml
production:
  otp_key_base: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```

Next, generate a new secret:

```
# omnibus-gitlab
sudo gitlab-rake secret

# installation from source
bundle exec rake secret RAILS_ENV=production
```

Now you need to stop the GitLab server, back up the existing secrets file and
update the database:

```
# omnibus-gitlab
sudo gitlab-ctl stop
sudo cp config/secrets.yml config/secrets.yml.bak
sudo gitlab-rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key>

# installation from source
sudo /etc/init.d/gitlab stop
cp config/secrets.yml config/secrets.yml.bak
bundle exec rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key> RAILS_ENV=production
```

The `<old key>` value can be read from `config/secrets.yml`; `<new key>` was
generated earlier. The **encrypted** values for the user 2FA secrets will be
written to the specified `filename` - you can use this to rollback in case of
error.

Finally, change `config/secrets.yml` to set `otp_key_base` to `<new key>` and
restart. Again, make sure you're operating in the **production** section.

```
# omnibus-gitlab
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
```

If there are any problems (perhaps using the wrong value for `old_key`), you can
restore your backup of `config/secrets.yml` and rollback the changes:

```
# omnibus-gitlab
sudo gitlab-ctl stop
sudo gitlab-rake gitlab:two_factor:rotate_key:rollback filename=backup.csv
sudo cp config/secrets.yml.bak config/secrets.yml
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
bundle exec rake gitlab:two_factor:rotate_key:rollback filename=backup.csv RAILS_ENV=production
cp config/secrets.yml.bak config/secrets.yml
sudo /etc/init.d/gitlab start

```
