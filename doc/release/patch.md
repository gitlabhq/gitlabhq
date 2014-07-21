# Things to do when doing a patch release

NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

## When to do a patch release

Do a patch release when there is a critical regression that needs to be addresses before the next monthly release.

Otherwise include it in the monthly release and note there was a regression fix in the release announcement.

## Release Procedure

1. Verify that the issue can be reproduced
1. Note in the 'GitLab X.X regressions' that you will create a patch
1. Create an issue on private GitLab development server
1. Name the issue "Release X.X.X CE and X.X.X EE", this will make searching easier
1. Fix the issue on a feature branch, do this on the private GitLab development server
1. Consider creating and testing workarounds
1. After the branch is merged into master, cherry pick the commit(s) into the current stable branch
1. In a separate commit in the stable branch update the CHANGELOG
1. For EE, update the CHANGELOG-EE if it is EE specific fix. Otherwise, merge the stable CE branch and add to CHANGELOG-EE "Merge community edition changes for version X.X.X"
1. In a separate commit in the stable branch update the VERSION
1. Create an annotated tag vX.X.X for CE and another patch release for EE `git tag -a vx.x.x -m 'Version x.x.x'`
1. Make sure that the build has passed and all tests are passing
1. Push the code and the tags to all the CE and EE repositories
1. Apply the patch to GitLab Cloud and the private GitLab development server
1. [Build new packages with the latest version](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md)
1. Cherry-pick the changelog update back into master
1. Send tweets about the release from `@gitlabhq`, tweet should include the most important feature that the release is addressing as well as the link to the changelog
1. Note in the 'GitLab X.X regressions' issue that the patch was published (CE only)
1. Send out an email to the 'GitLab Newsletter' mailing list on MailChimp (or the 'Subscribers' list if the patch is EE only)
