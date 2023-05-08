---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Introduction to Git workflows **(FREE)**

With Git, you can use a variety of branching strategies and workflows.
Having a structured workflow for collaboration in complex projects is
crucial for several reasons:

- **Code organization**: Keep the codebase organized, prevent
  overlapping work, and ensure focused efforts towards a common goal.

- **Version control**: Allow simultaneous work on different features
  without conflicts, maintaining code stability.

- **Code quality**: A code review and approval process helps maintain high
  code quality and adherence to coding standards.

- **Traceability and accountability**: Enable tracking of changes and their authors,
  simplifying issue identification and responsibility assignment.

- **Easier onboarding**: Help new team members quickly grasp the
  development process, and start contributing effectively.

- **Time and resource management**: Enable better planning, resource
  allocation, and meeting deadlines, ensuring an efficient development
  process.

- **CI/CD**: Incorporate automated testing and deployment
  processes, streamlining the release cycle and delivering high-quality
  software consistently.

A structured workflow promotes organization, efficiency, and code
quality, leading to a more successful and streamlined development process.

If the default workflow is not specifically defined, many organizations
end up with workflows that are:

- Too complicated.
- Not clearly defined.
- Not integrated with their issue tracking systems.

Your organization can use GitLab with any workflow you choose.

## Workflow types

Here are some of the most common Git workflows.

### Centralized workflow

Best suited for small teams transitioning from a centralized version
control system like SVN. All team members work on a single branch,
usually `main`, and push their changes directly to the central
repository.

### Feature branch workflow

Developers create separate branches for each feature or bugfix,
keeping the 'main' branch stable. When a feature is complete, the
developer submits a merge request to integrate the
changes back into `main` after a code review.

### Forking workflow

Commonly used in open-source projects, this workflow allows external
contributors to work without direct access to the main repository.
Developers create a fork (personal copy) of the main repository and
make changes in it. They then submit a merge request to have those changes
integrated into the main repository.

### Git flow workflow

This workflow is best for projects with a structured release cycle.
It introduces two long-lived branches: `main` for production-ready
code and `develop` for integrating features. Additional branches like
`feature`, `release`, and `hotfix` are used for specific purposes,
ensuring a strict and organized development process.

### GitLab/GitHub flow

A simplified workflow primarily used for web development and
continuous deployment. It combines aspects of the Feature branch
workflow and the Git flow workflow. Developers create feature branches
from `main`, and after the changes are complete, they are merged back
into the `main` branch, which is then immediately deployed.

Each of these Git workflows has its advantages and is suited to
different project types and team structures. Below the most popular
workflows are reviewed in more details.

## Git workflow

Most version control systems have only one step: committing from the working copy to a shared server.

When you convert to Git, you have to get used to the fact that it takes three steps to share a commit with colleagues.

In Git, you add files from the working copy to the staging area. After that, you commit them to your local repository.
The third step is pushing to a shared remote repository.

```mermaid
graph LR
    subgraph Git workflow
    A[Working copy] --> |git add| B[Index]
    B --> |git commit| C[Local repository]
    C --> |git push| D[Remote repository]
    end
```

After getting used to these three steps, the next challenge is the branching model.

