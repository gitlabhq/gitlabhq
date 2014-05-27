# Monthly Release

NOTE: This is a guide for GitLab developers.

# **15th - Code Freeze & Release Manager**

### **1. Stop merging in code, except for important bugfixes**

### **2. Release Manager**

A release manager is selected that coordinates the entire release of this version. The release manager has to make sure all the steps below are done and delegated where necessary. This person should also make sure this document is kept up to date and issues are created and updated.

### **3. Update Changelog**

Any changes not yet added to the changelog are added by lead developer and in that merge request the complete team is asked if there is anything missing.

# **18th - Releasing RC1**

The RC1 release comes with the task to update the installation and upgrade docs. Be mindful that there might already be merge requests for this on GitLab or GitHub.

### **1. Create an issue for RC1 release**

Consider naming the issue "Release x.x.x.rc1" to make it easier for later searches.

### **2. Update the installation guide**

1. Check if it references the correct branch `x-x-stable` (doesn't exist yet, but that is okay)
2. Check the [GitLab Shell version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L782)
3. Check the [Git version](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/check.rake#L794)
4. There might be other changes. Ask around.

### **3. Create an update guide**

It's best to copy paste the previous guide and make changes where necessary. The typical steps are listed below with any points you should specifically look at.

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

* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/nginx/gitlab
* https://gitlab.com/gitlab-org/gitlab-shell/commits/master/config.yml.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/gitlab.yml.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/unicorn.rb.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.mysql
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.postgresql

#### 8. Need to update init script?

Check if the init.d/gitlab script changed since last release: https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/init.d/gitlab

#### 9. Start application

#### 10. Check application status

### **4. Code quality indicatiors**
Make sure the code quality indicators are green / good.

* [![build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

* [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://travis-ci.org/gitlabhq/gitlabhq) on travis-ci.org (master branch)

* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

* [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available)

* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### **5. Set VERSION**

Change version in VERSION to x.x.0.rc1


### **6. Tag**

Create an annotated tag that points to the version change commit.
```
git tag -a vx.x.0.rc1 -m 'Version x.x.0.rc1'
```

### **7. Tweet**

Tweet about the RC release:

> GitLab x.x.x.rc1 is out. This is a release candidate intended for testing only. Please let us know if you find regressions.

### **8. Update GitLab.com**

Merge the RC1 code into GitLab.com. Once the build is green, deploy in the morning.

It is important to do this as soon as possible, so we can catch any errors before we release the full version.

# **21st - Preparation **

### **1. Prepare the blog post**

* Check the changelog of CE and EE for important changes. Based on [release blog template](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/doc/release_blog_template.md) fill in the important information.
* Create a WIP MR for the blog post and cc the team so everyone can give feedback.
* Ask Dmitriy to add screenshots to the WIP MR.
* Decide with team who will be the MVP user.
* Add a note if there are security fixes: This release fixes an important security issue and we advise everyone to upgrade as soon as possible.

### **2. Q&A**

Create issue on dev.gitlab.org gitlab repository, named "GitLab X.X release" in order to keep track of the progress.

Use the omnibus packages of Enterprise Edition using [this guide](https://dev.gitlab.org/gitlab/gitlab-ee/blob/master/doc/release/manual_testing.md).

**NOTE** Upgrader can only be tested when tags are pushed to all repositories. Do not forget to confirm it is working before releasing. Note that in the issue.


### **3. Fix anything coming out of the QA**

Create an issue with description of a problem, if it is quick fix fix yourself otherwise contact the team for advice.

# **22nd - Release CE and EE**

For GitLab EE, append -ee to the branches and tags.

`x-x-stable-ee`

`v.x.x.0-ee`

### **1. Create x-x-stable branch and push to the repositories**

```
git checkout master
git pull
git checkout -b x-x-stable
git push <remote> x-x-stable
```

### **2. Build the Omnibus packages**
[Follow this guide](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md)

### **3. Set VERSION to x.x.x and push**

Change the VERSION file in `master` branch of the CE repository and commit.
Cherry-pick into the `x-x-stable` branch of CE.

Change the VERSION file in `master branch of the EE repository and commit.
Cherry-pick into the `x-x-stable-ee` branch of EE.

### **4. Create annotated tag vx.x.x**

In `x-x-stable` branch check for the sha1 of the commit with VERSION file changed. Tag that commit,

```
git tag -a vx.x.0 -m 'Version x.x.0' xxxxx
```

where `xxxxx` is sha1.

### **5. Push the tag**

```
git push origin vx.x.0
```

### **6. Push to remotes**

For GitLab CE, push to dev, GitLab.com and GitHub.

For GitLab EE, push to the subscribers repo.

NOTE: You might not have the rights to push to master on dev. Ask Dmitriy.

### **7. Publish blog for new release**

Merge the [blog merge request](#1-prepare-the-blog-post) in `www-gitlab-com` repository.

### **8. Tweet to blog**

Send out a tweet to share the good news with the world. List the features in short and link to the blog post.

Proposed tweet for CE "GitLab X.X.X CE is released! It brings *** <link-to-blogpost>"

Proposed tweet for EE "GitLab X.X.X EE is released! It brings *** <link-to-blogpost>"

### **9. Send out newsletter**

In mailchimp replicate the former release newsletters to customers / newsletter subscribers (these are two separate things) and modify them accordingly.

Include a link to the blog post and keep it short.

Proposed email for CE: "We have released a new version of GitLab Community Edition and its packages. See our blog post(<link>) for more information."

### **10. Create a regressions issue**

On [the GitLab CE issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues/) create an issue titled "GitLab X.X regressions" add the following text:

This is a meta issue to discuss possible regressions in this monthly release and any patch versions.
Please do not raise issues directly in this issue but link to issues that might warrant a patch release.
The decision to create a patch release or not is with the release manager who is assigned to this issue.
The release manager will comment here about the plans for patch releases.

Assign the issue to the release manager and /cc all the core-team members active on the issue tracker. If there are any known bugs in the release add them immediately.

# **23rd - Optional Patch Release**

# **24th - Update GitLab.com**

Merge the stable release into GitLab.com. Once the build is green deploy the next morning.

# **25th - Release GitLab CI**
