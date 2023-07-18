---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Geo Rake tasks **(PREMIUM SELF)**

The following Rake tasks are for [Geo installations](../geo/index.md).
See also [troubleshooting Geo](../geo/replication/troubleshooting.md) for additional Geo Rake tasks.

## Git housekeeping

There are few tasks you can run to schedule a Git housekeeping to start at the
next repository sync in a **secondary** node:

### Incremental Repack

This is equivalent of running `git repack -d` on a _bare_ repository.

- Linux package installations:

  ```shell
  sudo gitlab-rake geo:git:housekeeping:incremental_repack
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake geo:git:housekeeping:incremental_repack RAILS_ENV=production
  ```

### Full Repack

This is equivalent of running `git repack -d -A --pack-kept-objects` on a
_bare_ repository which optionally, writes a reachability bitmap index
when this is enabled in GitLab.

- Linux package installations:

  ```shell
  sudo gitlab-rake geo:git:housekeeping:full_repack
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake geo:git:housekeeping:full_repack RAILS_ENV=production
  ```

### GC

This is equivalent of running `git gc` on a _bare_ repository, optionally writing
a reachability bitmap index when this is enabled in GitLab.

- Linux package installations:

  ```shell
  sudo gitlab-rake geo:git:housekeeping:gc
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake geo:git:housekeeping:gc RAILS_ENV=production
  ```

## Remove orphaned project registries

Under certain conditions your project registry can contain obsolete records, you
can remove them using the Rake task `geo:run_orphaned_project_registry_cleaner`:

- Linux package installations:

  ```shell
  sudo gitlab-rake geo:run_orphaned_project_registry_cleaner
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake geo:run_orphaned_project_registry_cleaner RAILS_ENV=production
  ```
