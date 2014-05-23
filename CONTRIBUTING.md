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

To get support for your particular problem please use the channels as detailed in the [getting help section of the readme](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md#getting-help). Professional [support subscriptions](http://www.gitlab.com/subscription/) and [consulting services](http://www.gitlab.com/consultancy/) are available from [GitLab.com](http://www.gitlab.com/).

The [issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues) is only for obvious errors in the latest [stable or development release of GitLab](MAINTENANCE.md).
If something is wrong but it is not a regression compared to older versions of GitLab please do not open an issue but a feature request.
When submitting an issue please conform to the issue submission guidelines listed below.
Not all issues will be addressed and your issue is more likely to be addressed if you submit a merge request which partially or fully addresses the issue.

Issues can be filed either at [gitlab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues) or [github.com](https://github.com/gitlabhq/gitlabhq/issues).

Do not use the issue tracker for feature requests.
We have a specific [feature request forum](http://feedback.gitlab.com) for this purpose.
Please keep feature requests as small and simple as possible, complex ones might be edited to make them small and simple.

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

We welcome merge requests with fixes and improvements to GitLab code, tests, and/or documentation. The features we would really like a merge request for are listed with the [status 'accepting merge requests' on our feature request forum](http://feedback.gitlab.com/forums/176466-general/status/796455) but other improvements are also welcome. If you want to add a new feature that is not marked it is best to first create a feedback issue (if there isn't one already) and leave a comment asking for it to be marked accepting merge requests. Please include screenshots or wireframes if the feature will also change the UI.

Merge requests can be filed either at [gitlab.com](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests) or [github.com](https://github.com/gitlabhq/gitlabhq/pulls).

### Merge request guidelines

If you can, please submit a merge request with the fix or improvements including tests. If you don't know how to fix the issue but can write a test that exposes the issue we will accept that as well. In general bug fixes that include a regression test are merged quickly while new features without proper tests are least likely to receive timely feedback. The workflow to make a merge request is as follows:

1. Fork the project on GitLab Cloud
1. Create a feature branch
1. Write [tests](README.md#run-the-tests) and code
1. Add your changes to the [CHANGELOG](CHANGELOG)
1. If you have multiple commits please combine them into one commit by [squashing them](http://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a merge request (MR) to the master branch
1. The MR title should describes the change you want to make
1. The MR description should give a motive for your change and the method you used to achieve it
1. If the MR changes the UI it should include before and after screenshots
1. If the MR changes CSS classes please include the list of affected pages `grep css-class ./app -R`
1. Link relevant [issues](https://gitlab.com/gitlab-org/gitlab-ce/issues) and/or [feature requests](http://feedback.gitlab.com/) from the merge request description and leave a comment on them with a link back to the MR
1. Be prepared to answer questions and incorporate feedback even if requests for this arrive weeks or months after your MR submittion
1. If your MR touches code that executes shell commands, make sure it adheres to the [shell command guidelines](    doc/development/shell_commands.md).

The **official merge window** is in the beginning of the month from the 1st to the 7th day of the month. The best time to submit a MR and get feedback fast. Before this time the GitLab B.V. team is still dealing with work that is created by the monthly release such as assisting subscribers with upgrade issues, the release of Enterprise Edition and the upgrade of GitLab Cloud. After the 7th it is already getting closer to the release date of the next version. This means there is less time to fix the issues created by merging large new features.

Please keep the change in a single MR **as small as possible**. If you want to contribute a large feature think very hard what the minimum viable change is. Can you split functionality? Can you only submit the backend/API code? Can you start with a very simple UI? The smaller a MR is the more likely it is it will be merged, after that you can send more MR's to enhance it.

For examples of feedback on merge requests please look at already [closed merge requests](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests?assignee_id=&label_name=&milestone_id=&scope=&sort=&state=closed). Please ensure that your merge request meets the following contribution acceptance criteria.

**Please format your merge request description as follows:**

1. What does this MR do?
2. Are there points in the code the reviewer needs to double check?
3. Why was this MR needed?
4. What are the relevant issue numbers / [Feature requests](http://feedback.gitlab.com/)?
5. Screenshots (If appropiate)

## Contribution acceptance criteria

1. The change is as small as possible (see the above paragraph for details)
1. Include proper tests and make all tests pass (unless it contains a test exposing a bug in existing code)
1. Can merge without problems (if not please use: `git rebase master`)
1. Does not break any existing functionality
1. Fixes one specific issue or implements one specific feature (do not combine things, send separate merge requests if needed)
1. Keeps the GitLab code base clean and well structured
1. Contains functionality we think other users will benefit from too
1. Doesn't add configuration options since they complicate future changes
1. Contains a single commit (please use `git rebase -i` to squash commits)
1. It conforms to the following style guides

## Style guides
1. [Ruby](https://github.com/bbatsov/ruby-style-guide)
1. [Rails](https://github.com/bbatsov/rails-style-guide)
1. [Formatting](https://github.com/thoughtbot/guides/tree/master/style#formatting)
1. [Naming](https://github.com/thoughtbot/guides/tree/master/style#naming) 
1. [Testing](https://github.com/thoughtbot/guides/tree/master/style#testing)
1. [CoffeeScript](https://github.com/thoughtbot/guides/tree/master/style#coffeescript)
1. [Shell commands](doc/development/shell_commands.md)
1. [Markdown](http://www.cirosantilli.com/markdown-styleguide)
