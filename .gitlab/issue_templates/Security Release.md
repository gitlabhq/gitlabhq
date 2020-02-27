<!--
# Read me first!

Set the title to: `Security Release: 12.2.X, 12.1.X, and 12.0.X`
-->

## Releases tasks

- https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/release-manager.md
- https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md
- https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/security-engineer.md

## Version issues:

12.2.X, 12.1.X, 12.0.X: {release task link}

## Issues in GitLab Security

To include your issue and merge requests in this Security Release, please mark
your security issues as related to this release tracking issue. You can do this
in the "Linked issues" section below this issue description.

:warning: If your security issues are not marked as related to this release
tracking issue, their merge requests may not be included in the security
release.

## Issues in Omnibus-GitLab

Omnibus security fixes need to be added manually to this issue description
using and below the following template:

```markdown
* {https://gitlab.com/gitlab-org/security/gitlab/issues/ link}

| Version | MR |
|---------|----|
| 12.2 | {https://dev.gitlab.org/gitlab/omnibus-gitlab/merge_requests/ link} |
| 12.1 | {https://dev.gitlab.org/gitlab/omnibus-gitlab/merge_requests/ link} |
| 12.0 | {https://dev.gitlab.org/gitlab/omnibus-gitlab/merge_requests/ link} |
| master | {https://dev.gitlab.org/gitlab/omnibus-gitlab/merge_requests/ link} |
```

## QA
{QA issue link}

## Blog post

Dev: {https://dev.gitlab.org/gitlab/www-gitlab-com/merge_requests/ link}<br/>
GitLab.com: {https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/ link}

## Email notification
{https://gitlab.com/gitlab-com/marketing/general/issues/ link}

/label ~security ~"upcoming security release"
/confidential
