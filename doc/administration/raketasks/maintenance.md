# Maintenance Rake Tasks

## Gather information about GitLab and the system it runs on

This command gathers information about your GitLab installation and the System it runs on. These may be useful when asking for help or reporting issues.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:env:info
```

**Source Installation**

```
bundle exec rake gitlab:env:info RAILS_ENV=production
```

Example output:

```
System information
System:           Debian 7.8
Current User:     git
Using RVM:        no
Ruby Version:     2.1.5p273
Gem Version:      2.4.3
Bundler Version:  1.7.6
Rake Version:     10.3.2
Redis Version:    3.2.5
Sidekiq Version:  2.17.8

GitLab information
Version:          7.7.1
Revision:         41ab9e1
Directory:        /home/git/gitlab
DB Adapter:       postgresql
URL:              https://gitlab.example.com
HTTP Clone URL:   https://gitlab.example.com/some-project.git
SSH Clone URL:    git@gitlab.example.com:some-project.git
Using LDAP:       no
Using Omniauth:   no

GitLab Shell
Version:          2.4.1
Repositories:     /home/git/repositories/
Hooks:            /home/git/gitlab-shell/hooks/
Git:              /usr/bin/git
```

## Check GitLab configuration

Runs the following rake tasks:

- `gitlab:gitlab_shell:check`
- `gitlab:gitaly:check`
- `gitlab:sidekiq:check`
- `gitlab:app:check`

It will check that each component was set up according to the installation guide and suggest fixes for issues found.

You may also have a look at our Troubleshooting Guides:

- [Troubleshooting Guide (GitLab)](../index.md#troubleshooting)
- [Troubleshooting Guide (Omnibus GitLab)](https://docs.gitlab.com/omnibus/README.html#troubleshooting)

**Omnibus Installation**

```
sudo gitlab-rake gitlab:check
```

**Source Installation**

```
bundle exec rake gitlab:check RAILS_ENV=production
```

NOTE: Use `SANITIZE=true` for `gitlab:check` if you want to omit project names from the output.

Example output:

```
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking GitLab Shell ...

GitLab Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking GitLab Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking GitLab ...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config outdated? ... no
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```

## Rebuild authorized_keys file

In some case it is necessary to rebuild the `authorized_keys` file.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:shell:setup
```

**Source Installation**

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
```

```
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Clear Redis cache

If for some reason the dashboard shows wrong information you might want to
clear Redis' cache.

**Omnibus Installation**

```
sudo gitlab-rake cache:clear
```

**Source Installation**

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

## Precompile the assets

Sometimes during version upgrades you might end up with some wrong CSS or
missing some icons. In that case, try to precompile the assets again.

Note that this only applies to source installations and does NOT apply to
Omnibus packages.

**Source Installation**

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production
```

For omnibus versions, the unoptimized assets (JavaScript, CSS) are frozen at
the release of upstream GitLab. The omnibus version includes optimized versions
of those assets. Unless you are modifying the JavaScript / CSS code on your
production machine after installing the package, there should be no reason to redo
`rake gitlab:assets:compile` on the production machine. If you suspect that assets
have been corrupted, you should reinstall the omnibus package.

## Tracking Deployments

GitLab provides a Rake task that lets you track deployments in GitLab
Performance Monitoring. This Rake task simply stores the current GitLab version
in the GitLab Performance Monitoring database.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:track_deployment
```

**Source Installation**

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:track_deployment RAILS_ENV=production
```

## Check TCP connectivity to a remote site

Sometimes you need to know if your GitLab installation can connect to a TCP
service on another machine - perhaps a PostgreSQL or HTTPS server. A rake task
is included to help you with this:

**Omnibus Installation**

```
sudo gitlab-rake gitlab:tcp_check[example.com,80]
```

**Source Installation**

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:tcp_check[example.com,80] RAILS_ENV=production
```

## Clear exclusive lease (DANGER)

GitLab uses a shared lock mechanism: `ExclusiveLease` to prevent simultaneous operations
in a shared resource. An example is running periodic garbage collection on repositories.

In very specific situations, a operation locked by an Exclusive Lease can fail without
releasing the lock. If you can't wait for it to expire, you can run this task to manually
clear it.

To clear all exclusive leases:

DANGER: **DANGER**:
Don't run it while GitLab or Sidekiq is running

```bash
sudo gitlab-rake gitlab:exclusive_lease:clear
```

To specify a lease `type` or lease `type + id`, specify a scope:

```bash
# to clear all leases for repository garbage collection:
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:*]

# to clear a lease for repository garbage collection in a specific project: (id=4)
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:4]
```

## Display status of database migrations

To check the status of migrations, you can use the following rake task:

```bash
sudo gitlab-rake db:migrate:status
```

This will output a table with a `Status` of `up` or `down` for
each Migration ID.

```bash
database: gitlabhq_production

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     migration_id    migration_name
```

## Import common metrics

Sometimes you may need to re-import the common metrics that power the Metrics dashboards.

This could be as a result of [updating existing metrics](../../development/prometheus_metrics.md#update-existing-metrics), or as a [troubleshooting measure](../../user/project/integrations/prometheus.md#troubleshooting).

To re-import the metrics you can run:

```sh
sudo gitlab-rake metrics:setup_common_metrics
```
