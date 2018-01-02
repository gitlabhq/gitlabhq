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

It is also possible to trigger build of GitLab packages and then pass these
package to GitLab QA to run tests in a [pipeline][gitlab-qa-pipelines].

Developers can trigger a `package-qa` manual action, that should be present in
the merge request widget in your merge request.

It is possible to trigger Gitlab QA pipeline from merge requests in GitLab CE
and GitLab EE, but QA triggering manual action is also available in the Omnibus
GitLab project as well.

Below you can read more about how to use it and how does it work.

#### How does it work?

Currently, we are _multi-project pipeline_-like approach to run QA pipelines.

1. Developer triggers manual action in the CE or EE merge request, that starts
a chain of pipelines.
1. Triggering this action enqueues a new CI job that is going to be picked by a
runner.
1. The script, that is being executed, triggers a pipeline in GitLab Omnibus
projects, and waits for the resulting status. We call it _status attribution_.
1. GitLab packages are being built in the pipeline started in Omnibus. Packages
are going to be sent to Container Registry.
1. When packages are ready, and available in the registry, a final step in the
pipeline that is now running in Omnibus triggers a new pipeline in the GitLab
QA project. It also waits for the resulting status.
1. GitLab QA pulls images from the registry, spins-up containers and runs tests
against test environment that has been just orchestrated.
1. The result of GitLab QA pipeline is being propagated upstream, through
Omnibus, to CE / EE merge request.

#### How do I write tests?

In order to write new tests, you first need to learn more about GitLab QA
architecture. There is some documentation about it in GitLab QA project
[here][gitlab-qa-architecture].

Once you decided we to put test environment orchestration scenarios and
instance specs, take a looks at [relevant documentation][instance-qa-readme]

## Where can I ask for help?

You can ask question in `#qa` channel on Slack (GitLab internal) or you can
find an issue you would like to work on in [the issue tracker][gitlab-qa-issues]
and start a new discussion there.

[omnibus-gitlab]: https://gitlab.com/gitlab-org/omnibus-gitlab
[gitlab-qa]: https://gitlab.com/gitlab-org/gitlab-qa
[gitlab-qa-pipelines]: https://gitlab.com/gitlab-org/gitlab-qa/pipelines
[instance-qa-readme]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/README.md
[gitlab-qa-architecture]: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/architecture.md
[gitlab-qa-issues]: https://gitlab.com/gitlab-org/gitlab-qa/issues
