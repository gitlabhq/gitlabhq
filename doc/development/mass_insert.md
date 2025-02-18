---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Mass inserting Rails models
---

Setting the environment variable [`MASS_INSERT=1`](rake_tasks.md#environment-variables)
when running [`rake setup`](rake_tasks.md) creates millions of records, but these records
aren't visible to the `root` user by default.

To make any number of the mass-inserted projects visible to the `root` user, run
the following snippet in the rails console.

```ruby
u = User.find(1)
Project.last(100).each { |p| p.send(:set_timestamps_for_create) && p.add_maintainer(u, current_user: u) } # Change 100 to whatever number of projects you need access to
```
