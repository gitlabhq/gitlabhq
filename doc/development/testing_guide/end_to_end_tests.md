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

It is also possible to trigger packages build and [GitLab QA pipeline][gitlab-qa-pipelines]
using a manual action that should be present in the merge request widget on
your merge request. Look for `package-qa` manual action.

Below you can read more about how to use it and how does it work.

## How does it work?

We are using _multi-project pipelines_ to run end-to-end tests.

## How do I test my code?

## How do I contribute?

## Where can I ask for help?


[omnibus-gitlab]: https://gitlab.com/gitlab-org/omnibus-gitlab
[gitlab-qa]: https://gitlab.com/gitlab-org/gitlab-qa
[gitlab-qa-pipelines]: https://gitlab.com/gitlab-org/gitlab-qa/pipelines
