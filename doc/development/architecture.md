# GitLab Architecture Overview

## Software delivery

There are two software distributions of GitLab: the open source [Community Edition](https://gitlab.com/gitlab-org/gitlab-ce/) (CE), and the open core [Enterprise Edition](https://gitlab.com/gitlab-org/gitlab-ee/) (EE). GitLab is available under [different subscriptions](https://about.gitlab.com/pricing/).

New versions of GitLab are released in stable branches and the master branch is for bleeding edge development.

For information, see the [GitLab Release Process](https://gitlab.com/gitlab-org/release/docs/tree/master#gitlab-release-process).

Both EE and CE require some add-on components called gitlab-shell and Gitaly. These components are available from the [gitlab-shell](https://gitlab.com/gitlab-org/gitlab-shell/tree/master) and [gitaly](https://gitlab.com/gitlab-org/gitaly/tree/master) repositories respectively. New versions are usually tags but staying on the master branch will give you the latest stable version. New releases are generally around the same time as GitLab CE releases with exception for informal security updates deemed critical.

## GitLab Omnibus Component by Component

This document is designed to be consumed by systems adminstrators and GitLab Support Engineers who want to understand more about the internals of GitLab and how they work together.

When deployed, GitLab should be considered the amalgamation of the below processes. When troubleshooting or debugging, be as specific as possible as to which component you are referencing. That should increase clarity and reduce confusion.

### GitLab Process Descriptions

As of this writing, a fresh GitLab 11.3.0 install will show the following processes with `gitlab-ctl status`:

```
run: alertmanager: (pid 30829) 14207s; run: log: (pid 13906) 2432044s
run: gitaly: (pid 30771) 14210s; run: log: (pid 13843) 2432046s
run: gitlab-monitor: (pid 30788) 14209s; run: log: (pid 13868) 2432045s
run: gitlab-workhorse: (pid 30758) 14210s; run: log: (pid 13855) 2432046s
run: logrotate: (pid 30246) 3407s; run: log: (pid 13825) 2432047s
run: nginx: (pid 30849) 14207s; run: log: (pid 13856) 2432046s
run: node-exporter: (pid 30929) 14206s; run: log: (pid 13877) 2432045s
run: postgres-exporter: (pid 30935) 14206s; run: log: (pid 13931) 2432044s
run: postgresql: (pid 13133) 2432214s; run: log: (pid 13848) 2432046s
run: prometheus: (pid 30807) 14209s; run: log: (pid 13884) 2432045s
run: redis: (pid 30560) 14274s; run: log: (pid 13807) 2432047s
run: redis-exporter: (pid 30946) 14205s; run: log: (pid 13869) 2432045s
run: sidekiq: (pid 30953) 14205s; run: log: (pid 13810) 2432047s
run: unicorn: (pid 30960) 14204s; run: log: (pid 13809) 2432047s
```

### Layers

GitLab can be considered to have two layers from a process perspective:

- **Monitoring**: Anything from this layer is not required to deliver GitLab the application, but will allow administrators more insight into their infrastructure and what the service as a whole is doing.
- **Core**: Any process that is vital for the delivery of GitLab as a platform. If any of these processes halt there will be a GitLab outage. For the Core layer, you can further divide into:
  - **Processors**: These processes are responsible for actually performing operations and presenting the service.
  - **Data**: These services store/expose structured data for the GitLab service.

### alertmanager

- Omnibus configuration options
- Layer: Monitoring

[Alert manager](https://prometheus.io/docs/alerting/alertmanager/) is a tool provided by prometheus that _"handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or OpsGenie. It also takes care of silencing and inhibition of alerts."_ You can read more in [issue gitlab-ce#45740](https://gitlab.com/gitlab-org/gitlab-ce/issues/45740) about what we will be alerting on.

### gitaly

- [Omnibus configuration options](https://gitlab.com/gitlab-org/gitaly/tree/master/doc/configuration)
- Layer: Core Service (Data)

Gitaly is a service designed by GitLab to remove our need for NFS for Git storage in distributed deployments of GitLab (Think GitLab.com or High Availability Deployments). As of 11.3.0, this service handles all Git level access in GitLab. You can read more about the project [in the project's readme](https://gitlab.com/gitlab-org/gitaly).

### gitlab-monitor

- Omnibus configuration options
- Layer: Monitoring

GitLab Monitor is a process designed in house that allows us to export metrics about GitLab application internals to prometheus. You can read more [in the project's readme](https://gitlab.com/gitlab-org/gitlab-monitor)

### gitlab-workhorse

- Omnibus configuration options
- Layer: Core Service (Processor)

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) is a program designed at GitLab to help alleviate pressure from unicorn. You can read more about the [historical reasons for developing](https://about.gitlab.com/2016/04/12/a-brief-history-of-gitlab-workhorse/). It's designed to act as a smart reverse proxy to help speed up GitLab as a whole.

### logrotate

- [Omnibus configuration options](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate)
- Layer: Core Service

GitLab is comprised of a large number of services that all log. We started bundling our own logrotate as of 7.4 to make sure we were logging responsibly. This is just a packaged version of the common opensource offering.

### nginx

- [Omnibus configuration options](https://docs.gitlab.com/omnibus/settings/nginx.html)
- Layer: Core Service (Processor)

Nginx as an ingress port for all HTTP requests and routes them to the approriate sub-systems within GitLab. We are bundling an unmodified version of the popular open source webserver.

### node-exporter

- [Omnibus configuration options](https://docs.gitlab.com/ee/administration/monitoring/prometheus/node_exporter.html)
- Layer: Monitoring

[Node Exporter](https://github.com/prometheus/node_exporter) is a Prometheus tool that gives us metrics on the underlying machine. (Think CPU/Disk/Load) It's just a packaged version of the common open source offering from the Prometheus project.

### postgres-exporter

- [Omnibus configuration options](https://docs.gitlab.com/ee/administration/monitoring/prometheus/postgres_exporter.html)
- Layer: Monitoring

[Postgres-exporter](https://github.com/wrouesnel/postgres_exporter) is the community provided Prometheus exporter that will deliver data about Postgres to prometheus for use in Grafana Dashboards.

### postgresql

- [Omnibus configuration options](https://docs.gitlab.com/omnibus/settings/database.html)
- Layer: Core Service (Data)

GitLab packages the popular Database to provide storage for Application meta data and user information.

### prometheus

- [Omnibus configuration options](https://docs.gitlab.com/ee/administration/monitoring/prometheus/)
- Layer: Monitoring

Prometheus is a time-series tool that helps GitLab administrators expose metrics about the individual processes used to provide GitLab the service.

### redis

- [Omnibus configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
- Layer: Core Service (Data)

Redis is packaged to provide a place to store:

- session data
- temporary cache information
- background job queues.

### redis-exporter

- [Omnibus configuration options](https://docs.gitlab.com/ee/administration/monitoring/prometheus/redis_exporter.html)
- Layer: Monitoring

[Redis Exporter](https://github.com/oliver006/redis_exporter) is designed to give specific metrics about the Redis process to Prometheus so that we can graph these metrics in Graphana.

### sidekiq

- Omnibus configuration options
- Layer: Core Service (Processor)

Sidekiq is a Ruby background job processor that pulls jobs from the redis queue and processes them. Background jobs allow GitLab to provide a faster request/response cycle by moving work into the background.

### unicorn

- [Omnibus configuration options](https://docs.gitlab.com/omnibus/settings/unicorn.html)
- Layer: Core Service (Processor)

[Unicorn](https://bogomips.org/unicorn/) is a Ruby application server that is used to run the core Rails Application that provides the user facing features in GitLab. Often process output you will see this as `bundle` or `config.ru` depending on the GitLab version.

### Additional Processes

### GitLab Pages

TODO

### Mattermost

TODO

### Registry

The registry is what users use to store their own Docker images. The bundled
registry uses nginx as a load balancer and GitLab as an authentication manager.
Whenever a client requests to pull or push an image from the registry, it will
return a `401` response along with a header detailing where to get an
authentication token, in this case the GitLab instance. The client will then
request a pull or push auth token from GitLab and retry the original request
to the registry. Learn more about [token authentication](https://docs.docker.com/registry/spec/auth/token/).

An external registry can also be configured to use GitLab as an auth endpoint.

## GitLab by Request Type

GitLab provides two "interfaces" for end users to access the service:

- Web HTTP Requests (Viewing the UI/API)
- Git HTTP/SSH Requests (Pushing/Pulling Git Data)

It's important to understand the distinction as some processes are used in both and others are exclusive to a specific request type.

### GitLab Web HTTP Request Cycle

When making a request to an HTTP Endpoint (Think `/users/sign_in`) the request will take the following path through the GitLab Service:

- nginx - Acts as our first line reverse proxy
- gitlab-workhorse - This determines if it needs to go to the Rails application or somewhere else to reduce load on unicorn.
- unicorn - Since this is a web request, and it needs to access the application it will go to Unicorn.
- Postgres/Gitaly/Redis - Depending on the type of request, it may hit these services to store or retrieve data.

### GitLab Git Request Cycle

Below we describe the different pathing that HTTP vs. SSH Git requests will take. There is some overlap with the Web Request Cycle but also some differences.

### Web Request (80/443)
TODO

### SSH Request (22)
TODO

## System Layout

When referring to `~git` in the pictures it means the home directory of the git user which is typically /home/git.

GitLab is primarily installed within the `/home/git` user home directory as `git` user. Within the home directory is where the gitlabhq server software resides as well as the repositories (though the repository location is configurable).

The bare repositories are located in `/home/git/repositories`. GitLab is a ruby on rails application so the particulars of the inner workings can be learned by studying how a ruby on rails application works.

To serve repositories over SSH there's an add-on application called gitlab-shell which is installed in `/home/git/gitlab-shell`.

### Components

<img src="https://docs.google.com/drawings/d/1fBzAyklyveF-i-2q-OHUIqDkYfjjxC4mq5shwKSZHLs/pub?w=987&amp;h=797">

_[edit diagram (for GitLab team members only)](https://docs.google.com/drawings/d/1fBzAyklyveF-i-2q-OHUIqDkYfjjxC4mq5shwKSZHLs/edit)_

A typical install of GitLab will be on GNU/Linux. It uses Nginx or Apache as a web front end to proxypass the Unicorn web server. By default, communication between Unicorn and the front end is via a Unix domain socket but forwarding requests via TCP is also supported. The web front end accesses `/home/git/gitlab/public` bypassing the Unicorn server to serve static pages, uploads (e.g. avatar images or attachments), and precompiled assets. GitLab serves web pages and a [GitLab API](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/api) using the Unicorn web server. It uses Sidekiq as a job queue which, in turn, uses redis as a non-persistent database backend for job information, meta data, and incoming jobs.

The GitLab web app uses MySQL or PostgreSQL for persistent database information (e.g. users, permissions, issues, other meta data). GitLab stores the bare git repositories it serves in `/home/git/repositories` by default. It also keeps default branch and hook information with the bare repository.

When serving repositories over HTTP/HTTPS GitLab utilizes the GitLab API to resolve authorization and access as well as serving git objects.

The add-on component gitlab-shell serves repositories over SSH. It manages the SSH keys within `/home/git/.ssh/authorized_keys` which should not be manually edited. gitlab-shell accesses the bare repositories through Gitaly to serve git objects and communicates with redis to submit jobs to Sidekiq for GitLab to process. gitlab-shell queries the GitLab API to determine authorization and access.

Gitaly executes git operations from gitlab-shell and the GitLab web app, and provides an API to the GitLab web app to get attributes from git (e.g. title, branches, tags, other meta data), and to get blobs (e.g. diffs, commits, files).

You may also be interested in the [production architecture of GitLab.com](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/).

### Installation Folder Summary

To summarize here's the [directory structure of the `git` user home directory](../install/structure.md).

### Processes

    ps aux | grep '^git'

GitLab has several components to operate. As a system user (i.e. any user that is not the `git` user) it requires a persistent database (MySQL/PostreSQL) and redis database. It also uses Apache httpd or Nginx to proxypass Unicorn. As the `git` user it starts Sidekiq and Unicorn (a simple ruby HTTP server running on port `8080` by default). Under the GitLab user there are normally 4 processes: `unicorn_rails master` (1 process), `unicorn_rails worker` (2 processes), `sidekiq` (1 process).

### Repository access

Repositories get accessed via HTTP or SSH. HTTP cloning/push/pull utilizes the GitLab API and SSH cloning is handled by gitlab-shell (previously explained).

## Troubleshooting

See the README for more information.

### Init scripts of the services

The GitLab init script starts and stops Unicorn and Sidekiq.

```
/etc/init.d/gitlab
Usage: service gitlab {start|stop|restart|reload|status}
```

Redis (key-value store/non-persistent database)

```
/etc/init.d/redis
Usage: /etc/init.d/redis {start|stop|status|restart|condrestart|try-restart}
```

SSH daemon

```
/etc/init.d/sshd
Usage: /etc/init.d/sshd {start|stop|restart|reload|force-reload|condrestart|try-restart|status}
```

Web server (one of the following)

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

### Log locations of the services

gitlabhq (includes Unicorn and Sidekiq logs)

- `/home/git/gitlab/log/` contains `application.log`, `production.log`, `sidekiq.log`, `unicorn.stdout.log`, `githost.log` and `unicorn.stderr.log` normally.

gitlab-shell

- `/home/git/gitlab-shell/gitlab-shell.log`

ssh

- `/var/log/auth.log` auth log (on Ubuntu).
- `/var/log/secure` auth log (on RHEL).

nginx

- `/var/log/nginx/` contains error and access logs.

Apache httpd

- [Explanation of Apache logs](https://httpd.apache.org/docs/2.2/logs.html).
- `/var/log/apache2/` contains error and output logs (on Ubuntu).
- `/var/log/httpd/` contains error and output logs (on RHEL).

redis

- `/var/log/redis/redis.log` there are also log-rotated logs there.

PostgreSQL

- `/var/log/postgresql/*`

MySQL

- `/var/log/mysql/*`
- `/var/log/mysql.*`

### GitLab specific config files

GitLab has configuration files located in `/home/git/gitlab/config/*`. Commonly referenced config files include:

- `gitlab.yml` - GitLab configuration.
- `unicorn.rb` - Unicorn web server settings.
- `database.yml` - Database connection settings.

gitlab-shell has a configuration file at `/home/git/gitlab-shell/config.yml`.

### Maintenance Tasks

[GitLab](https://gitlab.com/gitlab-org/gitlab-ce/tree/master) provides rake tasks with which you see version information and run a quick check on your configuration to ensure it is configured properly within the application. See [maintenance rake tasks](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/maintenance.md).
In a nutshell, do the following:

```
sudo -i -u git
cd gitlab
bundle exec rake gitlab:env:info RAILS_ENV=production
bundle exec rake gitlab:check RAILS_ENV=production
```

Note: It is recommended to log into the `git` user using `sudo -i -u git` or `sudo su - git`. While the sudo commands provided by gitlabhq work in Ubuntu they do not always work in RHEL.

## GitLab.com

We've also detailed [our architecture of GitLab.com](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/) but this is probably over the top unless you have millions of users.
