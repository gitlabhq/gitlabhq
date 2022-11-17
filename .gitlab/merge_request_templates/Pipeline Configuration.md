<!-- See Pipelines for the GitLab project: https://docs.gitlab.com/ee/development/pipelines -->
<!-- When in doubt about a Pipeline configuration change, feel free to ping @gl-quality/eng-prod. -->

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
- [ ] [Pipeline performance](https://about.gitlab.com/handbook/engineering/quality/performance-indicators/#average-merge-request-pipeline-duration-for-gitlab)

**If new jobs are added:**

- [ ] Change-related rules (e.g. frontend/backend/database file changes): _____
- [ ] Frequency they are running (MRs, main branch, nightly, bi-hourly): _____
- [ ] Add a duration chart to https://app.periscopedata.com/app/gitlab/652085/Engineering-Productivity---Pipeline-Build-Durations if there are new jobs added to merge request pipelines

This will help keep track of expected cost increases to the [GitLab project average pipeline cost per merge request](https://about.gitlab.com/handbook/engineering/quality/performance-indicators/#gitlab-project-average-pipeline-cost-per-merge-request) RPI

### Post-merge

- [ ] Consider communicating these changes to the broader team following the [communication guideline for pipeline changes](https://about.gitlab.com/handbook/engineering/quality/engineering-productivity/#pipeline-changes)

/label ~"maintenance::pipelines" ~"Engineering Productivity"
