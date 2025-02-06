---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: How to restart GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Depending on how you installed GitLab, there are different methods to restart
its services.

NOTE:
A short downtime is expected for all methods.

## Linux package installations

If you have used the [Linux package](https://about.gitlab.com/install/) to install GitLab,
you should already have `gitlab-ctl` in your `PATH`.

`gitlab-ctl` interacts with the Linux package installation and can be used to restart the
GitLab Rails application (Puma) as well as the other components, like:

- GitLab Workhorse
- Sidekiq
- PostgreSQL (if you are using the bundled one)
- NGINX (if you are using the bundled one)
- Redis (if you are using the bundled one)
- [Mailroom](reply_by_email.md)
- Logrotate

### Restart a Linux package installation

There may be times in the documentation where you are asked to _restart_
GitLab. To restart a Linux package installation, run:

```shell
sudo gitlab-ctl restart
```

The output should be similar to this:

```plaintext
ok: run: gitlab-workhorse: (pid 11291) 1s
ok: run: logrotate: (pid 11299) 0s
ok: run: mailroom: (pid 11306) 0s
ok: run: nginx: (pid 11309) 0s
ok: run: postgresql: (pid 11316) 1s
ok: run: redis: (pid 11325) 0s
ok: run: sidekiq: (pid 11331) 1s
ok: run: puma: (pid 11338) 0s
```

To restart a component separately, you can append its service name to the
`restart` command. For example, to restart **only** NGINX you would run:

```shell
sudo gitlab-ctl restart nginx
```

To check the status of GitLab services, run:

```shell
sudo gitlab-ctl status
```

Notice that all services say `ok: run`.

Sometimes, components time out (look for `timeout` in the logs) during the
restart and sometimes they get stuck.
In that case, you can use `gitlab-ctl kill <service>` to send the `SIGKILL`
signal to the service, for example `sidekiq`. After that, a restart should
perform fine.

As a last resort, you can try to reconfigure GitLab instead.

### Reconfigure a Linux package installation

There may be times in the documentation where you are asked to _reconfigure_
GitLab. Remember that this method applies only for Linux package installations.

To reconfigure a Linux package installation, run:

```shell
sudo gitlab-ctl reconfigure
```

Reconfiguring GitLab should occur in the event that something in its
configuration (`/etc/gitlab/gitlab.rb`) has changed.

When you run `gitlab-ctl reconfigure`, [Chef](https://www.chef.io/products/chef-infra),
the underlying configuration management application that powers Linux package installations, runs some checks.
Chef ensures directories, permissions, and services are in place and working.

Chef also restarts GitLab components if any of their configuration files have changed.

If you manually edit any files in `/var/opt/gitlab` that are managed by Chef,
running `reconfigure` reverts the changes and restarts the services that
depend on those files.

## Self-compiled installations

If you have followed the official installation guide to
[self-compile your installation](../install/installation.md), run the following command to restart GitLab:

```shell
# For systems running systemd
sudo systemctl restart gitlab.target

# For systems running SysV init
sudo service gitlab restart
```

This should restart Puma, Sidekiq, GitLab Workhorse, and [Mailroom](reply_by_email.md)
(if enabled).

## Helm chart installations

There is no single command to restart the entire GitLab application installed through
the [cloud-native Helm chart](https://docs.gitlab.com/charts/). Usually, it should be
enough to restart a specific component separately (for example, `gitaly`, `puma`,
`workhorse`, or `gitlab-shell`) by deleting all the pods related to it:

```shell
kubectl delete pods -l release=<helm release name>,app=<component name>
```

The release name can be obtained from the output of the `helm list` command.

## Docker installation

If you change the configuration on your [Docker installation](../install/docker/_index.md), for that change to take effect you must restart:

- The main `gitlab` container.
- Any separate component containers.

For example, if you deployed Sidekiq on a separate container, to restart the containers, run:

```shell
sudo docker restart gitlab
sudo docker restart sidekiq
```
