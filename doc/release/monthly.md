# Monthly Release

NOTE: This is a guide for GitLab developers.

# **15th - Code Freeze & Release Manager**

### **1. Stop merging in code, except for important bugfixes**

### **2. Release Manager**

A release manager is selected that coordinates the entire release of this version. The release manager has to make sure all the steps below are done and delegated where necessary. This person should also make sure this document is kept up to date and issues are created and updated.

### **3. Create an overall issue**
Name it "Release x.x.x" for easier searching.

```
15th:

* Update the changelog (#LINK)
* Triage the omnibus-gitlab milestone

16th:

* Merge CE in to EE (#LINK)
* Close the omnibus-gitlab milestone

17th:

* Create x.x.0.rc1 (#LINK)
* Build package for GitLab.com (https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/administration.md#build-a-package)

18th:

* Update GitLab.com with rc1 (#LINK) (https://dev.gitlab.org/cookbooks/chef-repo/blob/master/doc/administration.md#deploy-the-package)
* Regression issue and tweet about rc1 (#LINK)
* Start blog post (#LINK)

21th:

* Do QA and fix anything coming out of it (#LINK)

22nd:

* Release CE and EE (#LINK)

23rd:

* Prepare package for GitLab.com release (#LINK)

24th:

* Deploy to GitLab.com (#LINK)
```

### **4. Update Changelog**

Any changes not yet added to the changelog are added by lead developer and in that merge request the complete team is asked if there is anything missing.

### **5. Take weekend and vacations into account**

Ensure that there is enough time to incorporate the findings of the release candidate, etc.

# **16th - Merge the CE into EE**

Do this via a merge request.

# **17th - Create RC1**

The RC1 release comes with the task to update the installation and upgrade docs. Be mindful that there might already be merge requests for this on GitLab or GitHub.

### **1. Update the installation guide**

