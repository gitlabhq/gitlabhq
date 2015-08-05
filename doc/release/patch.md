# Things to do when doing a patch release

NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

## When to do a patch release

Do a patch release when there is a critical regression that needs to be addresses before the next monthly release.

Otherwise include it in the monthly release and note there was a regression fix in the release announcement.

## Release Procedure

### Preparation

1. Verify that the issue can be reproduced
1. Note in the 'GitLab X.X regressions' that you will create a patch
1. Create an issue on private GitLab development server
1. Name the issue "Release X.X.X CE and X.X.X EE", this will make searching easier
1. Fix the issue on a feature branch, do this on the private GitLab development server
1. If it is a security issue, then assign it to the release manager and apply a 'security' label
1. Consider creating and testing workarounds
1. After the branch is merged into master, cherry pick the commit(s) into the current stable branch
1. Make sure that the build has passed and all tests are passing
1. In a separate commit in the master branch update the CHANGELOG
1. For EE, update the CHANGELOG-EE if it is EE specific fix. Otherwise, merge the stable CE branch and add to CHANGELOG-EE "Merge community edition changes for version X.X.X"
1. Merge CE stable branch into EE stable branch


### Bump version

Get release tools

```
git clone git@dev.gitlab.org:gitlab/release-tools.git
cd release-tools
```

Bump all versions in stable branch, even if the changes affect only EE, CE, or CI. Since all the versions are synced now,
it doesn't make sense to say upgrade CE to 7.2, EE to 7.3 and CI to 7.1.

Create release tag and push to remotes:

```
bundle exec rake release["x.x.x"]
```

## Release

1. [Build new packages with the latest version](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md)
1. Apply the patch to GitLab.com and the private GitLab development server
1. Apply the patch to ci.gitLab.com and the private GitLab CI development server
1. Create and publish a blog post, see [patch release blog template](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/doc/patch_release_blog_template.md)
1. Send tweets about the release from `@gitlab`, tweet should include the most important feature that the release is addressing and link to the blog post
1. Note in the 'GitLab X.X regressions' issue that the patch was published (CE only)
1. Create the 'x.y.0' version on version.gitlab.com
1. [Create new AMIs](https://dev.gitlab.org/gitlab/AMI/blob/master/README.md)
1. Create a new patch release issue for the next potential release