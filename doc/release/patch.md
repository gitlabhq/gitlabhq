# Things to do when doing a patch release
NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

## When to do a patch release

Do a patch release when there is a critical regression that needs to be adresses before the next monthly release.
Otherwise include it in the monthly release and note there was a regression fix in the release announcement.

## Release Procedure

1. Verify that the issue can be repoduced
1. Create an issue on private GitLab development server
1. Name the issue "Release X.X.X CE and X.X.X EE", this will make searching easier
1. Fix the issue on a feature branch, do this on the private GitLab development server
1. After the branch is merged into master, cherry pick the commit(s) into the current stable branch
1. In a separate commit in the stable branch, update the VERSION and CHANGELOG
1. Create an annotated tag vX.X.X for CE and another patch release for EE
1. Make sure that the build has passed and no tests are failing
1. Push the code and the tags to all the CE and EE repositories
1. Apply the patch to GitLab Cloud and the private GitLab development server
1. Send tweets about the release from @gitlabhq, tweet should include the most important feature that the release is addressing as well as the link to the changelog
1. Build new packages with the latest version

