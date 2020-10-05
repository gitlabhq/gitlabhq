<!--
# Read me first!

Set the title to: `Security Release: 12.2.X, 12.1.X, and 12.0.X`
-->

:warning: **Only Release Managers and members of the AppSec team can edit the description of this issue**

-------

## Version issues:

12.2.X, 12.1.X, 12.0.X: {release task link}

## Issues in GitLab Security

To include your issue and merge requests in this Security Release, please mark
your security issues as related to this release tracking issue. You can do this
in the "Linked issues" section below this issue description.

:warning: If your security issues are not marked as related to this release
tracking issue, their merge requests will not be included in the security
release.

### Branches to target in GitLab Security

Your Security Implementation Issue should have `4` merge requests associated:

- [master and 3 backports](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/developer.md#backports)
- Backports should target the stable branches for the versions mentioned included in this Security Release

## Blog post

Security: {https://gitlab.com/gitlab-org/security/www-gitlab-com/merge_requests/ link}<br/>
GitLab.com: {https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/ link}

## Email notification
{https://gitlab.com/gitlab-com/marketing/general/issues/ link}

/label ~security ~"upcoming security release"
/confidential
