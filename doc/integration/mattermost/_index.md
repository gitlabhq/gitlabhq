---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Mattermost
---

DETAILS:
**Offering:** GitLab Self-Managed

You can run a [GitLab Mattermost](https://gitlab.com/gitlab-org/gitlab-mattermost)
service on your GitLab server. Mattermost is not part of the single application that GitLab is. There is a good integration between [Mattermost and GitLab](https://mattermost.com/solutions/mattermost-gitlab/), and our Linux package allows you to install it. **However, Mattermost is a separate application from a separate company.** GitLab Support cannot help you with Mattermost-specific questions beyond the integration with GitLab. If you need help with Mattermost itself, see the [community support resources](#community-support-resources).

## Prerequisites

Each release of GitLab Mattermost is compiled and manually tested on an AMD 64 chipset for Linux. ARM chipsets and operating systems, like Raspberry Pi, are not supported.

## Getting started

GitLab Mattermost expects to run on its own virtual host. In your DNS settings, you need
two entries pointing to the same machine. For example, `gitlab.example.com` and
`mattermost.example.com`.

GitLab Mattermost is disabled by default. To enable it:

1. Edit `/etc/gitlab/gitlab.rb` and add the Mattermost external URL:

   ```ruby
   mattermost_external_url 'https://mattermost.example.com'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Confirm that GitLab Mattermost is reachable at `https://mattermost.example.com` and authorized to connect to GitLab. Authorizing Mattermost with GitLab allows users to use GitLab as an SSO provider.

The Linux package attempts to automatically authorize GitLab Mattermost with GitLab if the applications are running on the same server.

Automatic authorization requires access to the GitLab database. If the GitLab database is not available
you need to manually authorize GitLab Mattermost for access to GitLab using the process described in the [Authorize GitLab Mattermost section](#authorize-gitlab-mattermost).

## Configuring Mattermost

Mattermost can be configured using the Mattermost System Console. An extensive list of
Mattermost settings and where they can be set is available [in the Mattermost documentation](https://docs.mattermost.com/administration/config-settings.html).

While using the System Console is recommended, you can also configure Mattermost using one of the following options:

1. Edit the Mattermost configuration directly through `/var/opt/gitlab/mattermost/config.json`.
1. Specify environment variables used to run Mattermost by changing the `mattermost['env']` setting in `gitlab.rb`. Any settings configured in this way are disabled from the System Console and cannot be changed without restarting Mattermost.

## Running GitLab Mattermost with HTTPS

Place the SSL certificate and SSL certificate key inside `/etc/gitlab/ssl`. If the directory doesn't exist, create it:

```shell
sudo mkdir -p /etc/gitlab/ssl
sudo chmod 755 /etc/gitlab/ssl
sudo cp mattermost.gitlab.example.key mattermost.gitlab.example.crt /etc/gitlab/ssl/
```

In `/etc/gitlab/gitlab.rb` specify the following configuration:

```ruby
mattermost_external_url 'https://mattermost.gitlab.example'
mattermost_nginx['redirect_http_to_https'] = true
```

If you haven't named your certificate and key `mattermost.gitlab.example.crt`
and `mattermost.gitlab.example.key` then you need to also add the full paths
as shown below.

```ruby
mattermost_nginx['ssl_certificate'] = "/etc/gitlab/ssl/mattermost-nginx.crt"
mattermost_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/mattermost-nginx.key"
```

where `mattermost-nginx.crt` is the SSL certificate and `mattermost-nginx.key` is the SSL key.

Once the configuration is set, run `sudo gitlab-ctl reconfigure` to apply the changes.

## Running GitLab Mattermost with an external PostgreSQL service

By default, Mattermost uses the Linux package bundled PostgreSQL service. If you want to use Mattermost with an external PostgreSQL service, it requires its own specific configuration. An existing [external PostgreSQL connection configuration used by GitLab](../../administration/postgresql/external.md) is not automatically inherited for Mattermost.

1. Edit `/etc/gitlab/gitlab.rb` and specify the following configuration:

   ```ruby
   mattermost['sql_driver_name'] = 'postgres'
   mattermost['sql_data_source'] = "user=gitlab_mattermost host=<hostname-of-postgresql-service> port=5432 sslmode=required dbname=<mattermost_production> password=<user-password>"
   ```

1. Create a PostgreSQL user matching the `user` value, and `password` value that you have defined in `mattermost['sql_data_source']`.
1. Create a PostgreSQL database matching the `dbname` value that was used.
1. Ensure that the `user` has permissions to the database that was created with `dbname`.

1. Reconfigure GitLab and restart Mattermost to apply the changes:

   ```shell
   sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart mattermost
   ```

## Running GitLab Mattermost on its own server

If you want to run GitLab and GitLab Mattermost on two separate servers the GitLab services are still set up on your GitLab Mattermost server, but they do not accept user requests or
consume system resources. You can use the following settings and configuration details on the GitLab Mattermost server to effectively disable the GitLab service bundled into the Linux package.

```ruby
mattermost_external_url 'http://mattermost.example.com'

# Shut down GitLab services on the Mattermost server
gitlab_rails['enable'] = false
redis['enable'] = false
postgres_exporter['enable'] = false
grafana['enable'] = false
```

Then follow the appropriate steps in the [Authorize GitLab Mattermost section](#authorize-gitlab-mattermost). Last, to enable
integrations with GitLab add the following on the GitLab Server:

```ruby
gitlab_rails['mattermost_host'] = "https://mattermost.example.com"
```

By default GitLab Mattermost requires all users to sign up with GitLab and disables the sign-up by email option. See Mattermost [documentation on GitLab SSO](https://docs.mattermost.com/deployment/sso-gitlab.html).

## Manually (re)authorizing GitLab Mattermost with GitLab

### Reauthorize GitLab Mattermost

To reauthorize GitLab Mattermost, you first need to revoke the existing
authorization. This can be done in the **Settings > Applications** area of GitLab. Then follow the steps below to complete authorization.

### Authorize GitLab Mattermost

Go to the **Settings > Applications** area in GitLab. Create a new application and for the **Redirect URI** use the following (replace `http` with `https` if you use HTTPS):

```plaintext
http://mattermost.example.com/signup/gitlab/complete
http://mattermost.example.com/login/gitlab/complete
```

Make sure to select the **Trusted** and **Confidential** settings. Under **Scopes**, select `read_user`. Then, choose **Save application**.

Once the application is created you are provided with an `Application ID` and `Secret`. One other piece of information needed is the URL of GitLab instance.
Return to the server running GitLab Mattermost and edit the `/etc/gitlab/gitlab.rb` configuration file as follows using the values you received above:

```ruby
mattermost['gitlab_enable'] = true
mattermost['gitlab_id'] = "12345656"
mattermost['gitlab_secret'] = "123456789"
mattermost['gitlab_scope'] = "read_user"
mattermost['gitlab_auth_endpoint'] = "http://gitlab.example.com/oauth/authorize"
mattermost['gitlab_token_endpoint'] = "http://gitlab.example.com/oauth/token"
mattermost['gitlab_user_api_endpoint'] = "http://gitlab.example.com/api/v4/user"
```

Save the changes and then run `sudo gitlab-ctl reconfigure`. If there are no errors your GitLab and GitLab Mattermost should be configured correctly.

## Specify numeric user and group identifiers

The Linux package creates a user and group `mattermost`. You can specify the
numeric identifiers for these users in `/etc/gitlab/gitlab.rb` as follows:

```ruby
mattermost['uid'] = 1234
mattermost['gid'] = 1234
```

Run `sudo gitlab-ctl reconfigure` to apply the changes.

## Setting custom environment variables

If necessary you can set custom environment variables to be used by Mattermost
via `/etc/gitlab/gitlab.rb`. This can be useful if the Mattermost server
is operated behind a corporate internet proxy. In `/etc/gitlab/gitlab.rb`
supply a `mattermost['env']` with a hash value. For example:

```ruby
mattermost['env'] = {"HTTP_PROXY" => "my_proxy", "HTTPS_PROXY" => "my_proxy", "NO_PROXY" => "my_no_proxy"}
```

Run `sudo gitlab-ctl reconfigure` to apply the changes.

## Connecting to the bundled PostgreSQL database

If you need to connect to the bundled PostgreSQL database and are using the default Linux package database configuration, you can connect as
the PostgreSQL superuser:

```shell
sudo gitlab-psql -d mattermost_production
```

## Back up GitLab Mattermost

GitLab Mattermost is not included in the regular [Linux package backup](../../administration/backup_restore/_index.md) Rake task.

The general Mattermost [backup and disaster recovery](https://docs.mattermost.com/deploy/backup-disaster-recovery.html) documentation can be used as a guide
on what needs to be backed up.

### Back up the bundled PostgreSQL database

If you need to back up the bundled PostgreSQL database and are using the default Linux package database configuration, you can back up using this command:

```shell
sudo -i -u gitlab-psql -- /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql mattermost_production | gzip > mattermost_dbdump_$(date --rfc-3339=date).sql.gz
```

### Back up the `data` directory and `config.json`

Mattermost has a `data` directory and `config.json` file that need to be backed up as well:

```shell
sudo tar -zcvf mattermost_data_$(date --rfc-3339=date).gz -C /var/opt/gitlab/mattermost data config.json
```

## Restore GitLab Mattermost

If you have previously [created a backup of GitLab Mattermost](#back-up-gitlab-mattermost), you can run the following commands to restore it:

```shell
# Stop Mattermost so we don't have any open database connections
sudo gitlab-ctl stop mattermost

# Drop the Mattermost database
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb -U gitlab-psql -h /var/opt/gitlab/postgresql -p 5432 mattermost_production

# Create the Mattermost database
sudo -u gitlab-psql /opt/gitlab/embedded/bin/createdb -U gitlab-psql -h /var/opt/gitlab/postgresql -p 5432 mattermost_production

# Perform the database restore
# Replace /tmp/mattermost_dbdump_2021-08-05.sql.gz with your backup
sudo -u mattermost sh -c "zcat /tmp/mattermost_dbdump_2021-08-05.sql.gz | /opt/gitlab/embedded/bin/psql -U gitlab_mattermost -h /var/opt/gitlab/postgresql -p 5432 mattermost_production"

# Restore the data directory and config.json
# Replace /tmp/mattermost_data_2021-08-09.gz with your backup
sudo tar -xzvf /tmp/mattermost_data_2021-08-09.gz -C /var/opt/gitlab/mattermost

# Fix permissions if required
sudo chown -R mattermost:mattermost /var/opt/gitlab/mattermost/data
sudo chown mattermost:mattermost /var/opt/gitlab/mattermost/config.json

# Start Mattermost
sudo gitlab-ctl start mattermost
```

## Mattermost command-line tool (CLI)

[`mmctl`](https://docs.mattermost.com/manage/mmctl-command-line-tool.html) is a CLI tool for the Mattermost server which is installed locally and uses the Mattermost API, but may also be used remotely. You must configure Mattermost either for local connections or authenticate as an administrator with local login credentials (not through GitLab SSO). The executable is located at `/opt/gitlab/embedded/bin/mmctl`.

### Use `mmctl` through a local connection

For local connections, the `mmctl` binary and Mattermost must be run from the same server. To enable the local socket:

1. Edit `/var/opt/gitlab/mattermost/config.json`, and add the following lines:

   ```json
   {
       "ServiceSettings": {
          ...
           "EnableLocalMode": true,
           "LocalModeSocketLocation": "/var/tmp/mattermost_local.socket",
           ...
       }
   }
   ```

1. Restart Mattermost:

   ```shell
   sudo gitlab-ctl restart mattermost
   ```

You can then use `sudo /opt/gitlab/embedded/bin/mmctl --local` to run `mmctl` commands
on your Mattermost instance.

For example, to show the list of users:

```shell
$ sudo /opt/gitlab/embedded/bin/mmctl --local user list

13dzo5bmg7fu8rdox347hbfxde: appsbot (appsbot@localhost)
tbnkwjdug3dejcoddboo4yuomr: boards (boards@localhost)
wd3g5zpepjgbfjgpdjaas7yj6a: feedbackbot (feedbackbot@localhost)
8d3zzgpurp85zgf1q88pef73eo: playbooks (playbooks@localhost)
There are 4 users on local instance
```

### Use `mmctl` through a remote connection

For remote connections or local connections where the socket cannot be used,
create a non-SSO user and give that user administrator privileges. Those credentials
can then be used to authenticate `mmctl`:

```shell
$ /opt/gitlab/embedded/bin/mmctl auth login http://mattermost.example.com

Connection name: test
Username: local-user
Password:
 credentials for "test": "local-user@http://mattermost.example.com" stored
```

## Configuring GitLab and Mattermost integrations

You can use the plugin to subscribe Mattermost to receive notifications about issues, merge requests, and pull requests as well as personal notifications regarding merge request reviews, unread messages, and task assignments. If you want to use slash commands to perform actions
such as creating and viewing issues, or to trigger deployments use GitLab [Mattermost slash commands](../../user/project/integrations/mattermost_slash_commands.md).

The plugin and slash commands can be used together or individually.

## Email Notifications

### Setting up SMTP for GitLab Mattermost

These settings are configured through the Mattermost System Console by the System Administrator.
On the **Environment > SMTP** tab of the **System Console**, you can enter the SMTP credentials given by your SMTP provider, or `127.0.0.1` and port `25` to use `sendmail`. More information on the specific settings
that are needed is available in the [Mattermost documentation](https://docs.mattermost.com/install/smtp-email-setup.html).

These settings can also be configured in `/var/opt/gitlab/mattermost/config.json`.

### Email batching

Enabling this feature allows users to control how often they receive email notifications.

Email batching can be enabled in the Mattermost **System Console** by navigating to the **Environment > SMTP** tab, and setting the **Enable Email Batching** setting to **True**.

This setting can also be configured in `/var/opt/gitlab/mattermost/config.json`.

## Upgrading GitLab Mattermost

NOTE:
When upgrading the Mattermost version, it is essential to check the
[Important Upgrade Notes](https://docs.mattermost.com/administration/important-upgrade-notes.html)
for Mattermost to address any changes or migrations that need to be performed.

GitLab Mattermost can be upgraded through the regular Linux package update process. When upgrading previous versions of
GitLab, the update process can only be used if Mattermost configuration settings have not been changed outside of GitLab. That is, no changes to the Mattermost `config.json`
file have been made - either directly or via the Mattermost **System Console**, which saves changes to `config.json`.

If you have only configured Mattermost using `gitlab.rb`, you can upgrade GitLab using the Linux package and then run `gitlab-ctl reconfigure` to upgrade GitLab Mattermost to the latest version.

If this is not the case, there are two options:

1. Update [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L706)
   with the changes done to `config.json`. This might require adding some parameters as not all
   settings in `config.json` are available in `gitlab.rb`. Once complete, the Linux package should be
   able to upgrade GitLab Mattermost from one version to the next.
1. Migrate Mattermost outside of the directory controlled by the Linux package so it can be administered
   and upgraded independently. Follow the [Mattermost Migration Guide](https://docs.mattermost.com/administration/migrating.html)
   to move your Mattermost configuration settings and data to another directory or server independent
   from the Linux package.

For a complete list of upgrade notices and special considerations for older versions, see the [Mattermost documentation](https://docs.mattermost.com/administration/important-upgrade-notes.html).

### GitLab Mattermost versions and edition shipped with the Linux package

Below is a list of Mattermost version changes for GitLab 15.0 and later:

| GitLab version | Mattermost version | Notes                                                                                    |
| :------------- | :----------------- | ---------------------------------------------------------------------------------------- |
| 17.7           | 10.2               |                                                                                          |
| 17.6           | 10.1               |                                                                                          |
| 17.5           | 10.0               |                                                                                          |
| 17.4           | 9.11               |                                                                                          |
| 17.3           | 9.10               |                                                                                          |
| 17.2           | 9.9                |                                                                                          |
| 17.1           | 9.8                |                                                                                          |
| 17.0           | 9.7                |                                                                                          |
| 16.11          | 9.6                |                                                                                          |
| 16.10          | 9.5                |                                                                                          |
| 16.9           | 9.4                |                                                                                          |
| 16.7           | 9.3                |                                                                                          |
| 16.6           | 9.1                |                                                                                          |
| 16.5           | 9.0                |                                                                                          |
| 16.4           | 8.1                |                                                                                          |
| 16.3           | 8.0                |                                                                                          |
| 16.0           | 7.10               |                                                                                          |
| 15.11          | 7.9                |                                                                                          |
| 15.10          | 7.8                |                                                                                          |
| 15.9           | 7.7                |                                                                                          |
| 15.7           | 7.5                |                                                                                          |
| 15.6           | 7.4                |                                                                                          |
| 15.5           | 7.3                |                                                                                          |
| 15.4           | 7.2                |                                                                                          |
| 15.3           | 7.1                |                                                                                          |
| 15.2           | 7.0                |                                                                                          |
| 15.1           | 6.7                |                                                                                          |
| 15.0           | 6.6                |                                                                                          |

NOTE:
The Mattermost upgrade notes refer to different impacts when used with a PostgreSQL versus a MySQL database. The GitLab Mattermost included with the Linux package uses a PostgreSQL database.

The Linux package bundles the [Mattermost Team Edition](https://docs.mattermost.com/about/editions-and-offerings.html#mattermost-team-edition), which is a free and open source edition and does not include its commercial features.
To upgrade to the [Mattermost Enterprise Edition](https://docs.mattermost.com/about/editions-and-offerings.html#mattermost-enterprise-edition) see the Mattermost [documentation on upgrading](https://docs.mattermost.com/install/enterprise-install-upgrade.html#upgrading-to-enterprise-edition-in-gitlab-omnibus).

## OAuth 2.0 sequence diagram

The following image is a sequence diagram for how GitLab works as an OAuth 2.0
provider for Mattermost. You can use this to troubleshoot errors
in getting the integration to work:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
accTitle: GitLab as OAuth 2.0 provider
accDescr: Sequence of actions that happen when a user authenticates to GitLab through Mattermost.

    User->>Mattermost: GET https://mm.domain.com
    Note over Mattermost, GitLab: Obtain access code
    Mattermost->>GitLab: GET https://gitlab.domain.com/oauth/authorize
    Note over User, GitLab: GitLab user signs in (if necessary)
    Note over GitLab: GitLab verifies client_id matches an OAuth application
    GitLab->>User: GitLab asks user to authorize Mattermost OAuth app
    User->>GitLab: User selects 'Allow'
    Note over GitLab: GitLab verifies redirect_uri matches list of valid URLs
    GitLab->>User: 302 redirect: https://mm.domain.com/signup/gitlab/complete
    User->>Mattermost: GET https://mm.domain.com/signup/gitlab/complete
    Note over Mattermost, GitLab: Exchange access code for access token
    Mattermost->>GitLab: POST http://gitlab.domain.com/oauth/token
    GitLab->>GitLab: Doorkeeper::TokensController#35;create
    GitLab->>Mattermost: Access token
    Note over Mattermost, GitLab: Mattermost looks up GitLab user
    Mattermost->>GitLab: GET https://gitlab.domain.com/api/v4/user
    GitLab->>Mattermost: User details
    Mattermost->>User: Mattermost/GitLab user ready
```

## Community support resources

For help and support around your GitLab Mattermost deployment, see:

- [Troubleshooting Mattermost issues](https://docs.mattermost.com/install/troubleshooting.html).
- [Mattermost forum](https://forum.mattermost.com/search?q=gitlab).