Because many organizations new to Git have no conventions for how to work with it, their repositories can quickly become messy.
The biggest problem is that many long-running branches emerge that all contain part of the changes.
People have a hard time figuring out which branch has the latest code, or which branch to deploy to production.
Frequently, the reaction to this problem is to adopt a standardized pattern such as [Git flow](https://nvie.com/posts/a-successful-git-branching-model/) and [GitHub flow](https://scottchacon.com/2011/08/31/github-flow.html).

We think there is still room for improvement, and so we've proposed a set of practices called the GitLab Flow.

For a video introduction of this workflow in GitLab, see [GitLab Flow](https://youtu.be/InKNIvky2KE).

## Problems with the Git flow

Git flow was one of the first proposals to use Git branches, and it has received
a lot of attention. It suggests a `main` branch and a separate `develop` branch,
with supporting branches for features, releases, and hotfixes. The development
happens on the `develop` branch, moves to a release branch, and is finally merged
into the `main` branch.

Git flow is a well-defined standard, but its complexity introduces two problems.
The first problem is that developers must use the `develop` branch and not `main`. `main` is reserved for code that is released to production.
It is a convention to call your default branch `main` and to mostly branch from and merge to this.
Because most tools automatically use the `main` branch as the default, it is annoying to have to switch to another branch.

The second problem of Git flow is the complexity introduced by the hotfix and release branches.
These branches can be a good idea for some organizations but are overkill for the vast majority of them.
Nowadays, most organizations practice continuous delivery, which means that your default branch can be deployed.
Continuous delivery removes the need for hotfix and release branches, including all the ceremony they introduce.
An example of this ceremony is the merging back of release branches.
Though specialized tools do exist to solve this, they require documentation and add complexity.
Frequently, developers make mistakes such as merging changes only into `main` and not into the `develop` branch.
The reason for these errors is that Git flow is too complicated for most use cases.
For example, many projects do releases but don't need to do hotfixes.

<!-- vale gitlab.Spelling = NO -->

![Git Flow timeline by Vincent Driessen, used with permission](img/gitlab_flow_gitdashflow.png)

<!-- vale gitlab.Spelling = YES -->

## GitHub flow as a simpler alternative

In reaction to Git flow, GitHub created a simpler alternative.
[GitHub flow](https://docs.github.com/en/get-started/quickstart/github-flow) has only feature branches and a `main` branch:

```mermaid
graph TD
    subgraph Feature branches in GitHub Flow
    A[main branch] ===>B[main branch]
    D[nav branch] --> |add navigation| B
    B ===> C[main branch]
    E[feature-branch] --> |add feature| C
    C ==> F[main branch]
    end
```

This flow is clean and straightforward, and many organizations have adopted it with great success.
Atlassian recommends [a similar strategy](https://www.atlassian.com/blog/git/simple-git-workflow-is-simple), although they rebase feature branches.
Merging everything into the `main` branch and frequently deploying means you minimize the amount of unreleased code. This approach is in line with lean and continuous delivery best practices.
However, this flow still leaves a lot of questions unanswered regarding deployments, environments, releases, and integrations with issues.

## Introduction to GitLab Flow **(FREE)**

However, if you are looking for guidance on best practices, you can use
the GitLab Flow. This workflow combines [feature-driven development](https://en.wikipedia.org/wiki/Feature-driven_development)
and [feature branches](https://martinfowler.com/bliki/FeatureBranch.html) with issue tracking.

While this workflow used at GitLab, you can choose whichever workflow
suits your organization best.

With GitLab flow, we offer additional guidance for these questions.

## Production branch with GitLab flow

GitHub flow assumes you can deploy to production every time you merge a feature branch.
While this is possible in some cases, such as SaaS applications, there are some cases where this is not possible, such as:

- You don't control the timing of a release. For example, an iOS application that
  is released when it passes App Store validation.
- You have deployment windows - for example, workdays from 10 AM to 4 PM when the
  operations team is at full capacity - but you also merge code at other times.

In these cases, you can create a production branch that reflects the deployed code.
You can deploy a new version by merging `main` into the `production` branch.
While not shown in the graph below, the work on the `main` branch works just like in GitHub flow:
with feature branches being merged into `main`.

```mermaid
graph TD
    subgraph Production branch in GitLab Flow
    A[main branch] ==>B[development]
    B ==> C[main branch]
    C ==> D[main branch]

    E[production] ====> F[production]
    C --> |deployment| F
    D ==> G[main branch]
    F ==> H[main branch]
    end
```

If you need to know what code is in production, you can check out the production branch to see.
The approximate time of deployment is visible as the merge commit in the version control system.
This time is pretty accurate if you automatically deploy your production branch.
If you need a more exact time, you can have your deployment script create a tag on each deployment.
This flow prevents the overhead of releasing, tagging, and merging that happens with Git flow.

## Environment branches with GitLab flow

It might be a good idea to have an environment that is automatically updated to the `staging` branch.
Only, in this case, the name of this environment might differ from the branch name.
Suppose you have a staging environment, a pre-production environment, and a production environment:

```mermaid
graph LR
    subgraph Environment branches in GitLab Flow

    A[staging] ==> B[staging]
    B ==> C[staging]
    C ==> D[staging]

    A --> |deploy to<br>pre-prod| G

    F[pre-prod] ==> G[pre-prod]
    G ==> H[pre-prod]
    H ==> I[pre-prod]

    C --> |deploy to<br>pre-prod| I

    J[production] ==> K[production]
    K ==> L[production]

    G --> |production <br>deployment| K

    end
```

In this case, deploy the `staging` branch to your staging environment.
To deploy to pre-production, create a merge request from the `staging` branch to the `pre-prod` branch.
Go live by merging the `pre-prod` branch into the `production` branch.
This workflow, where commits only flow downstream, ensures that everything is tested in all environments.
To cherry-pick a commit with a hotfix, develop it on a feature branch and merge it into `production` with a merge request.
In this case, do not delete the feature branch yet.
If `production` passes automatic testing, you then merge the feature branch into the other branches.
If this is not possible because more manual testing is required, you can send merge requests from the feature branch to the downstream branches.

## Release branches with GitLab flow

You should work with release branches only if you need to release software to
the outside world. In this case, each branch contains a minor version, such as
`2.3-stable` or `2.4-stable`:

```mermaid
graph LR
    A:::main ===> B((main))
    B:::main ==> C((main))
    C:::main ==> D((main))
    D:::main ==> E((main))

    A((main)) ----> F((2.3-stable)):::first
    F --> G((2.3-stable)):::first
    C -.-> |cherry-pick| G
    D --> H((2.4-stable)):::second

    classDef main fill:#f4f0ff,stroke:#7b58cf
    classDef first fill:#e9f3fc,stroke:#1f75cb
    classDef second fill:#ecf4ee,stroke:#108548
```

Create stable branches using `main` as a starting point, and branch as late as possible.
By doing this, you minimize the length of time during which you have to apply bug fixes to multiple branches.
After announcing a release branch, only add serious bug fixes to the branch.
If possible, first merge these bug fixes into `main`, and then cherry-pick them into the release branch.
If you initially merged into the release branch and then forgot to cherry-pick to `main`, you'd encounter the same bug in subsequent releases.
Merging into `main` and then cherry-picking into release is called an "upstream first" policy, which is also practiced by [Google](https://www.chromium.org/chromium-os/chromiumos-design-docs/upstream-first/) and [Red Hat](https://www.redhat.com/en/blog/a-community-for-using-openstack-with-red-hat-rdo).
Every time you include a bug fix in a release branch, increase the patch version (to comply with [Semantic Versioning](https://semver.org/)) by setting a new tag.
Some projects also have a stable branch that points to the same commit as the latest released branch.
In this flow, it is not common to have a production branch (or Git flow `main` branch).

## Merge/pull requests with GitLab flow

![Merge request with inline comments](img/gitlab_flow_mr_inline_comments.png)

Merge or pull requests are created in a Git management application. They ask an assigned person to merge two branches.
Tools such as GitHub and Bitbucket choose the name "pull request", because the first manual action is to pull the feature branch.
Tools such as GitLab and others choose the name "merge request", because the final action is to merge the feature branch.
This article refers to them as merge requests.

If you work on a feature branch for more than a few hours, share the intermediate result with the rest of your team.
To do this, create a merge request without assigning it to anyone.
Instead, mention people in the description or a comment, for example, "/cc @mark @susan."
This indicates that the merge request is not ready to be merged yet, but feedback is welcome.
Your team members can comment on the merge request in general or on specific lines with line comments.
The merge request serves as a code review tool, and no separate code review tools should be needed.
If the review reveals shortcomings, anyone can commit and push a fix.
Usually, the person to do this is the creator of the merge request.
The diff in the merge request automatically updates when new commits are pushed to the branch.

When you are ready to merge your feature branch, assign the merge request to a maintainer for the project.
Also, mention any other people from whom you would like feedback.
After the assigned person feels comfortable with the result, they can merge the branch.
If the assigned person does not feel comfortable, they can request more changes or close the merge request without merging.

In GitLab, it is common to protect the long-lived branches, such as the `main` branch, so [most developers can't modify them](../user/permissions.md).
So, if you want to merge into a protected branch, assign your merge request to someone with the
Maintainer role.

After you merge a feature branch, you should remove it from the source control software.
In GitLab, you can do this when merging.
Removing finished branches ensures that the list of branches shows only work in progress.
It also ensures that if someone reopens the issue, they can use the same branch name without causing problems.

NOTE:
When you reopen an issue you need to create a new merge request.

![Remove checkbox for branch in merge requests](img/gitlab_flow_remove_checkbox.png)

## Issue tracking with GitLab flow

GitLab flow is a way to make the relation between the code and the issue tracker more transparent.

Any significant change to the code should start with an issue that describes the goal.
Having a reason for every code change helps to inform the rest of the team and to keep the scope of a feature branch small.
In GitLab, each change to the codebase starts with an issue in the issue tracking system.
If there is no issue yet, create the issue if the change requires more than an hour's work.
In many organizations, raising an issue is part of the development process because they are used in sprint planning.
The issue title should describe the desired state of the system.
For example, the issue title `As an administrator, I want to remove users without receiving an error`
is better than "Administrators can't remove users."

When you are ready to code, create a branch for the issue from the `main` branch.
This branch is the place for any work related to this change.

NOTE:
The name of a branch might be dictated by organizational standards.

When you are done or want to discuss the code, open a merge request.
A merge request is an online place to discuss the change and review the code.

If you open the merge request but do not assign it to anyone, it is a [draft merge request](../user/project/merge_requests/drafts.md).
Drafts are used to discuss the proposed implementation but are not ready for inclusion in the `main` branch yet.
Start the title of the merge request with `[Draft]`, `Draft:` or `(Draft)` to prevent it from being merged before it's ready.

When you think the code is ready, assign the merge request to a reviewer.
The reviewer can merge the changes when they think the code is ready for inclusion in the `main` branch.
When they press the merge button, GitLab merges the code and creates a merge commit that makes this event visible later on.
Merge requests always create a merge commit, even when the branch could be merged without one.
This merge strategy is called "no fast-forward" in Git.
After the merge, delete the feature branch, because it is no longer needed.
In GitLab, this deletion is an option when merging.

Suppose that a branch is merged but a problem occurs and the issue is reopened.
In this case, it is no problem to reuse the same branch name, because the first branch was deleted when it was merged.
At any time, there is at most one branch for every issue.
It is possible that one feature branch solves more than one issue.

## Linking and closing issues from merge requests

Link to issues by mentioning them in commit messages or the description of a merge request, for example, "Fixes #16" or "Duck typing is preferred. See #12."
GitLab then creates links to the mentioned issues and creates comments in the issues linking back to the merge request.

To automatically close linked issues, mention them with the words "fixes" or "closes," for example, "fixes #14" or "closes #67." GitLab closes these issues when the code is merged into the default branch.

If you have an issue that spans across multiple repositories, create an issue for each repository and link all issues to a parent issue.

## Squashing commits with rebase

With Git, you can use an interactive rebase (`rebase -i`) to squash multiple commits into one or reorder them.
This feature helps you replace a couple of small commits with a single commit, or if you want to make the order more logical:

```shell
pick c6ee4d3 add a new file to the repo
pick c3c130b change readme

# Rebase 168afa0..c3c130b onto 168afa0
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
~
~
~
"~/demo/gitlab-ce/.git/rebase-merge/git-rebase-todo" 20L, 673C
```

However, you should avoid rebasing commits you have pushed to a remote server if you have other active contributors in the same branch.
Because rebasing creates new commits for all your changes, it can cause confusion because the same change would have multiple identifiers.
It would cause merge errors for anyone working on the same branch because their history would not match with yours. It can be really troublesome for the author or other contributors.
Also, if someone has already reviewed your code, rebasing makes it hard to tell what changed after the last review.

You should never rebase commits authored by other people unless you've agreed otherwise.
Not only does this rewrite history, but it also loses authorship information.
Rebasing prevents the other authors from being attributed and sharing part of the [`git blame`](https://git-scm.com/docs/git-blame).

If a merge involves many commits, it may seem more difficult to undo.
You might consider solving this by squashing all the changes into one commit just before merging by using the GitLab [Squash-and-Merge](../user/project/merge_requests/squash_and_merge.md) feature.
Fortunately, you can undo a merge with all its commits.
The way to do this is by reverting the merge commit.
Preserving this ability to revert a merge is a good reason to always use the "no fast-forward" (`--no-ff`) strategy when you merge manually.

NOTE:
If you revert a merge commit and then change your mind, revert the revert commit to redo the merge.
Git does not allow you to merge the code again otherwise.

## Reducing merge commits in feature branches

Having lots of merge commits can make your repository history messy.
Therefore, you should try to avoid merge commits in feature branches.
Often, people avoid merge commits by just using rebase to reorder their commits after the commits on the `main` branch.
Using rebase prevents a merge commit when merging `main` into your feature branch, and it creates a neat linear history.
However, as discussed in [the section about rebasing](#squashing-commits-with-rebase), you should avoid rebasing commits in a feature branch that you're sharing with others.

Rebasing could create more work, as every time you rebase, you may need to resolve the same conflicts.
Sometimes you can reuse recorded resolutions (`rerere`), but merging is better, because you only have to resolve conflicts once.
Atlassian has [a more thorough explanation of the tradeoffs between merging and rebasing](https://www.atlassian.com/blog/git/git-team-workflows-merge-or-rebase) on their blog.

A good way to prevent creating many merge commits is to not frequently merge `main` into the feature branch.
Three reasons to merge in `main`:

1. Utilizing new code.
1. Resolving merge conflicts.
1. Updating long-running branches.

To use some code that was introduced in `main` after you created the feature branch, cherry-pick a commit.

If your feature branch has a merge conflict, creating a merge commit is a standard way of solving this.

NOTE:
Sometimes you can use `.gitattributes` to reduce merge conflicts.
For example, you can set your changelog file to use the [union merge driver](https://git-scm.com/docs/gitattributes#gitattributes-union) so that multiple new entries don't conflict with each other.

The last reason for creating merge commits is to keep long-running feature branches up-to-date with the latest state of the project.
The solution here is to keep your feature branches short-lived.
Most feature branches should take less than one day of work.
If your feature branches often take more than a day of work, try to split your features into smaller units of work.

If you need to keep a feature branch open for more than a day, there are a few strategies to keep it up-to-date.
One option is to use continuous integration (CI) to merge in `main` at the start of the day.
Another option is to only merge in from well-defined points in time, for example, a tagged release.
You could also use [feature toggles](https://martinfowler.com/bliki/FeatureToggle.html) to hide incomplete features so you can still merge back into `main` every day.

NOTE:
Don't confuse automatic branch testing with continuous integration.
Martin Fowler makes this distinction in [an article about feature branches](https://martinfowler.com/bliki/FeatureBranch.html):
"\[People\] say they are doing CI because they are running builds, perhaps using a CI server, on every branch with every commit.
That's continuous building, and a Good Thing, but there's no *integration*, so it's not CI."

In conclusion, you should try to prevent merge commits, but not eliminate them.
Your codebase should be clean, but your history should represent what actually happened.
Developing software happens in small, messy steps, and it is OK to have your history reflect this.
You can use tools to view the network graphs of commits and understand the messy history that created your code.
If you rebase code, the commit history changes. Because of changed commit identifiers, tools can't restore the commit history.

## Commit often and push frequently

Another way to make your development work easier is to commit often.
Every time you have a working set of tests and code, you should make a commit.
Splitting up work into individual commits provides context for developers looking at your code later.
Smaller commits make it clear how a feature was developed. They help you roll back to a specific good point in time, or to revert one code change without reverting several unrelated changes.

Committing often also helps you share your work, which is important so that everyone is aware of what you are working on.
You should push your feature branch frequently, even when it is not yet ready for review.
By sharing your work in a feature branch or [a merge request](#mergepull-requests-with-gitlab-flow), you prevent your team members from duplicating work.
Sharing your work before it's complete also allows for discussion and feedback about the changes. This feedback can help improve the code before it gets to review.

## How to write a good commit message

A commit message should reflect your intention, not just the contents of the commit.
You can see the changes in a commit, so the commit message should explain why you made those changes:

```shell
# This commit message doesn't give enough information
git commit -m 'Improve XML generation'

# These commit messages clearly state the intent of the commit
git commit -m 'Properly escape special characters in XML generation'
```

An example of a good commit message is: "Combine templates to reduce duplicate code in the user views."
The words "change," "improve," "fix," and "refactor" don't add much information to a commit message.
For more information, see Tim Pope's excellent [note about formatting commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

To add more context to a commit message, consider adding information regarding the
origin of the change, such the GitLab issue URL or Jira issue number. That way, you provide 
more information for users who need in-depth context about the change.

For example:

```plaintext
Properly escape special characters in XML generation.

Issue: gitlab.com/gitlab-org/gitlab/-/issues/1
```

## Testing before merging

In old workflows, the continuous integration (CI) server commonly ran tests on the `main` branch only.
Developers had to ensure their code did not break the `main` branch.
When using GitLab flow, developers create their branches from this `main` branch, so it is essential that it never breaks.
Therefore, each merge request must be tested before it is accepted.
CI software like Travis CI and GitLab CI/CD show the build results right in the merge request itself to simplify the process.

There is one drawback to testing merge requests: the CI server only tests the feature branch itself, not the merged result.
Ideally, the server could also test the `main` branch after each change.
However, retesting on every commit to `main` is computationally expensive and means you are more frequently waiting for test results.
Because feature branches should be short-lived, testing just the branch is an acceptable risk.
If new commits in `main` cause merge conflicts with the feature branch, merge `main` back into the branch to make the CI server re-run the tests.
As said before, if you often have feature branches that last for more than a few days, you should make your issues smaller.

## Working with feature branches

When creating a feature branch, always branch from an up-to-date `main`.
If you know before you start that your work depends on another branch, you can also branch from there.
If you need to merge in another branch after starting, explain the reason in the merge commit.
If you have not pushed your commits to a shared location yet, you can also incorporate changes by rebasing on `main` or another feature branch.
Do not merge from upstream again if your code can work and merge cleanly without doing so.
Merging only when needed prevents creating merge commits in your feature branch that later end up littering the `main` history.
