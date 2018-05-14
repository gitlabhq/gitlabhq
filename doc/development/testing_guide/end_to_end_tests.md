# End-to-End Testing

## What is End-to-End testing?

End-to-End testing is a strategy used to check whether your application works
as expected across entire software stack and architecture, including
integration of all microservices and components that are supposed to work
together.

## How do we test GitLab?

We use [Omnibus GitLab][omnibus-gitlab] to build GitLab packages and then we
test these packages using [GitLab QA][gitlab-qa] project, which is entirely
black-box, click-driven testing framework.

### Testing nightly builds

We run scheduled pipeline each night to test nightly builds created by Omnibus.
You can find these nightly pipelines at [GitLab QA pipelines page][gitlab-qa-pipelines].

### Testing code in merge requests

It is possible to run end-to-end tests (eventually being run within a
[GitLab QA pipeline][gitlab-qa-pipelines]) for a merge request by triggering
the `package-and-qa` manual action, that should be present in a merge request
widget.

Manual action that starts end-to-end tests is also available in merge requests
in Omnibus GitLab project.

Below you can read more about how to use it and how does it work.

#### How does it work?

Currently, we are using _multi-project pipeline_-like approach to run QA
pipelines.

1. Developer triggers a manual action, that can be found in CE and EE merge
requests. This starts a chain of pipelines in multiple projects.

1. The script being executed triggers a pipeline in GitLab Omnibus and waits
for the resulting status. We call this a _status attribution_.

1. GitLab packages are being built in Omnibus pipeline. Packages are going to be
pushed to Container Registry.

1. When packages are ready, and available in the registry, a final step in the
pipeline, that is now running in Omnibus, triggers a new pipeline in the GitLab
QA project. It also waits for a resulting status.

1. GitLab QA pulls images from the registry, spins-up containers and runs tests
against a test environment that has been just orchestrated by the `gitlab-qa`
tool.

1. The result of the GitLab QA pipeline is being propagated upstream, through
Omnibus, back to CE / EE merge request.

#### How do I write tests?

In order to write new tests, you first need to learn more about GitLab QA
architecture. See the [documentation about it][gitlab-qa-architecture] in
GitLab QA project.

Once you decided where to put test environment orchestration scenarios and
instance specs, take a look at the [relevant documentation][instance-qa-readme]
and examples in [the `qa/` directory][instance-qa-examples].

## Where can I ask for help?

You can ask question in the `#quality` channel on Slack (GitLab internal) or
you can find an issue you would like to work on in
[the issue tracker][gitlab-qa-issues] and start a new discussion there.

[omnibus-gitlab]: https://gitlab.com/gitlab-org/omnibus-gitlab
[gitlab-qa]: https://gitlab.com/gitlab-org/gitlab-qa
[gitlab-qa-pipelines]: https://gitlab.com/gitlab-org/gitlab-qa/pipelines
[gitlab-qa-architecture]: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/architecture.md
[gitlab-qa-issues]: https://gitlab.com/gitlab-org/gitlab-qa/issues
[instance-qa-readme]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/README.md
[instance-qa-examples]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/qa
