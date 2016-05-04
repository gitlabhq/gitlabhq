<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Contribute to GitLab](#contribute-to-gitlab)
    - [Contributor license agreement](#contributor-license-agreement)
    - [Security vulnerability disclosure](#security-vulnerability-disclosure)
    - [Closing policy for issues and merge requests](#closing-policy-for-issues-and-merge-requests)
    - [Helping others](#helping-others)
    - [I want to contribute!](#i-want-to-contribute)
    - [Implement design & UI elements](#implement-design-ui-elements)
        - [Design reference](#design-reference)
        - [UI development kit](#ui-development-kit)
    - [Issue tracker](#issue-tracker)
        - [Feature proposals](#feature-proposals)
        - [Issue tracker guidelines](#issue-tracker-guidelines)
        - [Issue weight](#issue-weight)
        - [Regression issues](#regression-issues)
        - [Technical debt](#technical-debt)
    - [Merge requests](#merge-requests)
        - [Merge request guidelines](#merge-request-guidelines)
        - [Merge request description format](#merge-request-description-format)
        - [Contribution acceptance criteria](#contribution-acceptance-criteria)
    - [Changes for Stable Releases](#changes-for-stable-releases)
    - [Definition of done](#definition-of-done)
    - [Style guides](#style-guides)
    - [Code of conduct](#code-of-conduct)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Contribute to GitLab

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to GitLab in a way that is efficient for everyone.

GitLab comes into two flavors, GitLab Community Edition (CE) our free and open
source edition, and GitLab Enterprise Edition (EE) which is our commercial
edition. Throughout this guide you will see references to CE and EE for
abbreviation.

If you have read this guide and want to know how the GitLab [core team]
operates please see [the GitLab contributing process](PROCESS.md).

## Contributor license agreement

By submitting code as an individual you agree to the
[individual contributor license agreement](doc/legal/individual_contributor_license_agreement.md).
By submitting code as an entity you agree to the
[corporate contributor license agreement](doc/legal/corporate_contributor_license_agreement.md).

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to
`support@gitlab.com`, also see the
[disclosure section on the GitLab.com website](https://about.gitlab.com/disclosure/).
Please do **NOT** create publicly viewable issues for suspected security
vulnerabilities.

## Closing policy for issues and merge requests

GitLab is a popular open source project and the capacity to deal with issues
and merge requests is limited. Out of respect for our volunteers, issues and
merge requests not in line with the guidelines listed in this document may be
closed without notice.

Please treat our volunteers with courtesy and respect, it will go a long way
towards getting your issue resolved.

Issues and merge requests should be in English and contain appropriate language
for audiences of all ages.

## Helping others

Please help other GitLab users when you can. The channels people will reach out
on can be found on the [getting help page][getting-help].

Sign up for the mailing list, answer GitLab questions on StackOverflow or
respond in the IRC channel. You can also sign up on [CodeTriage][codetriage] to help with
the remaining issues on the GitHub issue tracker.

## I want to contribute!

If you want to contribute to GitLab, but are not sure where to start,
look for [issues with the label `up-for-grabs`][up-for-grabs]. These issues
will be of reasonable size and challenge, for anyone to start contributing to
GitLab.

This was inspired by [an article by Kent C. Dodds][medium-up-for-grabs].

## Implement design & UI elements

### Design reference

The GitLab design reference can be found in the [gitlab-design] project.
The designs are made using Antetype (`.atype` files). You can use the
[free Antetype viewer (Mac OSX only)] or grab an exported PNG from the design
(the PNG is 1:1).

The current designs can be found in the [`gitlab1.atype` file].

### UI development kit

Implemented UI elements can also be found at https://gitlab.com/help/ui. Please
note that this page isn't comprehensive at this time.

## Issue tracker

To get support for your particular problem please use the
[getting help channels](https://about.gitlab.com/getting-help/).

The [GitLab CE issue tracker on GitLab.com][ce-tracker] is for bugs concerning
the latest GitLab release and [feature proposals](#feature-proposals).

When submitting an issue please conform to the issue submission guidelines
listed below. Not all issues will be addressed and your issue is more likely to
be addressed if you submit a merge request which partially or fully solves
the issue.

If you're unsure where to post, post to the [mailing list][google-group] or
[Stack Overflow][stackoverflow] first. There are a lot of helpful GitLab users
there who may be able to help you quickly. If your particular issue turns out
to be a bug, it will find its way from there.

If it happens that you know the solution to an existing bug, please first
open the issue in order to keep track of it and then open the relevant merge
request that potentially fixes it.

### Feature proposals

To create a feature proposal for CE and CI, open an issue on the
[issue tracker of CE][ce-tracker].

For feature proposals for EE, open an issue on the
[issue tracker of EE][ee-tracker].

In order to help track the feature proposals, we have created a
[`feature proposal`][fpl] label. For the time being, users that are not members
of the project cannot add labels. You can instead ask one of the [core team]
members to add the label `feature proposal` to the issue or add the following
code snippet right after your description in a new line: `~"feature proposal"`.

Please keep feature proposals as small and simple as possible, complex ones
might be edited to make them small and simple.

You are encouraged to use the template below for feature proposals.

```
## Description including problem, use cases, benefits, and/or goals

## Proposal

## Links / references
```

For changes in the interface, it can be helpful to create a mockup first.
If you want to create something yourself, consider opening an issue first to
discuss whether it is interesting to include this in GitLab.

### Issue tracker guidelines

**[Search the issue tracker][ce-tracker]** for similar entries before
submitting your own, there's a good chance somebody else had the same issue or
feature proposal. Show your support with an award emoji and/or join the
discussion.

Please submit bugs using the following template in the issue description area.
The text in the parenthesis is there to help you with what to include. Omit it
when submitting the actual issue. You can copy-paste it and then edit as you
see fit.

```
## Summary

(Summarize your issue in one sentence - what goes wrong, what did you expect to happen)

## Steps to reproduce

(How one can reproduce the issue - this is very important)

## Expected behavior

(What you should see instead)

## Relevant logs and/or screenshots

(Paste any relevant logs - please use code blocks (```) to format console output,
logs, and code as it's very hard to read otherwise.)

## Output of checks

### Results of GitLab Application Check

(For installations with omnibus-gitlab package run and paste the output of:
sudo gitlab-rake gitlab:check SANITIZE=true)

(For installations from source run and paste the output of:
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production SANITIZE=true)

(we will only investigate if the tests are passing)

### Results of GitLab Environment Info

(For installations with omnibus-gitlab package run and paste the output of:
sudo gitlab-rake gitlab:env:info)

(For installations from source run and paste the output of:
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production)

## Possible fixes

(If you can, link to the line of code that might be responsible for the problem)

```

### Issue weight

Issue weight allows us to get an idea of the amount of work required to solve
one or multiple issues. This makes it possible to schedule work more accurately.

You are encouraged to set the weight of any issue. Following the guidelines
below will make it easy to manage this, without unnecessary overhead.

1. Set weight for any issue at the earliest possible convenience
1. If you don't agree with a set weight, discuss with other developers until
consensus is reached about the weight
1. Issue weights are an abstract measurement of complexity of the issue. Do not
relate issue weight directly to time. This is called [anchoring](https://en.wikipedia.org/wiki/Anchoring)
and something you want to avoid.
1. Something that has a weight of 1 (or no weight) is really small and simple.
Something that is 9 is rewriting a large fundamental part of GitLab,
which might lead to many hard problems to solve. Changing some text in GitLab
is probably 1, adding a new Git Hook maybe 4 or 5, big features 7-9.
1. If something is very large, it should probably be split up in multiple
issues or chunks. You can simply not set the weight of a parent issue and set
weights to children issues.

### Regression issues

Every monthly release has a corresponding issue on the CE issue tracker to keep
track of functionality broken by that release and any fixes that need to be
included in a patch release (see [8.3 Regressions] as an example).

As outlined in the issue description, the intended workflow is to post one note
with a reference to an issue describing the regression, and then to update that
note with a reference to the merge request that fixes it as it becomes available.

If you're a contributor who doesn't have the required permissions to update
other users' notes, please post a new note with a reference to both the issue
and the merge request.

The release manager will [update the notes] in the regression issue as fixes are
addressed.

[8.3 Regressions]: https://gitlab.com/gitlab-org/gitlab-ce/issues/4127
[update the notes]: https://gitlab.com/gitlab-org/release-tools/blob/master/doc/pro-tips.md#update-the-regression-issue

### Technical debt

In order to track things that can be improved in GitLab's codebase, we created
the ~"technical debt" label in [GitLab's issue tracker][ce-tracker].

This label should be added to issues that describe things that can be improved,
shortcuts that have been taken, code that needs refactoring, features that need
additional attention, and all other things that have been left behind due to
high velocity of development.

Everyone can create an issue, though you may need to ask for adding a specific
label, if you do not have permissions to do it by yourself. Additional labels
can be combined with the `technical debt` label, to make it easier to schedule
the improvements for a release.

Issues tagged with the `technical debt` label have the same priority like issues
that describe a new feature to be introduced in GitLab, and should be scheduled
for a release by the appropriate person.

Make sure to mention the merge request that the `technical debt` issue is
associated with in the description of the issue.

## Merge requests

We welcome merge requests with fixes and improvements to GitLab code, tests,
and/or documentation. The features we would really like a merge request for are
listed with the label [`Accepting Merge Requests` on our issue tracker for CE][accepting-mrs-ce]
and [EE][accepting-mrs-ee] but other improvements are also welcome.

If you want to add a new feature that is not labeled it is best to first create
a feedback issue (if there isn't one already) and leave a comment asking for it
to be marked as `Accepting merge requests`. Please include screenshots or
wireframes if the feature will also change the UI.

Merge requests can be filed either at [GitLab.com][gitlab-mr-tracker] or at
[github.com][github-mr-tracker].

If you are new to GitLab development (or web development in general), see the
[I want to contribute!](#i-want-to-contribute) section to get you started with
some potentially easy issues.

To start with GitLab development download the [GitLab Development Kit][gdk] and
see the [Development section](doc/development/README.md) for some guidelines.

### Merge request guidelines

If you can, please submit a merge request with the fix or improvements
including tests. If you don't know how to fix the issue but can write a test
that exposes the issue we will accept that as well. In general bug fixes that
include a regression test are merged quickly while new features without proper
tests are least likely to receive timely feedback. The workflow to make a merge
request is as follows:

1. Fork the project into your personal space on GitLab.com
1. Create a feature branch
1. Write [tests](https://gitlab.com/gitlab-org/gitlab-development-kit#running-the-tests) and code
1. Add your changes to the [CHANGELOG](CHANGELOG)
1. If you are changing the README, some documentation or other things which
   have no effect on the tests, add `[ci skip]` somewhere in the commit message
   and make sure to read the [documentation styleguide][doc-styleguide]
1. If you have multiple commits please combine them into one commit by
   [squashing them][git-squash]
1. Push the commit(s) to your fork
1. Submit a merge request (MR) to the master branch
1. The MR title should describe the change you want to make
1. The MR description should give a motive for your change and the method you
   used to achieve it, see the [merge request description format]
   (#merge-request-description-format)
1. If the MR changes the UI it should include before and after screenshots
1. If the MR changes CSS classes please include the list of affected pages,
   `grep css-class ./app -R`
1. Link any relevant [issues][ce-tracker] in the merge request description and
   leave a comment on them with a link back to the MR
1. Be prepared to answer questions and incorporate feedback even if requests
   for this arrive weeks or months after your MR submission
1. If your MR touches code that executes shell commands, reads or opens files or
   handles paths to files on disk, make sure it adheres to the
   [shell command guidelines](doc/development/shell_commands.md)
1. If your code creates new files on disk please read the
   [shared files guidelines](doc/development/shared_files.md).
1. When writing commit messages please follow [these](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) [guidelines](http://chris.beams.io/posts/git-commit/).

The **official merge window** is in the beginning of the month from the 1st to
the 7th day of the month. This is the best time to submit an MR and get
feedback fast. Before this time the GitLab Inc. team is still dealing with work
that is created by the monthly release such as regressions requiring patch
releases. After the 7th it is already getting closer to the release date of the
next version. This means there is less time to fix the issues created by
merging large new features.

Please keep the change in a single MR **as small as possible**. If you want to
contribute a large feature think very hard what the minimum viable change is.
Can you split the functionality? Can you only submit the backend/API code? Can
you start with a very simple UI? Can you do part of the refactor? The increased
reviewability of small MRs that leads to higher code quality is more important
to us than having a minimal commit log. The smaller an MR is the more likely it
is it will be merged (quickly). After that you can send more MRs to enhance it.

For examples of feedback on merge requests please look at already
[closed merge requests][closed-merge-requests]. If you would like quick feedback
on your merge request feel free to mention one of the Merge Marshalls in the
[core team] or one of the [Merge request coaches](https://about.gitlab.com/team/).
Please ensure that your merge request meets the contribution acceptance criteria.

When having your code reviewed and when reviewing merge requests please take the
[code review guidelines](doc/development/code_review.md) into account.

### Merge request description format

Please submit merge requests using the following template in the merge request
description area. Copy-paste it to retain the markdown format.

```
## What does this MR do?

## Are there points in the code the reviewer needs to double check?

## Why was this MR needed?

## What are the relevant issue numbers?

## Screenshots (if relevant)
```

### Contribution acceptance criteria

1. The change is as small as possible
1. Include proper tests and make all tests pass (unless it contains a test
   exposing a bug in existing code)
1. If you suspect a failing CI build is unrelated to your contribution, you may
   try and restart the failing CI job or ask a developer to fix the
   aforementioned failing test
1. Your MR initially contains a single commit (please use `git rebase -i` to
   squash commits)
1. Your changes can merge without problems (if not please merge `master`, never
   rebase commits pushed to the remote server)
1. Does not break any existing functionality
1. Fixes one specific issue or implements one specific feature (do not combine
   things, send separate merge requests if needed)
1. Migrations should do only one thing (e.g., either create a table, move data
   to a new table or remove an old table) to aid retrying on failure
1. Keeps the GitLab code base clean and well structured
1. Contains functionality we think other users will benefit from too
1. Doesn't add configuration options or settings options since they complicate
   making and testing future changes
1. Changes after submitting the merge request should be in separate commits
   (no squashing). If necessary, you will be asked to squash when the review is
   over, before merging.
1. It conforms to the [style guides](#style-guides) and the following:
    - If your change touches a line that does not follow the style, modify the
      entire line to follow it. This prevents linting tools from generating warnings.
    - Don't touch neighbouring lines. As an exception, automatic mass
      refactoring modifications may leave style non-compliant.

## Changes for Stable Releases

Sometimes certain changes have to be added to an existing stable release.
Two examples are bug fixes and performance improvements. In these cases the
corresponding merge request should be updated to have the following:

1. A milestone indicating what release the merge request should be merged into.
1. The label "Pick into Stable"

This makes it easier for release managers to keep track of what still has to be
merged and where changes have to be merged into.
Like all merge requests the target should be master so all bugfixes are in master.

## Definition of done

If you contribute to GitLab please know that changes involve more than just
code. We have the following [definition of done][definition-of-done]. Please ensure you support
the feature you contribute through all of these steps.

1. Description explaining the relevancy (see following item)
1. Working and clean code that is commented where needed
1. Unit and integration tests that pass on the CI server
1. [Documented][doc-styleguide] in the /doc directory
1. Changelog entry added
1. Reviewed and any concerns are addressed
1. Merged by the project lead
1. Added to the release blog article
1. Added to [the website](https://gitlab.com/gitlab-com/www-gitlab-com/) if relevant
1. Community questions answered
1. Answers to questions radiated (in docs/wiki/etc.)

If you add a dependency in GitLab (such as an operating system package) please
consider updating the following and note the applicability of each in your
merge request:

1. Note the addition in the release blog post (create one if it doesn't exist yet) https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/
1. Upgrade guide, for example https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/7.5-to-7.6.md
1. Upgrader https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/upgrader.md#2-run-gitlab-upgrade-tool
1. Installation guide https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md#1-packages-dependencies
1. GitLab Development Kit https://gitlab.com/gitlab-org/gitlab-development-kit
1. Test suite https://gitlab.com/gitlab-org/gitlab-ce/blob/master/scripts/prepare_build.sh
1. Omnibus package creator https://gitlab.com/gitlab-org/omnibus-gitlab

## Style guides

1.  [Ruby](https://github.com/bbatsov/ruby-style-guide).
    Important sections include [Source Code Layout][rss-source] and
    [Naming][rss-naming]. Use:
    - multi-line method chaining style **Option B**: dot `.` on previous line
    - string literal quoting style **Option A**: single quoted by default
1.  [Rails](https://github.com/bbatsov/rails-style-guide)
1.  [Testing](doc/development/testing.md)
1.  [CoffeeScript](https://github.com/thoughtbot/guides/tree/master/style/coffeescript)
1.  [SCSS styleguide][scss-styleguide]
1.  [Shell commands](doc/development/shell_commands.md) created by GitLab
    contributors to enhance security
1.  [Database Migrations](doc/development/migration_style_guide.md)
1.  [Markdown](http://www.cirosantilli.com/markdown-styleguide)
1.  [Documentation styleguide][doc-styleguide]
1.  Interface text should be written subjectively instead of objectively. It
    should be the GitLab core team addressing a person. It should be written in
    present time and never use past tense (has been/was). For example instead
    of _prohibited this user from being saved due to the following errors:_ the
    text should be _sorry, we could not create your account because:_

This is also the style used by linting tools such as
[RuboCop](https://github.com/bbatsov/rubocop),
[PullReview](https://www.pullreview.com/) and [Hound CI](https://houndci.com).

## Code of conduct

As contributors and maintainers of this project, we pledge to respect all
people who contribute through reporting issues, posting feature requests,
updating documentation, submitting pull requests or patches, and other
activities.

We are committed to making participation in this project a harassment-free
experience for everyone, regardless of level of experience, gender, gender
identity and expression, sexual orientation, disability, personal appearance,
body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual
language or imagery, derogatory comments or personal attacks, trolling, public
or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct. Project maintainers who do not
follow the Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior can be
reported by emailing `contact@gitlab.com`.

This Code of Conduct is adapted from the [Contributor Covenant][contributor-covenant], version 1.1.0,
available at [http://contributor-covenant.org/version/1/1/0/](http://contributor-covenant.org/version/1/1/0/).

[core team]: https://about.gitlab.com/core-team/
[getting-help]: https://about.gitlab.com/getting-help/
[codetriage]: http://www.codetriage.com/gitlabhq/gitlabhq
[up-for-grabs]: https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name=up-for-grabs
[medium-up-for-grabs]: https://medium.com/@kentcdodds/first-timers-only-78281ea47455
[ce-tracker]: https://gitlab.com/gitlab-org/gitlab-ce/issues
[ee-tracker]: https://gitlab.com/gitlab-org/gitlab-ee/issues
[google-group]: https://groups.google.com/forum/#!forum/gitlabhq
[stackoverflow]: https://stackoverflow.com/questions/tagged/gitlab
[fpl]: https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name=feature+proposal
[accepting-mrs-ce]: https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name=Accepting+Merge+Requests
[accepting-mrs-ee]: https://gitlab.com/gitlab-org/gitlab-ee/issues?label_name=Accepting+Merge+Requests
[gitlab-mr-tracker]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests
[github-mr-tracker]: https://github.com/gitlabhq/gitlabhq/pulls
[gdk]: https://gitlab.com/gitlab-org/gitlab-development-kit
[git-squash]: https://git-scm.com/book/en/Git-Tools-Rewriting-History#Squashing-Commits
[closed-merge-requests]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests?assignee_id=&label_name=&milestone_id=&scope=&sort=&state=closed
[definition-of-done]: http://guide.agilealliance.org/guide/definition-of-done.html
[contributor-covenant]: http://contributor-covenant.org
[rss-source]: https://github.com/bbatsov/ruby-style-guide/blob/master/README.md#source-code-layout
[rss-naming]: https://github.com/bbatsov/ruby-style-guide/blob/master/README.md#naming
[doc-styleguide]: doc/development/doc_styleguide.md "Documentation styleguide"
[scss-styleguide]: doc/development/scss_styleguide.md "SCSS styleguide"
[gitlab-design]: https://gitlab.com/gitlab-org/gitlab-design
[free Antetype viewer (Mac OSX only)]: https://itunes.apple.com/us/app/antetype-viewer/id824152298?mt=12
[`gitlab1.atype` file]: https://gitlab.com/gitlab-org/gitlab-design/tree/master/gitlab1.atype/
