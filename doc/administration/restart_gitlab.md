# How to restart GitLab

Depending on how you installed GitLab, there are different methods to restart
its service(s).

If you want the TL;DR versions, jump to:

- [Omnibus GitLab restart](#omnibus-gitlab-restart)
- [Omnibus GitLab reconfigure](#omnibus-gitlab-reconfigure)
- [Source installation restart](#installations-from-source)
- [Helm chart installation restart](#helm-chart-installations)

## Omnibus installations

If you have used the [Omnibus packages][omnibus-dl] to install GitLab, then
you should already have `gitlab-ctl` in your `PATH`.

`gitlab-ctl` interacts with the Omnibus packages and can be used to restart the
GitLab Rails application (Unicorn) as well as the other components, like:

- GitLab Workhorse
- Sidekiq
- PostgreSQL (if you are using the bundled one)
- NGINX (if you are using the bundled one)
- Redis (if you are using the bundled one)
- [Mailroom][]
- Logrotate

### Omnibus GitLab restart

There may be times in the documentation where you will be asked to _restart_
GitLab. In that case, you need to run the following command:

```bash
sudo gitlab-ctl restart
```

The output should be similar to this:

```
ok: run: gitlab-workhorse: (pid 11291) 1s
ok: run: logrotate: (pid 11299) 0s
ok: run: mailroom: (pid 11306) 0s
ok: run: nginx: (pid 11309) 0s
ok: run: postgresql: (pid 11316) 1s
ok: run: redis: (pid 11325) 0s
ok: run: sidekiq: (pid 11331) 1s
ok: run: unicorn: (pid 11338) 0s
```

To restart a component separately, you can append its service name to the
`restart` command. For example, to restart **only** NGINX you would run:

```bash
sudo gitlab-ctl restart nginx
```

To check the status of GitLab services, run:

```bash
sudo gitlab-ctl status
```

Notice that all services say `ok: run`.

Sometimes, components time out (look for `timeout` in the logs) during the
restart and sometimes they get stuck.
In that case, you can use `gitlab-ctl kill <service>` to send the `SIGKILL`
signal to the service, for example `sidekiq`. After that, a restart should
perform fine.

As a last resort, you can try to
[reconfigure GitLab](#omnibus-gitlab-reconfigure) instead.

### Omnibus GitLab reconfigure

There may be times in the documentation where you will be asked to _reconfigure_
GitLab. Remember that this method applies only for the Omnibus packages.

Reconfigure Omnibus GitLab with:

```bash
sudo gitlab-ctl reconfigure
```

Reconfiguring GitLab should occur in the event that something in its
configuration (`/etc/gitlab/gitlab.rb`) has changed.

When you run this command, [Chef], the underlying configuration management
application that powers Omnibus GitLab, will make sure that all directories,
permissions, services, etc., are in place and in the same shape that they were
initially shipped.

It will also restart GitLab components where needed, if any of their
configuration files have changed.

If you manually edit any files in `/var/opt/gitlab` that are managed by Chef,
running reconfigure will revert the changes AND restart the services that
depend on those files.

## Installations from source

If you have followed the official installation guide to [install GitLab from
source][install], run the following command to restart GitLab:

```
sudo service gitlab restart
```

The output should be similar to this:

```
Shutting down GitLab Unicorn
Shutting down GitLab Sidekiq
Shutting down GitLab Workhorse
Shutting down GitLab MailRoom
...
GitLab is not running.
Starting GitLab Unicorn
Starting GitLab Sidekiq
Starting GitLab Workhorse
Starting GitLab MailRoom
...
The GitLab Unicorn web server with pid 28059 is running.
The GitLab Sidekiq job dispatcher with pid 28176 is running.
The GitLab Workhorse with pid 28122 is running.
The GitLab MailRoom email processor with pid 28114 is running.
GitLab and all its components are up and running.
```

This should restart Unicorn, Sidekiq, GitLab Workhorse and [Mailroom][]
(if enabled). The init service file that does all the magic can be found on
your server in `/etc/init.d/gitlab`.

---

If you are using other init systems, like systemd, you can check the
[GitLab Recipes][gl-recipes] repository for some unofficial services. These are
**not** officially supported so use them at your own risk.

[omnibus-dl]: https://about.gitlab.com/install/ "Download the Omnibus packages"
[install]: ../install/installation.md "Documentation to install GitLab from source"
[mailroom]: reply_by_email.md "Used for replying by email in GitLab issues and merge requests"
[chef]: https://www.chef.io/products/chef-infra/ "Chef official website"
[src-service]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib/support/init.d/gitlab "GitLab init service file"
[gl-recipes]: https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/init "GitLab Recipes repository"

## Helm chart installations

There is no single command to restart the entire GitLab application installed via
the [cloud native Helm Chart](https://docs.gitlab.com/charts/). Usually, it should be
enough to restart a specific component separately (`gitaly`, `unicorn`,
`workhorse`, `gitlab-shell`, etc.) by deleting all the pods related to it:

```bash
kubectl delete pods -l release=<helm release name>,app=<component name>
```

The release name can be obtained from the output of the `helm list` command.
