---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Disaster recovery **(FREE SELF)**

This document describes a feature that allows you to disable some important but computationally
expensive parts of the application to relieve stress on the database during an ongoing downtime.

## `ci_queueing_disaster_recovery_disable_fair_scheduling`

This feature flag, if temporarily enabled, disables fair scheduling on shared runners.
This can help to reduce system resource usage on the `jobs/request` endpoint
by significantly reducing the computations being performed.

Side effects:

- In case of a large backlog of jobs, the jobs are processed in the order
  they were put in the system, instead of balancing the jobs across many projects.

## `ci_queueing_disaster_recovery_disable_quota`

This feature flag, if temporarily enabled, disables enforcing CI minutes quota
on shared runners. This can help to reduce system resource usage on the
`jobs/request` endpoint by significantly reducing the computations being
performed.

Side effects:

- Projects which are out of quota will be run. This affects
  only jobs created during the last hour, as prior jobs are canceled
  by a periodic background worker (`StuckCiJobsWorker`).
