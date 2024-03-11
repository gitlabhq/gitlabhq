---
stage: DevSecOps
group: Technical writing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started with GitLab application security

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Adopting GitLab application security](https://www.youtube.com/watch?v=5QlxkiKR04k).
<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an interactive reading and how-to demo playlist, see [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

The following steps help introduce you to GitLab application security tools incrementally.
You can choose to enable features in a different order, or skip features that don't apply to your specific needs.
You should start with:

- [Secret Detection](secret_detection/index.md), which works with all programming languages and creates understandable results.
- [Dependency Scanning](dependency_scanning/index.md), which finds known vulnerabilities in the dependencies your code uses.

If it's your first time setting up GitLab security scanning, you should start with a single project.
After you've gotten familiar with how scanning works, you can then choose to:

- Follow [the same steps](#recommended-steps) to enable scanning in more projects.
- [Enforce scanning](index.md#enforce-scan-execution) across more of your projects at once.

## Recommended steps

1. Choose a project to enable and test security features. Consider choosing a project:
   - That uses your organization's typical programming languages and technologies, because some scanning features work differently across languages.
   - Where you can try out new settings, like required approvals, without interrupting your team's daily work.
     You could create a copy of a higher-traffic project for testing, or select a project that's not as busy.
1. Create a merge request to [enable Secret Detection](secret_detection/pipeline/index.md#enabling-the-analyzer) and [enable Dependency Scanning](dependency_scanning/index.md#configuration)
   to identify any leaked secrets and vulnerable packages in that project.
   - Security scanners run in your project's [CI/CD pipelines](../../ci/pipelines/index.md). Creating a merge request to update your [`.gitlab-ci.yml`](../../ci/index.md#the-gitlab-ciyml-file) helps you check how the scanners work with your project before they start running in every pipeline. In the merge request, you can change relevant [Secret Detection settings](secret_detection/pipeline/index.md#configuration) or [Dependency Scanning settings](dependency_scanning/index.md#available-cicd-variables) to accommodate your project's layout or configuration. For example, you might choose to exclude a directory of third-party code from scanning.
   - After you merge this MR to your [default branch](../project/repository/branches/default.md), the system creates a baseline scan. This scan identifies which vulnerabilities already exist on the default branch so [merge requests](../project/merge_requests/index.md) can highlight only newly-introduced problems. Without a baseline scan, merge requests display every
     vulnerability in the branch, even if the vulnerability already exists on the default branch.
1. Let your team get comfortable with [viewing security findings in merge requests](index.md#view-security-scan-information) and the [vulnerability report](vulnerability_report/index.md).
1. Establish a vulnerability triage workflow.
   - Consider creating [labels](../project/labels.md) and [issue boards](../project/issue_board.md) to
     help manage issues created from vulnerabilities. Issue boards allow all stakeholders to have a
   common view of all issues and track remediation progress.
1. Monitor the [Security Dashboard](security_dashboard/index.md) trends to gauge success in remediating existing vulnerabilities and preventing the introduction of new ones.
1. Enforce scheduled security scanning jobs by using a [scan execution policy](policies/scan-execution-policies.md).
   - These scheduled jobs run independently from any other security scans you may have defined in a compliance framework pipeline or in the project's `.gitlab-ci.yml` file.
   - Running regular dependency and [container scans](container_scanning/index.md) surface newly-discovered vulnerabilities that already exist in your repository.
   - Scheduled scans are most useful for projects or important branches with low development activity where pipeline scans are infrequent.
1. Create a [merge request approval policy](policies/index.md) to limit new vulnerabilities from being merged
   into your [default branch](../project/repository/branches/default.md).
1. Enable other scan types such as [SAST](sast/index.md), [DAST](dast/index.md),
   [Fuzz testing](coverage_fuzzing/index.md), or [Container Scanning](container_scanning/index.md).
1. Use [Compliance Pipelines](../group/compliance_pipelines.md)
   or [Scan Execution Policies](policies/scan-execution-policies.md) to enforce required scan types
   and ensure separation of duties between security and engineering.
1. Consider enabling [Review Apps](../../development/testing_guide/review_apps.md) to allow for DAST
   and [Web API fuzzing](api_fuzzing/index.md) on ephemeral test environments.
1. Enable [operational container scanning](../../user/clusters/agent/vulnerabilities.md) to scan
   container images in your production cluster for security vulnerabilities.
