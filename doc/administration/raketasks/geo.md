# Geo Rake Tasks **(PREMIUM ONLY)**

## Git housekeeping

There are few tasks you can run to schedule a git housekeeping to start at the 
next repository sync in a **Secondary node**:

### Incremental Repack

This is equivalent of running `git repack -d` on a _bare_ repository.

**Omnibus Installation**

```
sudo gitlab-rake geo:git:housekeeping:incremental_repack
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake geo:git:housekeeping:incremental_repack RAILS_ENV=production
```

### Full Repack

This is equivalent of running `git repack -d -A --pack-kept-objects` on a 
_bare_ repository which will optionally, write a reachability bitmap index
when this is enabled in GitLab.

**Omnibus Installation**

```
sudo gitlab-rake geo:git:housekeeping:full_repack
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake geo:git:housekeeping:full_repack RAILS_ENV=production
```

### GC

This is equivalent of running `git gc` on a _bare_ repository, optionally writing
a reachability bitmap index when this is enabled in GitLab.

**Omnibus Installation**

```
sudo gitlab-rake geo:git:housekeeping:gc
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake geo:git:housekeeping:gc RAILS_ENV=production
```
