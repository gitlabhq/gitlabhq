# Maintenance

## Gather information about GitLab and the system it runs on

This command gathers information about your GitLab installation and the System it runs on. These may be useful when asking for help or reporting issues.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:env:info

# installation from source
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
- `gitlab:sidekiq:check`
- `gitlab:app:check`

It will check that each component was setup according to the installation guide and suggest fixes for issues found.

You may also have a look at our [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide).

```
# omnibus-gitlab
sudo gitlab-rake gitlab:check

# installation from source
bundle exec rake gitlab:check RAILS_ENV=production
```

NOTE: Use SANITIZE=true for gitlab:check if you want to omit project names from the output.

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

For Omnibus-packages:
```
sudo gitlab-rake gitlab:shell:setup
```

For installations from source:
```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
```

```
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Clear redis cache

If for some reason the dashboard shows wrong information you might want to
clear Redis' cache.

For Omnibus-packages:
```
sudo gitlab-rake cache:clear
```

For installations from source:
```
cd /home/git/gitlab
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

## Precompile the assets

Sometimes during version upgrades you might end up with some wrong CSS or
missing some icons. In that case, try to precompile the assets again.

Note that this only applies to source installations and does NOT apply to
omnibus packages.

For installations from source:
```
cd /home/git/gitlab
sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
```

For omnibus versions, the unoptimized assets (JavaScript, CSS) are frozen at
the release of upstream GitLab. The omnibus version includes optimized versions
of those assets. Unless you are modifying the JavaScript / CSS code on your
production machine after installing the package, there should be no reason to redo
rake assets:precompile on the production machine. If you suspect that assets
have been corrupted, you should reinstall the omnibus package.

## Tracking Deployments

GitLab provides a Rake task that lets you track deployments in GitLab
Performance Monitoring. This Rake task simply stores the current GitLab version
in the GitLab Performance Monitoring database.

For Omnibus-packages:

```
sudo gitlab-rake gitlab:track_deployment
```

For installations from source:

```
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:track_deployment RAILS_ENV=production
```
