---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Tuning Geo **(PREMIUM SELF)**

## Changing the sync/verification capacity values

In **Admin Area > Geo** (`/admin/geo/nodes`),
there are several variables that can be tuned to improve performance of Geo:

- Repository sync capacity
- File sync capacity
- Container repositories sync capacity
- Verification capacity

Increasing capacity values will increase the number of jobs that are scheduled.
However, this may not lead to more downloads in parallel unless the number of
available Sidekiq threads is also increased. For example, if repository sync
capacity is increased from 25 to 50, you may also want to increase the number
of Sidekiq threads from 25 to 50. See the
[Sidekiq concurrency documentation](../../operations/extra_sidekiq_processes.md#number-of-threads)
for more details.

## Repository re-verification

See
[Automatic background verification](../disaster_recovery/background_verification.md).
