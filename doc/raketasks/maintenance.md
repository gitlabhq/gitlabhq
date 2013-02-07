### Gather information about GitLab and the system it runs on

This command gathers information about your GitLab installation and the System
it runs on. These may be useful when asking for help or reporting issues.

```
bundle exec rake gitlab:env:info RAILS_ENV=production
```

Example output:

```
System information
System:         Debian 6.0.6
Current User:   gitlab
Using RVM:      yes
RVM Version:    1.17.2
Ruby Version:   ruby-1.9.3-p327
Gem Version:    1.8.24
Bundler Version:1.2.3
Rake Version:   10.0.1

GitLab information
Version:        3.1.0
Resivion:       fd5141d
Directory:      /home/gitlab/gitlab
DB Adapter:     mysql2
URL:            http://localhost:3000
HTTP Clone URL: http://localhost:3000/some-project.git
SSH Clone URL:  git@localhost:some-project.git
Using LDAP:     no
Using Omniauth: no

Gitolite information
Version:        v3.04-4-g4524f01
Admin URI:      git@localhost:gitolite-admin
Admin Key:      gitlab
Repositories:   /home/git/repositories/
Hooks:          /home/git/.gitolite/hooks/
Git:            /usr/bin/git
```


### Check GitLab configuration

Runs the following rake tasks:

* gitlab:env:check
* gitlab:gitolite:check
* gitlab:resque:check
* gitlab:app:check

It will check that each component was setup according to the installation guide and suggest fixes for issues found.

You may also have a look at our [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide).

```
bundle exec rake gitlab:check RAILS_ENV=production
```

Example output:

```
Checking Environment ...

gitlab user is in git group? ... yes
Has no "-e" in ~git/.profile ... yes
Git configured for gitlab user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking Gitolite ...

Using recommended version ... yes
Repo umask is 0007 in .gitolite.rc? ... yes
Allow all Git config keys in .gitolite.rc ... yes
Config directory exists? ... yes
Config directory owned by git:git? ... yes
Config directory access is drwxr-x---? ... yes
Repo base directory exists? ... yes
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
Can clone gitolite-admin? ... yes
Can commit to gitolite-admin? ... yes
post-receive hook exists? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ...
GitLab ... ok
Non-Ascii Files Test ... ok
Touch Commit Test ... ok
Without Master Test ... ok
Git config in repos: ...
GitLab ... ok
Non-Ascii Files Test ... ok
Touch Commit Test ... ok
Without Master Test ... ok

Checking Gitolite ... Finished

Checking Resque ...

Running? ... yes

Checking Resque ... Finished

Checking GitLab ...

Database config exists? ... yes
Database is not SQLite ... yes
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config not outdated? ... yes
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Projects have satellites? ...
GitLab ... yes
Non-Ascii Files Test ... yes
Touch Commit Test ... yes
Without Master Test ... yes

Checking GitLab ... Finished
```


### (Re-)Create satellite repos

This will create satellite repos for all your projects.
If necessary, remove the `tmp/repo_satellites` directory and rerun the command below.

```
bundle exec rake gitlab:satellites:create RAILS_ENV=production
```


### Rebuild each key at gitolite config

This will send all users ssh public keys to gitolite and grant them access (based on their permission) to their projects.

```
bundle exec rake gitlab:gitolite:update_keys RAILS_ENV=production
```


### Rebuild each project at gitolite config

This makes sure that all projects are present in gitolite and can be accessed.

```
bundle exec rake gitlab:gitolite:update_repos RAILS_ENV=production
```

### Import bare repositories into GitLab project instance

Notes:

* project owner will be a first admin
* existing projects will be skipped

How to use:

1. copy your bare repos under git base_path (see `config/gitlab.yml` git_host -> base_path)
2. run the command below

```
bundle exec rake gitlab:import:repos RAILS_ENV=production
```

Example output:

```
Processing abcd.git
 * Created abcd (abcd.git)
[...]
```
