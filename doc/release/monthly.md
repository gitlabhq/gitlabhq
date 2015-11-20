# Monthly Release

NOTE: This is a guide used by the GitLab the company to release GitLab.
As an end user you do not need to use this guide.

The process starts 7 working days before the release.
The release manager doesn't have to perform all the work but must ensure someone is assigned.
The current release manager must schedule the appointment of the next release manager.
The new release manager should create overall issue to track the progress.
The release manager should be the only person pushing/merging commits to the x-y-stable branches.

## Release Manager

A release manager is selected that coordinates all releases the coming month,
including the patch releases for previous releases.
The release manager has to make sure all the steps below are done and delegated where necessary.
This person should also make sure this document is kept up to date and issues are created and updated.

## Take vacations into account

The time is measured in weekdays to compensate for weekends.
Do everything on time to prevent problems due to rush jobs or too little testing time.
Make sure that you take into account any vacations of maintainers.
If the release is falling behind immediately warn the team.

## Create an overall issue and follow it

Create an issue in the GitLab CE project. Name it "Release x.x" and tag it with
the `release` label for easier searching. Replace the dates with actual dates
based on the number of workdays before the release. All steps from issue
template are explained below:

```
### Xth: (7 working days before the 22nd)

- [ ] Triage the [Omnibus milestone]

### Xth: (6 working days before the 22nd)

- [ ] Determine QA person and notify this person
- [ ] Check the tasks in [how to rc1 guide](https://dev.gitlab.org/gitlab/gitlabhq/blob/master/doc/release/howto_rc1.md) and delegate tasks if necessary
- [ ] Merge CE `master` into EE `master` via merge request (#LINK)
- [ ] Create CE and EE RC1 versions (#LINK)
- [ ] Build RC1 packages

### Xth: (5 working days before the 22nd)

- [ ] Do QA and fix anything coming out of it (#LINK)
- [ ] Close the [Omnibus milestone]
- [ ] Prepare the [blog post]

### Xth: (4 working days before the 22nd)

- [ ] Update GitLab.com with RC1
- [ ] Create the regression issue in the CE issue tracker:

    ```
    This is a meta issue to index possible regressions in this monthly release
    and any patch versions.

    Please do not raise or discuss issues directly in this issue but link to
    issues that might warrant a patch release. If there is a Merge Request
    that fixes the issue, please link to that as well.

    Please only post one regression issue and/or merge request per comment.
    Comments will be updated by the release manager as they are addressed.
    ```

- [ ] Tweet about RC1 release:

    ```
    GitLab x.y.0.rc1 is available: https://packages.gitlab.com/gitlab/unstable
    Use at your own risk. Please link regressions issues from
    LINK_TO_REGRESSION_ISSUE
    ```

### Xth: (3 working days before the 22nd)

- [ ] Merge `x-y-stable` into `x-y-stable-ee`
- [ ] Check that everyone is mentioned on the [blog post] using `@all`

### Xth: (2 working days before the 22nd)

- [ ] Check that MVP is added to the [MVP page]

### Xth: (1 working day before the 22nd)

- [ ] Merge `x-y-stable` into `x-y-stable-ee`
- [ ] Create CE and EE release candidates
- [ ] Create Omnibus tags and build packages for the latest release candidates
- [ ] Update GitLab.com with the latest RC

### 22nd before 1200 CET:

Release before 1200 CET / 2AM PST, to make sure the majority of our users
get the new version on the 22nd and there is sufficient time in the European
workday to quickly fix any issues.

- [ ] Merge `x-y-stable` into `x-y-stable-ee`
- [ ] Create the 'x.y.0' tag with the [release tools](https://dev.gitlab.org/gitlab/release-tools)
- [ ] Create the 'x.y.0' version on version.gitlab.com
- [ ] Try to do before 1100 CET: Create and push Omnibus tags for x.y.0 (will auto-release the packages)
- [ ] Try to do before 1200 CET: Publish the release [blog post]
- [ ] Tweet about the release
- [ ] Schedule a second Tweet of the release announcement with the same text at 1800 CET / 8AM PST

[Omnibus milestone]: LINK_TO_OMNIBUS_MILESTONE
[blog post]: LINK_TO_WIP_BLOG_POST
[MVP page]: https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/source/mvp/index.html
```

- - -

## Update changelog

Any changes not yet added to the changelog are added by lead developer and in that merge request the complete team is
asked if there is anything missing.

There are three changelogs that need to be updated: CE, EE and CI.

## Create RC1 (CE, EE, CI)

[Follow this How-to guide](howto_rc1.md) to create RC1.

## Prepare CHANGELOG for next release

Once the stable branches have been created, update the CHANGELOG in `master` with the upcoming version, usually X.X.X.pre.

