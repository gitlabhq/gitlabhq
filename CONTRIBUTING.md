# Contribute to GitLab

This guide details how contribute to GitLab.

If you want to know how the GitLab team handles contributions have a look at [the GitLab contributing process](PROCESS.md).

## Contributor license agreement

By submitting code as an individual you agree to the [individual contributor license agreement](doc/legal/individual_contributor_license_agreement.md). By submitting code as an entity you agree to the [corporate contributor license agreement](doc/legal/corporate_contributor_license_agreement.md).

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to support@gitlab.com, also see the [disclosure section on the GitLab.com website](http://www.gitlab.com/disclosure/). Please do NOT create publicly viewable issues for suspected security vulnerabilities.

## Closing policy for issues and merge requests

GitLab is a popular open source project and the capacity to deal with issues and merge requests is limited. Out of respect for our volunteers, issues and merge requests not in line with the guidelines listed in this document may be closed without notice.

Please treat our volunteers with courtesy and respect, it will go a long way towards getting your issue resolved.

Issues and merge requests should be in English and contain appropriate language for audiences of all ages.

## Issue tracker

To get support for your particular problem please use the channels as detailed in the getting help section of [the readme](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md). Professional [support subscriptions](http://www.gitlab.com/subscription/) and [consulting services](http://www.gitlab.com/consultancy/) are available from [GitLab.com](http://www.gitlab.com/).

The [issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues) is only for obvious bugs or misbehavior in the latest [stable or development release of GitLab](MAINTENANCE.md). When submitting an issue please conform to the issue submission guidelines listed below. Not all issues will be addressed and your issue is more likely to be addressed if you submit a merge request which partially or fully addresses the issue.

Do not use the issue tracker for feature requests. We have a specific [feedback and suggestions forum](http://feedback.gitlab.com) for this purpose.

Please send a merge request with a tested solution or a merge request with a failing test instead of opening an issue if you can. If you're unsure where to post, post to the [mailing list](https://groups.google.com/forum/#!forum/gitlabhq) or [Stack Overflow](http://stackoverflow.com/questions/tagged/gitlab) first. There are a lot of helpful GitLab users there who may be able to help you quickly. If your particular issue turns out to be a bug, it will find its way from there.

### Issue tracker guidelines

**[Search the issues](https://gitlab.com/gitlab-org/gitlab-ce/issues)** for similar entries before submitting your own, there's a good chance somebody else had the same issue. Show your support with `:+1:` and/or join the discussion. Please submit issues in the following format (as the first post):

1. **Summary:** Summarize your issue in one sentence (what goes wrong, what did you expect to happen)
2. **Steps to reproduce:** How can we reproduce the issue, preferably on the [GitLab development virtual machine with vagrant](https://gitlab.com/gitlab-org/cookbook-gitlab/blob/master/doc/development.md) (start your issue with: `vagrant destroy && vagrant up && vagrant ssh`)
3. **Expected behavior:** Describe your issue in detail
4. **Observed behavior**
5. **Relevant logs and/or screenshots:** Please use code blocks (\`\`\`) to format console output, logs, and code as it's very hard to read otherwise.
6. **Output of checks**
    * Results of GitLab [Application Check](doc/install/installation.md#check-application-status) (`sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production`); we will only investigate if the tests are passing
    * Version of GitLab you are running; we will only investigate issues in the latest stable and development releases as per the [maintenance policy](MAINTENANCE.md)
    * Add the last commit sha1 of the GitLab version you used to replicate the issue (obtainable from the help page)
    * Describe your setup (use relevant parts from `sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production`)
7. **Possible fixes**: If you can, link to the line of code that might be responsible for the problem

## Merge requests

We welcome merge requests with fixes and improvements to GitLab code, tests, and/or documentation. The features we would really like a merge request for are listed with the [status 'accepting merge/merge requests' on our feedback forum](http://feedback.gitlab.com/forums/176466-general/status/796455) but other improvements are also welcome.

### Merge request guidelines

If you can, please submit a merge request with the fix or improvements including tests. If you don't know how to fix the issue but can write a test that exposes the issue we will accept that as well. In general bug fixes that include a regression test are merged quickly while new features without proper tests are least likely to receive timely feedback. The workflow to make a merge request is as follows:

1. Fork the project on GitLab Cloud
1. Create a feature branch
1. Write [tests](README.md#run-the-tests) and code
1. Add your changes to the [CHANGELOG](CHANGELOG)
1. If you have multiple commits please combine them into one commit by [squashing them](http://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a merge request (MR)
1. The MR title should describes the change you want to make
1. The MR description should give a motive for your change and the method you used to achieve it
1. If the MR changes the UI it should include before and after screenshots
1. Link relevant [issues](https://gitlab.com/gitlab-org/gitlab-ce/issues) and/or [feedback items](http://feedback.gitlab.com/) from the merge request description and leave a comment on them with a link back to the MR
1. Be prepared to answer questions and incorporate feedback even if requests for this arrive weeks or months after your MR submittion

Please keep the change in a single MR **as small as possible**. If you want to contribute a large feature think very hard what the minimum viable change is. Can you split functionality? Can you only submit the backend/API code? Can you start with a very simple UI? The smaller a MR is the more likely it is it will be merged, after that you can send more MR's to enhance it.

The **official merge window** is in the beginning of the month from the 1st to the 7th day of the month.
The best time to submit a MR and get feedback fast.
Before this time the GitLab.com team is still dealing with work that is created by the monthly release such as assisting subscribers with upgrade issues, the release of Enterprise Edition and the upgrade of GitLab Cloud.
After the 7th it is already getting closer to the release date of the next version.
This means there is less time to fix the issues created by merging large new features.

We will accept a merge requests if it:

* Includes proper tests and all tests pass (unless it contains a test exposing a bug in existing code)
* Can be merged without problems (if not please use: `git rebase master`)
* Do not break any existing functionality
* Conforms to the [Ruby](https://github.com/bbatsov/ruby-style-guide) and [Rails](https://github.com/bbatsov/rails-style-guide) style guides and best practices
* Fixes one specific issue or implements one specific feature (do not combine things, send separate merge requests if needed)
* Keeps the GitLab code base clean and well structured
* Contains functionality we think other users will benefit from too
* Doesn't add configuration options since these complicate future changes
* Contains a single commit (please use `git rebase -i` to squash commits)

For examples of feedback on merge requests please look at already [closed merge requests](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests?assignee_id=&label_name=&milestone_id=&scope=&sort=&state=closed).
