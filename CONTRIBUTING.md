# Contribute to GitLab

Thank you for your interest in contributing to GitLab.
This guide details how contribute to GitLab in a way that is efficient for everyone.
If you have read this guide and want to know how the GitLab core-team operates please see [the GitLab contributing process](PROCESS.md).

## Contributor license agreement

By submitting code as an individual you agree to the [individual contributor license agreement](doc/legal/individual_contributor_license_agreement.md). By submitting code as an entity you agree to the [corporate contributor license agreement](doc/legal/corporate_contributor_license_agreement.md).

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to support@gitlab.com, also see the [disclosure section on the GitLab.com website](https://about.gitlab.com/disclosure/). Please do NOT create publicly viewable issues for suspected security vulnerabilities.

## Closing policy for issues and merge requests

GitLab is a popular open source project and the capacity to deal with issues and merge requests is limited. Out of respect for our volunteers, issues and merge requests not in line with the guidelines listed in this document may be closed without notice.

Please treat our volunteers with courtesy and respect, it will go a long way towards getting your issue resolved.

Issues and merge requests should be in English and contain appropriate language for audiences of all ages.

## Helping others

Please help other GitLab users when you can.
The channnels people will reach out on can be found on the [getting help page](https://about.gitlab.com/getting-help/).
Sign up for the mailinglist, answer GitLab questions on StackOverflow or respond in the irc channel.
You can also sign up on [CodeTriage](http://www.codetriage.com/gitlabhq/gitlabhq) to help with one issue every day.

## Issue tracker

To get support for your particular problem please use the [getting help channels](https://about.gitlab.com/getting-help/).

The [GitLab CE issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues) is only for obvious errors in the latest [stable or development release of GitLab](MAINTENANCE.md). If something is wrong but it is not a regression compared to older versions of GitLab please do not open an issue but a feature request. When submitting an issue please conform to the issue submission guidelines listed below. Not all issues will be addressed and your issue is more likely to be addressed if you submit a merge request which partially or fully addresses the issue.

Do not use the issue tracker for feature requests. We have a specific [feature request forum](http://feedback.gitlab.com) for this purpose. Please keep feature requests as small and simple as possible, complex ones might be edited to make them small and simple.

Please send a merge request with a tested solution or a merge request with a failing test instead of opening an issue if you can. If you're unsure where to post, post to the [mailing list](https://groups.google.com/forum/#!forum/gitlabhq) or [Stack Overflow](https://stackoverflow.com/questions/tagged/gitlab) first. There are a lot of helpful GitLab users there who may be able to help you quickly. If your particular issue turns out to be a bug, it will find its way from there.

### Issue tracker guidelines

**[Search the issues](https://gitlab.com/gitlab-org/gitlab-ce/issues)** for similar entries before submitting your own, there's a good chance somebody else had the same issue. Show your support with `:+1:` and/or join the discussion. Please submit issues in the following format (as the first post):

1. **Summary:** Summarize your issue in one sentence (what goes wrong, what did you expect to happen)
1. **Steps to reproduce:** How can we reproduce the issue
1. **Expected behavior:** Describe your issue in detail
1. **Observed behavior**
1. **Relevant logs and/or screenshots:** Please use code blocks (\`\`\`) to format console output, logs, and code as it's very hard to read otherwise.
1. **Output of checks**
    * Results of GitLab [Application Check](doc/install/installation.md#check-application-status) (`sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production SANITIZE=true`); we will only investigate if the tests are passing
    * Version of GitLab you are running; we will only investigate issues in the latest stable and development releases as per the [maintenance policy](MAINTENANCE.md)
    * Add the last commit SHA-1 of the GitLab version you used to replicate the issue (obtainable from the help page)
    * Describe your setup (use relevant parts from `sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production`)
1. **Possible fixes**: If you can, link to the line of code that might be responsible for the problem

## Merge requests

We welcome merge requests with fixes and improvements to GitLab code, tests, and/or documentation. The features we would really like a merge request for are listed with the [status 'accepting merge requests' on our feature request forum](http://feedback.gitlab.com/forums/176466-general/status/796455) but other improvements are also welcome. If you want to add a new feature that is not marked it is best to first create a feedback issue (if there isn't one already) and leave a comment asking for it to be marked accepting merge requests. Please include screenshots or wireframes if the feature will also change the UI.

Merge requests can be filed either at [gitlab.com](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests) or [github.com](https://github.com/gitlabhq/gitlabhq/pulls).

If you are new to GitLab development (or web development in general), search for the label `easyfix` ([gitlab.com](https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name=easyfix), [github](https://github.com/gitlabhq/gitlabhq/labels/easyfix)). Those are issues easy to fix, marked by the GitLab core-team. If you are unsure how to proceed but want to help, mention one of the core-team members to give you a hint.

To start with GitLab download the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit) and see [Development section](doc/development/README.md) in the help file.

### Merge request guidelines

If you can, please submit a merge request with the fix or improvements including tests. If you don't know how to fix the issue but can write a test that exposes the issue we will accept that as well. In general bug fixes that include a regression test are merged quickly while new features without proper tests are least likely to receive timely feedback. The workflow to make a merge request is as follows:

1. Fork the project into your personal space on GitLab.com
1. Create a feature branch
1. Write [tests](https://gitlab.com/gitlab-org/gitlab-development-kit#running-the-tests) and code
1. Add your changes to the [CHANGELOG](CHANGELOG)
1. If you are changing the README, some documentation or other things which have no effect on the tests, add `[ci skip]` somewhere in the commit message
1. If you have multiple commits please combine them into one commit by [squashing them](https://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits)
1. Push the commit to your fork
1. Submit a merge request (MR) to the master branch
1. The MR title should describe the change you want to make
1. The MR description should give a motive for your change and the method you used to achieve it
1. If the MR changes the UI it should include before and after screenshots
1. If the MR changes CSS classes please include the list of affected pages `grep css-class ./app -R`
1. Link relevant [issues](https://gitlab.com/gitlab-org/gitlab-ce/issues) and/or [feature requests](http://feedback.gitlab.com/) from the merge request description and leave a comment on them with a link back to the MR
1. Be prepared to answer questions and incorporate feedback even if requests for this arrive weeks or months after your MR submission
1. If your MR touches code that executes shell commands, make sure it adheres to the [shell command guidelines](    doc/development/shell_commands.md).
1. Also have a look at the [shell command guidelines](doc/development/shell_commands.md) if your code reads or opens files, or handles paths to files on disk.
1. If your code creates new files on disk please read the [shared files guidelines](doc/development/shared_files.md).

The **official merge window** is in the beginning of the month from the 1st to the 7th day of the month. The best time to submit a MR and get feedback fast.
Before this time the GitLab B.V. team is still dealing with work that is created by the monthly release such as regressions requiring patch releases.
After the 7th it is already getting closer to the release date of the next version. This means there is less time to fix the issues created by merging large new features.

Please keep the change in a single MR **as small as possible**. If you want to contribute a large feature think very hard what the minimum viable change is. Can you split functionality? Can you only submit the backend/API code? Can you start with a very simple UI? Can you do part of the refactor? The increased reviewability of small MR's that leads to higher code quality is more important to us than having a minimal commit log. The smaller a MR is the more likely it is it will be merged (quickly), after that you can send more MR's to enhance it.

For examples of feedback on merge requests please look at already [closed merge requests](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests?assignee_id=&label_name=&milestone_id=&scope=&sort=&state=closed). If you would like quick feedback on your merge request feel free to mention one of the Merge Marshalls of [the core-team](https://about.gitlab.com/core-team/). Please ensure that your merge request meets the contribution acceptance criteria.

## Definition of done

If you contribute to GitLab please know that changes involve more than just code.
We have the following [definition of done](http://guide.agilealliance.org/guide/definition-of-done.html).
Please ensure you support the feature you contribute through all of these steps.

1. Description explaning the relevancy (see following item)
1. Working and clean code that is commented where needed
1. Unit and integration tests that pass on the CI server
1. Documented in the /doc directory
1. Changelog entry added
1. Reviewed and any concerns are addressed
1. Merged by the project lead
1. Added to the release blog article
1. Added to [the website](https://gitlab.com/gitlab-com/www-gitlab-com/) if relevant
1. Community questions answered
1. Answers to questions radiated (in docs/wiki/etc.)

If you add a dependency in GitLab (such as an operating system package) please consider updating the following and note the applicability of each in your merge request:

1. Note the addition in the release blog post (create one if it doesn't exist yet) https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/
1. Upgrade guide, for example https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/7.5-to-7.6.md
1. Upgrader https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/upgrader.md#2-run-gitlab-upgrade-tool
1. Installation guide https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md#1-packages-dependencies
1. GitLab Development Kit https://gitlab.com/gitlab-org/gitlab-development-kit
1. Test suite https://gitlab.com/gitlab-org/gitlab-ci/blob/master/doc/examples/configure_a_runner_to_run_the_gitlab_ce_test_suite.md
1. Omnibus package creator https://gitlab.com/gitlab-org/omnibus-gitlab

## Merge request description format

1. What does this MR do?
1. Are there points in the code the reviewer needs to double check?
1. Why was this MR needed?
1. What are the relevant issue numbers / [Feature requests](http://feedback.gitlab.com/)?
1. Screenshots (if relevant)

## Contribution acceptance criteria

1. The change is as small as possible (see the above paragraph for details)
1. Include proper tests and make all tests pass (unless it contains a test exposing a bug in existing code)
1. All tests have to pass, if you suspect a failing CI build is unrelated to your contribution ask for tests to be restarted. See [the CI setup document](http://doc.gitlab.com/ce/development/ci_setup.html) on who you can ask for test restart.
1. Initially contains a single commit (please use `git rebase -i` to squash commits)
1. Can merge without problems (if not please merge `master`, never rebase commits pushed to the remote server)
1. Does not break any existing functionality
1. Fixes one specific issue or implements one specific feature (do not combine things, send separate merge requests if needed)
1. Migrations should do only one thing (eg: either create a table, move data to a new table or remove an old table) to aid retrying on failure
1. Keeps the GitLab code base clean and well structured
1. Contains functionality we think other users will benefit from too
1. Doesn't add configuration options since they complicate future changes
1. Changes after submitting the merge request should be in separate commits (no squashing). You will be asked to squash when the review is over, before merging.
1. It conforms to the following style guides.
    If your change touches a line that does not follow the style,
    modify the entire line to follow it. This prevents linting tools from generating warnings.
    Don't touch neighbouring lines. As an exception, automatic mass refactoring modifications
    may leave style non-compliant.

## Style guides

1.  [Ruby](https://github.com/bbatsov/ruby-style-guide).
    Important sections include [Source Code Layout](https://github.com/bbatsov/ruby-style-guide#source-code-layout)
    and [Naming](https://github.com/bbatsov/ruby-style-guide#naming). Use:
    - multi-line method chaining style **Option B**: dot `.` on previous line
    - string literal quoting style **Option A**: single quoted by default
1.  [Rails](https://github.com/bbatsov/rails-style-guide)
1.  [Testing](https://github.com/thoughtbot/guides/tree/master/style#testing)
1.  [CoffeeScript](https://github.com/thoughtbot/guides/tree/master/style#coffeescript)
1.  [Shell commands](doc/development/shell_commands.md) created by GitLab contributors to enhance security
1.  [Markdown](http://www.cirosantilli.com/markdown-styleguide)
1.  [Database Migrations](doc/development/migration_style_guide.md)
1.  [Documentation styleguide](doc_styleguide.md)
1.  Interface text should be written subjectively instead of objectively. It should be the gitlab core team addressing a person. It should be written in present time and never use past tense (has been/was). For example instead of "prohibited this user from being saved due to the following errors:" the text should be "sorry, we could not create your account because:". Also these [excellent writing guidelines](https://github.com/NARKOZ/guides#writing).

This is also the style used by linting tools such as [RuboCop](https://github.com/bbatsov/rubocop), [PullReview](https://www.pullreview.com/) and [Hound CI](https://houndci.com).

## Code of conduct

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior can be reported by emailing contact@gitlab.com

This Code of Conduct is adapted from the [Contributor Covenant](http://contributor-covenant.org), version 1.1.0, available at [http://contributor-covenant.org/version/1/1/0/](http://contributor-covenant.org/version/1/1/0/)
