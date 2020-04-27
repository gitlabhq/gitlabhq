# Geo Rake Tasks **(PREMIUM ONLY)**

The following Rake tasks are for [Geo installations](../geo/replication/index.md).

## Git housekeeping

There are few tasks you can run to schedule a Git housekeeping to start at the
next repository sync in a **secondary** node:

### Incremental Repack

This is equivalent of running `git repack -d` on a _bare_ repository.

**Omnibus Installation**

```shell
sudo gitlab-rake geo:git:housekeeping:incremental_repack
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake geo:git:housekeeping:incremental_repack RAILS_ENV=production
```

### Full Repack

This is equivalent of running `git repack -d -A --pack-kept-objects` on a
_bare_ repository which will optionally, write a reachability bitmap index
when this is enabled in GitLab.

**Omnibus Installation**

```shell
sudo gitlab-rake geo:git:housekeeping:full_repack
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake geo:git:housekeeping:full_repack RAILS_ENV=production
```

### GC

This is equivalent of running `git gc` on a _bare_ repository, optionally writing
a reachability bitmap index when this is enabled in GitLab.

**Omnibus Installation**

```shell
sudo gitlab-rake geo:git:housekeeping:gc
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake geo:git:housekeeping:gc RAILS_ENV=production
```

## Remove orphaned project registries

Under certain conditions your project registry can contain obsolete records, you
can remove them using the Rake task `geo:run_orphaned_project_registry_cleaner`:

**Omnibus Installation**

```shell
sudo gitlab-rake geo:run_orphaned_project_registry_cleaner
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake geo:run_orphaned_project_registry_cleaner RAILS_ENV=production
```