1. Check if it references the correct branch `x-x-stable` (doesn't exist yet, but that is okay)
1. Check the [GitLab Shell version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L782)
1. Check the [Git version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L794)
1. There might be other changes. Ask around.

### **2. Create an update guides**

1. Create: CE update guide from previous version. Like `from-6-8-to-6.9`
1. Create: CE to EE update guide in EE repository for latest version.
1. Update: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/6.0-to-6.x.md to latest version.

It's best to copy paste the previous guide and make changes where necessary.
The typical steps are listed below with any points you should specifically look at.

#### 0. Any major changes?

List any major changes here, so the user is aware of them before starting to upgrade. For instance:

- Database updates
- Web server changes
- File structure changes

#### 1. Make backup

#### 2. Stop server

#### 3. Do users need to update dependencies like `git`?

- Check if the [GitLab Shell version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L782) changed since the last release.

- Check if the [Git version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L794) changed since the last release.

#### 4. Get latest code

#### 5. Does GitLab shell need to be updated?

#### 6. Install libs, migrations, etc.

#### 7. Any config files updated since last release?

Check if any of these changed since last release:

- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/nginx/gitlab>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/nginx/gitlab-ssl>
- <https://gitlab.com/gitlab-org/gitlab-shell/commits/master/config.yml.example>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/gitlab.yml.example>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/unicorn.rb.example>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.mysql>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.postgresql>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/initializers/rack_attack.rb.example>
- <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/resque.yml.example>

#### 8. Need to update init script?

Check if the `init.d/gitlab` script changed since last release: <https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/init.d/gitlab>

#### 9. Start application

#### 10. Check application status

### **3. Code quality indicators**

Make sure the code quality indicators are green / good.

- [![Build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

- [![Build Status](https://semaphoreapp.com/api/v1/projects/2f1a5809-418b-4cc2-a1f4-819607579fe7/243338/badge.png)](https://semaphoreapp.com/gitlabhq/gitlabhq) (master branch)

- [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

- [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available)

- [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### **4. Set VERSION**

Change version in VERSION to `x.x.0.rc1`.

### **5. Tag**

Create an annotated tag that points to the version change commit:

```
git tag -a vx.x.0.rc1 -m 'Version x.x.0.rc1'
```

### **6. Create stable branches**

For GitLab EE, append `-ee` to the branch.

`x-x-stable-ee`

```
git checkout master
git pull
git checkout -b x-x-stable
git push <remote> x-x-stable
```

Now developers can use master for merging new features.
So you should use stable branch for future code chages related to release.


# **18th - Release RC1**

### **1. Update GitLab.com**

Merge the RC1 EE code into GitLab.com.
Once the build is green, create a package.
If there are big database migrations consider testing them with the production db on a VM.
Try to deploy in the morning.
It is important to do this as soon as possible, so we can catch any errors before we release the full version.

### **2. Prepare the blog post**

- Start with a complete copy of the [release blog template](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/doc/release_blog_template.md) and fill it out.
- Check the changelog of CE and EE for important changes.
- Create a WIP MR for the blog post
- Ask Dmitriy to add screenshots to the WIP MR.
- Decide with team who will be the MVP user.
- Add a note if there are security fixes: This release fixes an important security issue and we advise everyone to upgrade as soon as possible.
- Assign to one reviewer who will fix spelling issues by editing the branch (can use the online editor)
- After the reviewer is finished the whole team will be mentioned to give their suggestions via line comments

### **3. Create a regressions issue**

On [the GitLab CE issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues/) create an issue titled "GitLab X.X regressions" add the following text:

This is a meta issue to discuss possible regressions in this monthly release and any patch versions.
Please do not raise issues directly in this issue but link to issues that might warrant a patch release.
The decision to create a patch release or not is with the release manager who is assigned to this issue.
The release manager will comment here about the plans for patch releases.

Assign the issue to the release manager and /cc all the core-team members active on the issue tracker. If there are any known bugs in the release add them immediately.

### **4. Tweet**

Tweet about the RC release:

> GitLab x.x.0.rc1 is out. This release candidate is only suitable for testing. Please link regressions issues from LINK_TO_REGRESSION_ISSUE

# **21st - Preparation**

### **1. Pre QA merge**

Merge CE into EE before doing the QA.

### **2. QA**

Create issue on dev.gitlab.org `gitlab` repository, named "GitLab X.X QA" in order to keep track of the progress.

Use the omnibus packages of Enterprise Edition using [this guide](https://dev.gitlab.org/gitlab/gitlab-ee/blob/master/doc/release/manual_testing.md).

**NOTE** Upgrader can only be tested when tags are pushed to all repositories. Do not forget to confirm it is working before releasing. Note that in the issue.

### **3. Fix anything coming out of the QA**

Create an issue with description of a problem, if it is quick fix fix it yourself otherwise contact the team for advice.

**NOTE** If there is a problem that cannot be fixed in a timely manner, reverting the feature is an option! If the feature is reverted,
create an issue about it in order to discuss the next steps after the release.

# **22nd - Release CE and EE**

For GitLab EE, append `-ee` to the branches and tags.

`x-x-stable-ee`

`v.x.x.0-ee`

Note: Merge CE into EE if needed.

### **1. Set VERSION to x.x.x and push**

- Change the GITLAB_SHELL_VERSION file in `master` of the CE repository if the version changed.
- Change the GITLAB_SHELL_VERSION file in `master` of the EE repository if the version changed.
- Change the VERSION file in `master` branch of the CE repository and commit and push to origin.
- Change the VERSION file in `master` branch of the EE repository and commit and push to origin.

### **2. Update installation.md**

Update [installation.md](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md) to the newest version in master.

### **3. Push latest changes from x-x-stable branch to dev.gitlab.org**

```
git checkout -b x-x-stable
git push origin x-x-stable
```

### **4. Build the Omnibus packages**

Follow the [release doc in the Omnibus repository](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md).
This can happen before tagging because Omnibus uses tags in its own repo and SHA1's to refer to the GitLab codebase.

### **5. Create annotated tag vx.x.x**

In `x-x-stable` branch check for the SHA-1 of the commit with VERSION file changed. Tag that commit,

```
git tag -a vx.x.0 -m 'Version x.x.0' xxxxx
```

where `xxxxx` is SHA-1.

### **6. Push the tag and x-x-stable branch to the remotes**

For GitLab CE, push to dev, GitLab.com and GitHub.

For GitLab EE, push to the subscribers repo.

Make sure the branch is marked 'protected' on each of the remotes you pushed to.

```
git push <remote> x-x-stable(-ee)
git push <remote> vx.x.0
```

### **7. Publish packages for new release**

Update `downloads/index.html` and `downloads/archive/index.html` in `www-gitlab-com` repository.

### **8. Publish blog for new release**

Merge the [blog merge request](#1-prepare-the-blog-post) in `www-gitlab-com` repository.

### **9. Tweet to blog**

Send out a tweet to share the good news with the world.
List the most important features and link to the blog post.

Proposed tweet for CE "GitLab X.X is released! It brings *** <link-to-blogpost>"

### **10. Send out the newsletter**

Send out an email to the 'GitLab Newsletter' mailing list on MailChimp.
Replicate the former release newsletter and modify it accordingly.
**Do not forget to edit `Subject line` and regenerate `Plain-Text Email` from HTML source**

Include a link to the blog post and keep it short.

Proposed email text:
"We have released a new version of GitLab. See our blog post(<link>) for more information."


# **23rd - Optional Patch Release**

# **24th - Update GitLab.com**

Merge the stable release into GitLab.com. Once the build is green deploy the next morning.

# **25th - Release GitLab CI**
