---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Danger bot

The GitLab CI/CD pipeline includes a `danger-review` job that uses [Danger](https://github.com/danger/danger)
to perform a variety of automated checks on the code under test.

Danger is a gem that runs in the CI environment, like any other analysis tool.
What sets it apart from (for example, RuboCop) is that it's designed to allow you to
easily write arbitrary code to test properties of your code or changes. To this
end, it provides a set of common helpers and access to information about what
has actually changed in your environment, then simply runs your code!

If Danger is asking you to change something about your merge request, it's best
just to make the change. If you want to learn how Danger works, or make changes
to the existing rules, then this is the document for you.

## Danger comments in merge requests

Danger only posts one comment and updates its content on subsequent
`danger-review` runs. Given this, it's usually one of the first few comments
in a merge request if not the first. If you didn't see it, try to look
from the start of the merge request.

### Advantages

- You don't get email notifications each time `danger-review` runs.

### Disadvantages

- It's not obvious Danger updates the old comment, thus you need to
  pay attention to it if it is updated or not.

## Run Danger locally

A subset of the current checks can be run locally with the following Rake task:

```shell
bin/rake danger_local
```

## Operation

On startup, Danger reads a [`Dangerfile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/Dangerfile)
from the project root. Danger code in GitLab is decomposed into a set of helpers
and plugins, all within the [`danger/`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/danger/)
subdirectory, so ours just tells Danger to load it all. Danger then runs
each plugin against the merge request, collecting the output from each. A plugin
may output notifications, warnings, or errors, all of which are copied to the
CI job's log. If an error happens, the CI job (and so the entire pipeline) fails.

On merge requests, Danger also copies the output to a comment on the MR
itself, increasing visibility.

## Development guidelines

Danger code is Ruby code, so all our [usual backend guidelines](index.md#backend-guides)
continue to apply. However, there are a few things that deserve special emphasis.

### When to use Danger

Danger is a powerful tool and flexible tool, but not always the most appropriate
way to solve a given problem or workflow.

First, be aware of the GitLab [commitment to dogfooding](https://about.gitlab.com/handbook/engineering/#dogfooding).
The code we write for Danger is GitLab-specific, and it **may not** be most
appropriate place to implement functionality that addresses a need we encounter.
Our users, customers, and even our own satellite projects, such as [Gitaly](https://gitlab.com/gitlab-org/gitaly),
often face similar challenges, after all. Think about how you could fulfill the
same need while ensuring everyone can benefit from the work, and do that instead
if you can.

If a standard tool (for example, `rubocop`) exists for a task, it's better to
use it directly, rather than calling it by using Danger. Running and debugging
the results of those tools locally is easier if Danger isn't involved, and
unless you're using some Danger-specific functionality, there's no benefit to
including it in the Danger run.

Danger is well-suited to prototyping and rapidly iterating on solutions, so if
what we want to build is unclear, a solution in Danger can be thought of as a
trial run to gather information about a product area. If you're doing this, make
sure the problem you're trying to solve, and the outcomes of that prototyping,
are captured in an issue or epic as you go along. This helps us to address
the need as part of the product in a future version of GitLab!

### Implementation details

Implement each task as an isolated piece of functionality and place it in its
own directory under `danger` as `danger/<task-name>/Dangerfile`.

Each task should be isolated from the others, and able to function in isolation.
If there is code that should be shared between multiple tasks, add a plugin to
`danger/plugins/...` and require it in each task that needs it. You can also
create plugins that are specific to a single task, which is a natural place for
complex logic related to that task.

Danger code is just Ruby code. It should adhere to our coding standards, and
needs tests, like any other piece of Ruby in our codebase. However, we aren't
able to test a `Dangerfile` directly! So, to maximize test coverage, try to
minimize the number of lines of code in `danger/`. A non-trivial `Dangerfile`
should mostly call plugin code with arguments derived from the methods provided
by Danger. The plugin code itself should have unit tests.

At present, we do this by putting the code in a module in `tooling/danger/...`,
and including it in the matching `danger/plugins/...` file. Specs can then be
added in `spec/tooling/danger/...`.

To determine if your `Dangerfile` works, push the branch that contains it to
GitLab. This can be quite frustrating, as it significantly increases the cycle
time when developing a new task, or trying to debug something in an existing
one. If you've followed the guidelines above, most of your code can be exercised
locally in RSpec, minimizing the number of cycles you need to go through in CI.
However, you can speed these cycles up somewhat by emptying the
`.gitlab/ci/rails.gitlab-ci.yml` file in your merge request. Just don't forget
to revert the change before merging!

To enable the Dangerfile on another existing GitLab project, run the following
extra steps:

1. Create a [Project access tokens](../user/project/settings/project_access_tokens.md).
1. Add the token as a CI/CD project variable named `DANGER_GITLAB_API_TOKEN`.

You should add the ~"Danger bot" label to the merge request before sending it
for review.

## Current uses

Here is a (non-exhaustive) list of the kinds of things Danger has been used for
at GitLab so far:

- Coding style
- Database review
- Documentation review
- Merge request metrics
- Reviewer roulette. Reviewers and maintainers are chosen based on:
  - Their roles (backend, frontend, database, etc).
  - Their availability:
    - No "OOO"/"PTO"/"Parental Leave" in their GitLab or Slack status.
    - No `:red_circle:`/`:palm_tree:`/`:beach:`/`:beach_umbrella:`/`:beach_with_umbrella:` emojis in GitLab or Slack status.
  - (Experimental) Their timezone: people for which the local hour is between
    6 AM and 2 PM are eligible to be picked. This is to ensure they have a good
    chance to get to perform a review during their current work day. The experimentation is tracked in
    [this issue](https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/563)
- Single codebase effort

## Limitations

Danger is run but its output is not added to a merge request comment if working
on a fork. This happens because the secret variable from the canonical project
is not shared to forks. To work around this, you can add an [environment
variable](../ci/variables/index.md) called `DANGER_GITLAB_API_TOKEN` with a
[personal API token](https://gitlab.com/-/profile/personal_access_tokens?name=GitLab+Dangerbot&scopes=api)
to your fork that has the `api` scope set. That way the danger comments are made
from CI using that API token instead. Making the variable
[masked](../ci/variables/index.md#mask-a-cicd-variable) makes sure it
doesn't show up in the job logs. The variable cannot be
[protected](../ci/variables/index.md#protect-a-cicd-variable), as it needs
to be present for all feature branches.