On creating the stable branches, notify the core team and developers.

## QA

Create issue on dev.gitlab.org `gitlab` repository, named "GitLab X.X QA" in order to keep track of the progress.

Use the omnibus packages created for RC1 of Enterprise Edition using [this guide](https://dev.gitlab.org/gitlab/gitlab-ee/blob/master/doc/release/manual_testing.md).

**NOTE** Upgrader can only be tested when tags are pushed to all repositories. Do not forget to confirm it is working before releasing. Note that in the issue.

#### Fix anything coming out of the QA

Create an issue with description of a problem, if it is quick fix fix it yourself otherwise contact the team for advice.

**NOTE** If there is a problem that cannot be fixed in a timely manner, reverting the feature is an option! If the feature is reverted,
create an issue about it in order to discuss the next steps after the release.

## Update GitLab.com with RC1

Use the omnibus EE packages created for RC1.
If there are big database migrations consider testing them with the production db on a VM.
Try to deploy in the morning.
It is important to do this as soon as possible, so we can catch any errors before we release the full version.

## Create a regressions issue

On [the GitLab CE issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues/) create an issue titled "GitLab X.X regressions" add the following text:

This is a meta issue to discuss possible regressions in this monthly release and any patch versions.
Please do not raise issues directly in this issue but link to issues that might warrant a patch release.
The decision to create a patch release or not is with the release manager who is assigned to this issue.
The release manager will comment here about the plans for patch releases.

Assign the issue to the release manager and at mention all members of gitlab core team. If there are any known bugs in the release add them immediately.

## Tweet about RC1

Tweet about the RC release:

> GitLab x.x.0.rc1 is out. This release candidate is only suitable for testing. Please link regressions issues from LINK_TO_REGRESSION_ISSUE

## Prepare the blog post

1. The blog post template for this release should already exist and might have comments that were added during the month.
1. Fill out as much of the blog post template as you can.
1. Make sure the blog post contains information about the GitLab CI release.
1. Check the changelog of CE and EE for important changes.
1. Also check the CI changelog
1. Add a proposed tweet text to the blog post WIP MR description.
1. Create a WIP MR for the blog post
1. Make sure merge request title starts with `WIP` so it can not be accidently merged until ready.
1. Ask Dmitriy (or a team member with OS X) to add screenshots to the WIP MR.
1. Decide with core team who will be the MVP user.
1. Create WIP MR for adding MVP to MVP page on website
1. Add a note if there are security fixes: This release fixes an important security issue and we advise everyone to upgrade as soon as possible.
1. Create a merge request on [GitLab.com](https://gitlab.com/gitlab-com/www-gitlab-com/tree/master)
1. Assign to one reviewer who will fix spelling issues by editing the branch (either with a git client or by using the online editor)
1. Comment to the reviewer: '@person Please mention the whole team as soon as you are done (3 workdays before release at the latest)'
1. Create a new merge request with complete copy of the [release blog template](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/doc/release_blog_template.md) for the next release using the branch name `release-x-x-x`.

## Create CE, EE, CI stable versions

Get release tools

```
git clone git@dev.gitlab.org:gitlab/release-tools.git
cd release-tools
```

Bump version, create release tag and push to remotes:

```
bundle exec rake release["x.x.0"]
```

This will create correct version and tag and push to all CE, EE and CI remotes.

Update [installation.md](/doc/install/installation.md) to the newest version in master.


## Create Omnibus tags and build packages

Follow the [release doc in the Omnibus repository](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md).
This can happen before tagging because Omnibus uses tags in its own repo and SHA1's to refer to the GitLab codebase.

## Update GitLab.com with the stable version

- Deploy the package (should not need downtime because of the small difference with RC1)
- Deploy the package for gitlab.com/ci

## Release CE, EE and CI

__1. Publish packages for new release__

Update `downloads/index.html` and `downloads/archive/index.html` in `www-gitlab-com` repository.

__2. Publish blog for new release__

Doublecheck the everyone has been mentioned in the blog post.
Merge the [blog merge request](#1-prepare-the-blog-post) in `www-gitlab-com` repository.

__3. Tweet to blog__

Send out a tweet to share the good news with the world.
List the most important features and link to the blog post.

Proposed tweet "Release of GitLab X.X & CI Y.Y! FEATURE, FEATURE and FEATURE &lt;link-to-blog-post&gt; #gitlab"

Consider creating a post on Hacker News.

## Release new AMIs

[Follow this guide](https://dev.gitlab.org/gitlab/AMI/blob/master/README.md)

## Create a WIP blogpost for the next release

Create a WIP blogpost using [release blog template](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/doc/release_blog_template.md).
