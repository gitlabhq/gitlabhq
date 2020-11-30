---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Mass inserting Rails models

Setting the environment variable [`MASS_INSERT=1`](rake_tasks.md#environment-variables)
when running [`rake setup`](rake_tasks.md) will create millions of records, but these records
aren't visible to the `root` user by default.

To make any number of the mass-inserted projects visible to the `root` user, run
the following snippet in the rails console.

```ruby
u = User.find(1)
Project.last(100).each { |p| p.set_timestamps_for_create && p.add_maintainer(u, current_user: u) } # Change 100 to whatever number of projects you need access to
```
