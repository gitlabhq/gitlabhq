# Cron jobs

## Adjusting synchronization times for repository mirroring

>**Notes:**
- This is an [Enterprise Edition][ee] only feature.
- For more information on the repository mirroring, see the
  [user documentation](../workflow/repository_mirroring.md).

You can manually configure the repository synchronization times by setting the
following configuration values.

Please note that `update_all_mirrors_worker_cron` refers to the worker used for
pulling changes from a remote mirror while `update_all_remote_mirrors_worker_cron`
refers to the worker used for pushing changes to the remote mirror.

>**Note:**
These are cron formatted values. You can use a crontab generator to create these
values, for example http://www.crontabgenerator.com/.

**Omnibus installations**

```
gitlab_rails['update_all_mirrors_worker_cron'] = "0 * * * *"
gitlab_rails['update_all_remote_mirrors_worker_cron'] = "30 * * * *"
```

**Source installations**

```
cron_jobs:
  update_all_mirrors_worker_cron:
    cron: "0 * * * *"
  update_all_remote_mirrors_worker_cron:
    cron: "30 * * * *"
```

[ee]: https://about.gitlab.com/products
