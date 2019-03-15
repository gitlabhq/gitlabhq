# End-to-end Testing

## What is end-to-end testing?

End-to-end testing is a strategy used to check whether your application works
as expected across the entire software stack and architecture, including
integration of all micro-services and components that are supposed to work
together.

## How do we test GitLab?

We use [Omnibus GitLab][omnibus-gitlab] to build GitLab packages and then we
test these packages using the [GitLab QA orchestrator][gitlab-qa] tool, which is
a black-box testing framework for the API and the UI.

### Testing nightly builds

We run scheduled pipeline each night to test nightly builds created by Omnibus.
You can find these nightly pipelines at [gitlab-org/quality/nightly/pipelines][quality-nightly-pipelines].

### Testing staging

We run scheduled pipeline each night to test staging.
You can find these nightly pipelines at [gitlab-org/quality/staging/pipelines][quality-staging-pipelines].

### Testing code in merge requests

It is possible to run end-to-end tests for a merge request, eventually being run in
a pipeline in the [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/) project,
by triggering the `package-and-qa` manual action in the `test` stage (which should
be present in a merge request widget, unless the merge request comes from a fork).

Manual action that starts end-to-end tests is also available in merge requests
in [Omnibus GitLab][omnibus-gitlab].

Below you can read more about how to use it and how does it work.

#### How does it work?

Currently, we are using _multi-project pipeline_-like approach to run QA
pipelines.

1. Developer triggers a manual action, that can be found in CE / EE merge
   requests. This starts a chain of pipelines in multiple projects.

1. The script being executed triggers a pipeline in [Omnibus GitLab][omnibus-gitlab]
   and waits for the resulting status. We call this a _status attribution_.

1. GitLab packages are being built in the [Omnibus GitLab][omnibus-gitlab]
   pipeline. Packages are then pushed to its Container Registry.

1. When packages are ready, and available in the registry, a final step in the
   [Omnibus GitLab][omnibus-gitlab] pipeline, triggers a new
   [GitLab QA pipeline][gitlab-qa-pipelines]. It also waits for a resulting status.

1. GitLab QA pulls images from the registry, spins-up containers and runs tests
   against a test environment that has been just orchestrated by the `gitlab-qa`
   tool.

1. The result of the [GitLab QA pipeline][gitlab-qa-pipelines] is being
   propagated upstream, through Omnibus, back to the CE / EE merge request.

#### How do I write tests?

In order to write new tests, you first need to learn more about GitLab QA
architecture. See the [documentation about it][gitlab-qa-architecture].

Once you decided where to put [test environment orchestration scenarios] and
[instance-level scenarios], take a look at the [GitLab QA README][instance-qa-readme],
the [GitLab QA orchestrator README][gitlab-qa-readme], and [the already existing
instance-level scenarios][instance-level scenarios].

## Where can I ask for help?

You can ask question in the `#quality` channel on Slack (GitLab internal) or
you can find an issue you would like to work on in
[the `gitlab-ce` issue tracker][gitlab-ce-issues],
[the `gitlab-ee` issue tracker][gitlab-ce-issues], or
[the `gitlab-qa` issue tracker][gitlab-qa-issues].

[omnibus-gitlab]: https://gitlab.com/gitlab-org/omnibus-gitlab
[gitlab-qa]: https://gitlab.com/gitlab-org/gitlab-qa
[gitlab-qa-readme]: https://gitlab.com/gitlab-org/gitlab-qa/tree/master/README.md
[quality-nightly-pipelines]: https://gitlab.com/gitlab-org/quality/nightly/pipelines
[quality-staging-pipelines]: https://gitlab.com/gitlab-org/quality/staging/pipelines
[gitlab-qa-architecture]: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/architecture.md
[gitlab-qa-issues]: https://gitlab.com/gitlab-org/gitlab-qa/issues?label_name%5B%5D=new+scenario
[gitlab-ce-issues]: https://gitlab.com/gitlab-org/gitlab-ce/issues?label_name[]=QA&label_name[]=test
[gitlab-ee-issues]: https://gitlab.com/gitlab-org/gitlab-ee/issues?label_name[]=QA&label_name[]=test
[test environment orchestration scenarios]: https://gitlab.com/gitlab-org/gitlab-qa/tree/master/lib/gitlab/qa/scenario
[instance-level scenarios]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/qa/specs/features
[Page objects documentation]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/qa/page/README.md
[instance-qa-readme]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/README.md
[instance-qa-examples]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/qa
