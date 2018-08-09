## Merge requests

We welcome merge requests with fixes and improvements to GitLab code, tests,
and/or documentation. The issues that are specifically suitable for
community contributions are listed with the label
[`Accepting Merge Requests` on our issue tracker for CE][accepting-mrs-ce]
and [EE][accepting-mrs-ee], but you are free to contribute to any other issue
you want.

Please note that if an issue is marked for the current milestone either before
or while you are working on it, a team member may take over the merge request
in order to ensure the work is finished before the release date.

If you want to add a new feature that is not labeled it is best to first create
a feedback issue (if there isn't one already) and leave a comment asking for it
to be marked as `Accepting Merge Requests`. Please include screenshots or
wireframes if the feature will also change the UI.

Merge requests should be opened at [GitLab.com][gitlab-mr-tracker].

If you are new to GitLab development (or web development in general), see the
[I want to contribute!](#i-want-to-contribute) section to get you started with
some potentially easy issues.

To start with GitLab development download the [GitLab Development Kit][gdk] and
see the [Development section](../README.md) for some guidelines.

### Merge request guidelines

If you can, please submit a merge request with the fix or improvements
including tests. If you don't know how to fix the issue but can write a test
that exposes the issue we will accept that as well. In general bug fixes that
include a regression test are merged quickly while new features without proper
tests are least likely to receive timely feedback. The workflow to make a merge
request is as follows:

1. Fork the project into your personal space on GitLab.com
1. Create a feature branch, branch away from `master`
1. Write [tests](https://docs.gitlab.com/ee/development/rake_tasks.html#run-tests) and code
1. [Generate a changelog entry with `bin/changelog`][changelog]
1. If you are writing documentation, make sure to follow the
   [documentation guidelines][doc-guidelines]
1. If you have multiple commits please combine them into a few logically
  organized commits by [squashing them][git-squash]
1. Push the commit(s) to your fork
1. Submit a merge request (MR) to the `master` branch
  1. Your merge request needs at least 1 approval but feel free to require more.
    For instance if you're touching backend and frontend code, it's a good idea
    to require 2 approvals: 1 from a backend maintainer and 1 from a frontend
    maintainer
  1. You don't have to select any approvers, but you can if you really want
    specific people to approve your merge request
1. The MR title should describe the change you want to make
1. The MR description should give a motive for your change and the method you
   used to achieve it.
  1. If you are contributing code, fill in the template already provided in the
     "Description" field.
  1. If you are contributing documentation, choose `Documentation` from the
     "Choose a template" menu and fill in the template.
  1. Mention the issue(s) your merge request solves, using the `Solves #XXX` or
    `Closes #XXX` syntax to auto-close the issue(s) once the merge request will
    be merged.
1. If you're allowed to, set a relevant milestone and labels
1. If the MR changes the UI it should include *Before* and *After* screenshots
1. If the MR changes CSS classes please include the list of affected pages,
   `grep css-class ./app -R`
1. Be prepared to answer questions and incorporate feedback even if requests
   for this arrive weeks or months after your MR submission
  1. If a discussion has been addressed, select the "Resolve discussion" button
    beneath it to mark it resolved.
1. If your MR touches code that executes shell commands, reads or opens files or
   handles paths to files on disk, make sure it adheres to the
   [shell command guidelines](../shell_commands.md)
1. If your code creates new files on disk please read the
   [shared files guidelines](../shared_files.md).
1. When writing commit messages please follow
   [these](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
   [guidelines](http://chris.beams.io/posts/git-commit/).
1. If your merge request adds one or more migrations, make sure to execute all
   migrations on a fresh database before the MR is reviewed. If the review leads
   to large changes in the MR, do this again once the review is complete.
1. For more complex migrations, write tests.
1. Merge requests **must** adhere to the [merge request performance
   guidelines](../merge_request_performance_guidelines.md).
1. For tests that use Capybara or PhantomJS, see this [article on how
   to write reliable asynchronous tests](https://robots.thoughtbot.com/write-reliable-asynchronous-integration-tests-with-capybara).

Please keep the change in a single MR **as small as possible**. If you want to
contribute a large feature think very hard what the minimum viable change is.
Can you split the functionality? Can you only submit the backend/API code? Can
you start with a very simple UI? Can you do part of the refactor? The increased
reviewability of small MRs that leads to higher code quality is more important
to us than having a minimal commit log. The smaller an MR is the more likely it
is it will be merged (quickly). After that you can send more MRs to enhance it.
The ['How to get faster PR reviews' document of Kubernetes](https://github.com/kubernetes/community/blob/master/contributors/devel/faster_reviews.md) also has some great points regarding this.

For examples of feedback on merge requests please look at already
[closed merge requests][closed-merge-requests]. If you would like quick feedback
on your merge request feel free to mention someone from the [core team] or one
of the [Merge request coaches][team].
Please ensure that your merge request meets the contribution acceptance criteria.

When having your code reviewed and when reviewing merge requests please take the
[code review guidelines](../code_review.md) into account.

### Contribution acceptance criteria

1. The change is as small as possible
1. Include proper tests and make all tests pass (unless it contains a test
   exposing a bug in existing code). Every new class should have corresponding
   unit tests, even if the class is exercised at a higher level, such as a feature test.
1. If you suspect a failing CI build is unrelated to your contribution, you may
   try and restart the failing CI job or ask a developer to fix the
   aforementioned failing test
1. Your MR initially contains a single commit (please use `git rebase -i` to
   squash commits)
1. Your changes can merge without problems (if not please rebase if you're the
   only one working on your feature branch, otherwise, merge `master`)
1. Does not break any existing functionality
1. Fixes one specific issue or implements one specific feature (do not combine
   things, send separate merge requests if needed)
1. Migrations should do only one thing (e.g., either create a table, move data
   to a new table or remove an old table) to aid retrying on failure
1. Keeps the GitLab code base clean and well structured
1. Contains functionality we think other users will benefit from too
1. Doesn't add configuration options or settings options since they complicate
   making and testing future changes
1. Changes do not adversely degrade performance.
   - Avoid repeated polling of endpoints that require a significant amount of overhead
   - Check for N+1 queries via the SQL log or [`QueryRecorder`](https://docs.gitlab.com/ce/development/mer ge_request_performance_guidelines.html)
   - Avoid repeated access of filesystem
1. If you need polling to support real-time features, please use
   [polling with ETag caching][polling-etag].
1. Changes after submitting the merge request should be in separate commits
   (no squashing).
1. It conforms to the [style guides](#style-guides) and the following:
    - If your change touches a line that does not follow the style, modify the
      entire line to follow it. This prevents linting tools from generating warnings.
    - Don't touch neighbouring lines. As an exception, automatic mass
      refactoring modifications may leave style non-compliant.
1. If the merge request adds any new libraries (gems, JavaScript libraries,
   etc.), they should conform to our [Licensing guidelines][license-finder-doc].
   See the instructions in that document for help if your MR fails the
   "license-finder" test with a "Dependencies that need approval" error.
1. The merge request meets the [definition of done](#definition-of-done).

## Definition of done

If you contribute to GitLab please know that changes involve more than just
code. We have the following [definition of done][definition-of-done]. Please ensure you support
the feature you contribute through all of these steps.

1. Description explaining the relevancy (see following item)
1. Working and clean code that is commented where needed
1. [Unit, integration, and system tests][testing] that pass on the CI server
1. Performance/scalability implications have been considered, addressed, and tested
1. [Documented][doc-guidelines] in the `/doc` directory
1. [Changelog entry added][changelog], if necessary
1. Reviewed and any concerns are addressed
1. Merged by a project maintainer
1. Added to the release blog article, if relevant
1. Added to [the website](https://gitlab.com/gitlab-com/www-gitlab-com/), if relevant
1. Community questions answered
1. Answers to questions radiated (in docs/wiki/support etc.)

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

---

[Return to Contributing documentation](index.md)
