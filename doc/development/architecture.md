# GitLab Architecture Overview
---

# Software delivery

There's two editions of GitLab: [Enterprise Edition](https://www.gitlab.com/features/) (EE) and [Community Edition](http://gitlab.org/gitlab-ce/) (CE).   GitLab CE is delivered via git from the [gitlabhq repository](https://github.com/gitlabhq/gitlabhq/).   New versions of GitLab are released in stable branches and the master branch is for bleeding edge development.   EE releases are available not long after CE releases.   To obtain the GitLab EE there is a [repository at gitlab.com](https://gitlab.com/subscribers/gitlab-ee).   A new version of CE is delivered every month on the 22nd of the month. For this reason it is recommended to follow a monthly upgrade schedule because usually one can't skip versions when upgrading but must upgrade incrementally. Security updates come out on an informal basis.

Both EE and CE require an add-on component called gitlab-shell. It is obtained from the [gitlab-shell repository](https://github.com/gitlabhq/gitlab-shell).   New versions are usually tags but staying on the master branch will give you the latest stable version. New releases are generally around the same time as GitLab CE releases with exception for informal security updates deemed critical.

# System Layout

When referring to `~git` it means the home directory of the `git` user which is typically `/home/git`.

GitLab is primarily installed within the `/home/git` user home directory as `git` user.   Within the home directory is where the gitlabhq server software resides as well as the repositories (though repository location is configurable).   The bare repositories are located in `~git/repositories`.  GitLab is a ruby on rails application so the particulars of the inner workings can be learned by studying how a ruby on rails application works. To serve repositories over SSH there's an add-on application called gitlab-shell which is installed in `/home/git/gitlab-shell`.

## Components

![GitLab Diagram Overview](resources/gitlab_diagram_overview.png "GitLab Diagram Overview")

A typical install of GitLab will be on RHEL or Ubuntu Linux.  It uses Apache or nginx as a web front end to proxypass the Unicorn web server.  Communication between Unicorn and the front end is usually HTTP but access via socket is also supported.  The web front end accesses `~git/gitlab/public` bypassing the Unicorn server to serve static pages, attachments, and other resources the GitLab core creates (such as uploaded avatars or archives).  GitLab serves web pages and a [GitLab API](https://github.com/gitlabhq/gitlabhq/tree/master/doc/api) using the Unicorn web server.  It uses Sidekiq as a job queue which, in turn, uses redis as a non-persistent database backend for job information, meta data, and incomming jobs.  The GitLab web app uses MySQL or PostgreSQL for persistent database information (e.g. users, permissions, issues, other meta data).  GitLab stores the bare git repositories it serves in `~git/repositories` by default.  It also keeps default branch and hook information with the bare repository.  GitLab maintains a checked out version of each repository in `~git/gitlab-satellites`.  The satellite repository is used by the web interface for editing repositories and the wiki which is also a git repository.  When serving repositories over HTTP/HTTPS GitLab utilizes the GitLab API to resolve authorization and access as well as serving git objects.

The add-on component gitlab-shell serves repositories over SSH.  It manages the SSH keys within `~git/.ssh/authorized_keys` which should not be manually edited.  gitlab-shell accesses the bare repositories directly to serve git objects and communicates with redis to submit jobs to Sidekiq for GitLab to process.  gitlab-shell queries the GitLab API to determine authorization and access.

## Processes

    ps aux | grep '^git'

GitLab has several components to operate. As a system user (i.e. any user that is not the `git` user) it requires a persistent database (MySQL/PostreSQL) and redis database. It also uses Apache httpd or nginx to proxypass Unicorn. As the `git` user it starts Sidekiq and Unicorn (a simple ruby HTTP server running on port `8080` by default). Under the gitlab user there are normally 6 processes: `unicorn_rails master` (1 process), `unicorn_rails worker` (2 processes), `python pygments` (2 processes), `sidekiq` (1 process).  Pygments is used by GitLab for syntax highlighting in the web interface.

## Repository access

Repositories get accessed via HTTP or SSH. HTTP cloning/push/pull utilizes the GitLab API and SSH cloning is handled by gitlab-shell (previously explained).

# Troubleshooting

See also the [IRC F.A.Q.](https://github.com/gitlabhq/gitlab-public-wiki/wiki/IRC-channel-Guidelines-and-F.A.Q.) and [Troubleshooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki).

## Services

GitLab (includes Unicorn and Sidekiq), redis (non-persistent DB), SSH (all of the following)

```
/etc/init.d/gitlab 
Usage: service gitlab {start|stop|restart|reload|status}

/etc/init.d/redis 
Usage: /etc/init.d/redis {start|stop|status|restart|condrestart|try-restart}

/etc/init.d/sshd 
Usage: /etc/init.d/sshd {start|stop|restart|reload|force-reload|condrestart|try-restart|status}
```

Web front end (one of the following)

```
/etc/init.d/httpd 
Usage: httpd {start|stop|restart|condrestart|try-restart|force-reload|reload|status|fullstatus|graceful|help|configtest}

$ /etc/init.d/nginx
Usage: nginx {start|stop|restart|reload|force-reload|status|configtest}
```

Persistent database (one of the following)

```
/etc/init.d/mysqld 
Usage: /etc/init.d/mysqld {start|stop|status|restart|condrestart|try-restart|reload|force-reload}

$ /etc/init.d/postgresql
Usage: /etc/init.d/postgresql {start|stop|restart|reload|force-reload|status} [version ..]
```

## Log locations

Note: `~git/` is shorthand for `/home/git`.

gitlabhq (includes Unicorn and Sidekiq logs)

* `~git/gitlab/log/` contains `application.log`, `production.log`, `sidekiq.log`, `unicorn.stdout.log`, `githost.log`, `satellites.log`, and `unicorn.stderr.log` normally.

gitlab-shell

* `~git/gitlab-shell/gitlab-shell.log`

ssh

* `/var/log/auth.log` auth log (on Ubuntu).
* `/var/log/secure` auth log (on RHEL).

nginx

* `/var/log/nginx/` contains error and access logs.

Apache httpd

* [Explanation of apache logs](http://httpd.apache.org/docs/2.2/logs.html).
* `/var/log/apache2/` contains error and output logs (on Ubuntu).
* `/var/log/httpd/` contains error and output logs (on RHEL).

redis

* `/var/log/redis/redis.log` there are also logrotated logs there.

PostgreSQL

* `/var/log/postgresql/*`

MySQL

* `/var/log/mysql/*`
* `/var/log/mysql.*`

## GitLab specific config files

GitLab has configuration files located in `~git/gitlab/config/*`.  Commonly referenced config files include:

* `gitlab.yml` - GitLab configuration.
* `unicorn.rb` - Unicorn web server settings.
* `database.yml` - Database connection settings.

gitlab-shell has a configuration file at `~git/gitlab-shell/config.yml`.

## Maintenance Tasks

[gitlabhq](https://github.com/gitlabhq/gitlabhq) provides rake tasks with which you see version information and run a quick check on your configuration to ensure it is configured properly within the application.  See [maintenance rake tasks](https://github.com/gitlabhq/gitlabhq/blob/master/doc/raketasks/maintenance.md). In a nutshell, do the following:

```
sudo -i -u git
cd gitlab
bundle exec rake gitlab:env:info RAILS_ENV=production
bundle exec rake gitlab:check RAILS_ENV=production
```

Note: It is recommended to log into the `git` user using `sudo -i -u git` or `sudo su - git`.  While the sudo commands provided by gitlabhq work in Ubuntu they do not always work in RHEL.
