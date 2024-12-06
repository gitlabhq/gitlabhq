<!-- See Pipelines for the GitLab project: https://docs.gitlab.com/ee/development/pipelines -->
<!-- When in doubt about a Pipeline configuration change, feel free to ping @gl-dx/eng-prod. -->

## What does this MR do?

<!-- Briefly describe what this MR is about -->

## Related issues

<!-- Link related issues below. -->

## Checklist

### Pre-merge

Consider the effect of the changes in this merge request on the following:

- [ ] Different [pipeline types](https://docs.gitlab.com/ee/development/pipelines/index.html#pipelines-types-for-merge-requests)
- Non-canonical projects:
  - [ ] `gitlab-foss`
  - [ ] `security`
  - [ ] `dev`
  - [ ] personal forks
- [ ] [Pipeline performance](https://docs.gitlab.com/ee/ci/pipelines/pipeline_efficiency.html)

**If new jobs are added:**

- [ ] Change-related rules (e.g. frontend/backend/database file changes): _____
- [ ] Frequency they are running (MRs, main branch, nightly, bi-hourly): _____
- [ ] Add a duration chart to https://app.periscopedata.com/app/gitlab/652085/Engineering-Productivity---Pipeline-Build-Durations if there are new jobs added to merge request pipelines

This will help keep track of expected pipeline time and cost increases.

### Post-merge

- [ ] Consider communicating these changes to the broader team following the [communication guideline for pipeline changes](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/#pipeline-changes)

/label ~"maintenance::pipelines" ~"Engineering Productivity"
