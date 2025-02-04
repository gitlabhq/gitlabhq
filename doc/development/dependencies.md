---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Dependencies
---

## Dependency updates

We use the [Renovate GitLab Bot](https://gitlab.com/gitlab-org/frontend/renovate-gitlab-bot) to
automatically create merge requests for updating (some) Node and Ruby dependencies in several projects.
You can find the up-to-date list of projects managed by the renovate bot in the project's README.

Some key dependencies updated using renovate are:

- [`@gitlab/ui`](https://gitlab.com/gitlab-org/gitlab-ui)
- [`@gitlab/svgs`](https://gitlab.com/gitlab-org/gitlab-svgs)
- [`@gitlab/eslint-plugin`](https://gitlab.com/gitlab-org/frontend/eslint-plugin)
- And any other package in the `@gitlab/` scope

We have the goal of updating [_all_ dependencies with renovate](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/21).

Updating dependencies automatically has several benefits, have a look at this [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53613).

- MRs are created automatically when new versions are released.
- MRs can easily be rebased and updated by just checking a checkbox in the MR description.
- MRs contain changelog summaries and links to compare the different package versions.
- MRs can be assigned to people directly responsible for the dependencies.

### Community contributions updating dependencies

It is okay to reject Community Contributions that solely bump dependencies.
Simple dependency updates are better done automatically for the reasons provided above.
If a community contribution needs to be rebased, runs into conflicts, or goes stale, the effort required
to instruct the contributor to correct it often outweighs the benefits.

If a dependency update is accompanied with significant migration efforts, due to major version updates,
a community contribution is acceptable.

Here is a message you can use to explain to community contributors as to why we reject simple updates:

```markdown
Hello CONTRIBUTOR!

Thank you very much for this contribution. It seems like you are doing a "simple" dependency update.

If a dependency update is as simple as increasing the version number, we'd like a Bot to do this to save you and ourselves some time.

This has certain benefits as outlined in our <a href="https://docs.gitlab.com/ee/development/fe_guide/dependencies.html#updating-dependencies">Frontend development guidelines</a>.

You might find that we do not currently update DEPENDENCY automatically, but we are planning to do so in [the near future](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/21).

Thank you for understanding, I will close this merge request.
/close
```
