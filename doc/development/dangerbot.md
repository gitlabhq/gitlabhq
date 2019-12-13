# Danger bot

The GitLab CI pipeline includes a `danger-review` job that uses [Danger](https://github.com/danger/danger)
to perform a variety of automated checks on the code under test.

Danger is a gem that runs in the CI environment, like any other analysis tool.
What sets it apart from, e.g., Rubocop, is that it's designed to allow you to
easily write arbitrary code to test properties of your code or changes. To this
end, it provides a set of common helpers and access to information about what
has actually changed in your environment, then simply runs your code!

If Danger is asking you to change something about your merge request, it's best
just to make the change. If you want to learn how Danger works, or make changes
to the existing rules, then this is the document for you.

## Operation

On startup, Danger reads a [`Dangerfile`](https://gitlab.com/gitlab-org/gitlab/blob/master/Dangerfile)
from the project root. GitLab's Danger code is decomposed into a set of helpers
and plugins, all within the [`danger/`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/danger/)
subdirectory, so ours just tells Danger to load it all. Danger will then run
each plugin against the merge request, collecting the output from each. A plugin
may output notifications, warnings, or errors, all of which are copied to the
CI job's log. If an error happens, the CI job (and so the entire pipeline) will
be failed.

On merge requests, Danger will also copy the output to a comment on the MR
itself, increasing visibility.

## Development guidelines

Danger code is Ruby code, so all our [usual backend guidelines](README.md#backend-guides)
continue to apply. However, there are a few things that deserve special emphasis.

### When to use Danger

Danger is a powerful tool and flexible tool, but not always the most appropriate
way to solve a given problem or workflow.

First, be aware of GitLab's [commitment to dogfooding](https://about.gitlab.com/handbook/engineering/#dogfooding).
The code we write for Danger is GitLab-specific, and it **may not** be most
appropriate place to implement functionality that addresses a need we encounter.
Our users, customers, and even our own satellite projects, such as [Gitaly](https://gitlab.com/gitlab-org/gitaly),
often face similar challenges, after all. Think about how you could fulfil the
same need while ensuring everyone can benefit from the work, and do that instead
if you can.

If a standard tool (e.g. `rubocop`) exists for a task, it is better to use it
directly, rather than calling it via Danger. Running and debugging the results
of those tools locally is easier if Danger isn't involved, and unless you're
using some Danger-specific functionality, there's no benefit to including it in
the Danger run.

Danger is well-suited to prototyping and rapidly iterating on solutions, so if
what we want to build is unclear, a solution in Danger can be thought of as a
trial run to gather information about a product area. If you're doing this, make
sure the problem you're trying to solve, and the outcomes of that prototyping,
are captured in an issue or epic as you go along. This will help us to address
the need as part of the product in a future version of GitLab!

### Implementation details

Implement each task as an isolated piece of functionality and place it in its
own directory under `danger` as `danger/<task-name>/Dangerfile`.

Add a line to the top-level `Dangerfile` to ensure it is loaded like:

```ruby
danger.import_dangerfile('danger/<task-name>')
```

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

At present, we do this by putting the code in a module in `lib/gitlab/danger/...`,
and including it in the matching `danger/plugins/...` file. Specs can then be
added in `spec/lib/gitlab/danger/...`.

You'll only know if your `Dangerfile` works by pushing the branch that contains
it to GitLab. This can be quite frustrating, as it significantly increases the
cycle time when developing a new task, or trying to debug something in an
existing one. If you've followed the guidelines above, most of your code can
be exercised locally in RSpec, minimizing the number of cycles you need to go
through in CI. However, you can speed these cycles up somewhat by emptying the
`.gitlab/ci/rails.gitlab-ci.yml` file in your merge request. Just don't forget
to revert the change before merging!

To enable the Dangerfile on another existing GitLab project, run the following extra steps, based on [this procedure](https://danger.systems/guides/getting_started.html#creating-a-bot-account-for-danger-to-use):

1. Add `@gitlab-bot` to the project as a `reporter`.
1. Add the `@gitlab-bot`'s `GITLAB_API_PRIVATE_TOKEN` value as a value for a new CI/CD
   variable named `DANGER_GITLAB_API_TOKEN`.

You should add the `~Danger bot` label to the merge request before sending it
for review.

## Current uses

Here is a (non-exhaustive) list of the kinds of things Danger has been used for
at GitLab so far:

- Coding style
- Database review workflow
- Documentation review workflow
- Merge request metrics
- Reviewer roulette workflow
- Single codebase effort

## Limitations

- [`danger local` does not work on GitLab](https://github.com/danger/danger/issues/458)
- Danger output is not added to a merge request comment if working on a fork.
