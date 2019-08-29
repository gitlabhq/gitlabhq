# Tracing **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/7903) in GitLab Ultimate 11.5.

Tracing provides insight into the performance and health of a deployed application,
tracking each function or microservice which handles a given request.

This makes it easy to
understand the end-to-end flow of a request, regardless of whether you are using a monolithic or distributed system.

## Jaeger tracing

[Jaeger](https://www.jaegertracing.io/) is an open source, end-to-end distributed
tracing system used for monitoring and troubleshooting microservices-based distributed
systems.

### Deploying Jaeger

To learn more about deploying Jaeger, read the official
[Getting Started documentation](https://www.jaegertracing.io/docs/latest/getting-started/).
There is an easy to use [all-in-one Docker image](https://www.jaegertracing.io/docs/latest/getting-started/#AllinoneDockerimage),
as well as deployment options for [Kubernetes](https://github.com/jaegertracing/jaeger-kubernetes)
and [OpenShift](https://github.com/jaegertracing/jaeger-openshift).

### Enabling Jaeger

GitLab provides an easy way to open the Jaeger UI from within your project:

1. [Set up Jaeger](#deploying-jaeger) and configure your application using one of the
   [client libraries](https://www.jaegertracing.io/docs/latest/client-libraries/).
1. Navigate to your project's **Settings > Operations** and provide the Jaeger URL.
1. Click **Save changes** for the changes to take effect.
1. You can now visit **Operations > Tracing** in your project's sidebar and
   GitLab will redirect you to the configured Jaeger URL.
