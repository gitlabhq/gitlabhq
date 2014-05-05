# Monthly Release
NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

# Release Schedule

After making the release branch new commits are cherry-picked from master. When the release gets closer we get more selective what is cherry-picked. The days of the month are approximately as follows:

* 1-7th: Official merge window (see contributing guide).
* 8-14th: Work on bugfixes, sponsored features and GitLab EE.
* 15th: Code freeze
* 18th: Release Candidate 1
* 20st: Optional release candidate 2
* 22nd: Release
* 23nd: Optional patch releases
* 24-end of month: Release GitLab EE and GitLab CI

# **15th - Code Freeze & Release Manager**

### **1. Stop merging in code, except for important bugfixes**

### **2. Release Manager**

A release manager is selected that coordinates the entire release of this version. The release manager has to make sure all the steps below are done and delegated where necessary. This person should also make sure this document is kept up to date and issues are created and updated.

# **18th - Releasing RC1**

> Yo dawg, I heard you like releases..

The RC1 release comes with the task to update the installation and upgrade docs. Be mindful that there might already be merge requests for this on GitLab or GitHub.

### **1. Create an issue for RC1 release**

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

Set VERSION tot x.x.0.rc1


### **6. Tag**

Create an annotated tag that points to the version change commit.
```
git tag -a vx.x.0.rc1 -m 'Version x.x.0.rc1'
```

### **7. Tweet**

Tweet about the RC release. Make sure to explain what a RC is.

### **8. Update Cloud**

Merge the RC1 code into Cloud. Once the build is green, deploy in the morning.

It is important to do this as soon as possible, so we can catch any errors before we release the full version.


# **22nd - Release CE**

After making the release branch new commits are cherry-picked from master. When the release gets closer we get more selective what is cherry-picked. The days of the month are approximately as follows:


### **1. Create x-x-stable branch and push to the repositories**

```
git checkout master
git pull
git checkout -b x-x-stable
git push <remote> x-x-stable
```

### **2. Build the Omnibus packages**
[Follow this guide](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/release.md)

### **3. QA**
Use the omnibus packages to test the following:

### **4. Fix anything coming out of the QA**

### **5. Set VERSION to x.x.0**

### **6. Create annotated tag vx.x.0**
```
git tag -a vx.x.0 -m 'Version x.x.0'
```

### **7. Push VERSION + Tag to master, merge into x-x-stable**
```
git push origin master
```

Next, merge the VERSION into the x-x-stable branch.

### **8. Publish blog for new release**
* Mention what GitLab is on the second line: GitLab is open source software to collaborate on code.
* Select and thank the the Most Valuable Person (MVP) of this release.
* Add a note if there are security fixes: This release fixes an important security issue and we advise everyone to upgrade as soon as possible.

### **9. Tweet to blog**

Send out a tweet to share the good news with the world. For a major/minor release, list the features in short and link to the blog post.

For a RC, make sure to explain what a RC is.

A patch release tweet should specify the fixes it brings and link to the corresponding blog post.


# **22nd - Release EE**

# **23rd - Optional Patch Release**

# **25th - Release GitLab CI**
