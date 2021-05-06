---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Disaster Recovery

This document describes a feature that allows to easily disable some important but computationally
expensive parts of the application, in order to relieve stress on the database in an ongoing downtime.

## `ci_queueing_disaster_recovery`

This feature flag, if enabled temporarily disables fair scheduling on shared runners.
This can help reduce system resource usage on the `jobs/request` endpoint
by significantly reducing computations being performed.

Side effects:

- In case of a large backlog of jobs, the jobs will be processed in the order
they were put in the system instead of balancing the jobs across many projects
- Projects which are out of quota will be run. This affects
only jobs that were created during the last hour, as prior jobs are canceled
by a periodic background worker (`StuckCiJobsWorker`).
