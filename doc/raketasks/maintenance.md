### Gather information about GitLab and the system it runs on

This command gathers information about your GitLab installation and the System
it runs on. These may be useful when asking for help or reporting issues.

```
bundle exec rake gitlab:env:info RAILS_ENV=production
```

Example output:

```
System information
System:		Debian 6.0.7
Current User:	git
Using RVM:	no
Ruby Version:	1.9.3p392
Gem Version:	1.8.23
Bundler Version:1.3.5
Rake Version:	10.0.4

GitLab information
Version:	5.1.0.beta2
Revision:	4da8b37
Directory:	/home/git/gitlab
DB Adapter:	mysql2
URL:		http://example.com
HTTP Clone URL:	http://example.com/some-project.git
SSH Clone URL:	git@example.com:some-project.git
Using LDAP:	no
Using Omniauth:	no

GitLab Shell
Version:	1.2.0
Repositories:	/home/git/repositories/
Hooks:		/home/git/gitlab-shell/hooks/
Git:		/usr/bin/git
```


### Check GitLab configuration

Runs the following rake tasks:

* gitlab:env:check
* gitlab:gitlab_shell:check
* gitlab:sidekiq:check
* gitlab:app:check

It will check that each component was setup according to the installation guide and suggest fixes for issues found.

You may also have a look at our [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide).

```
bundle exec rake gitlab:check RAILS_ENV=production
```

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
Projects have satellites? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```


### (Re-)Create satellite repos

This will create satellite repos for all your projects.
If necessary, remove the `tmp/repo_satellites` directory and rerun the command below.

```
bundle exec rake gitlab:satellites:create RAILS_ENV=production
```
