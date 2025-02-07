---
stage: Monitor
group: Platform Insights
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Documentation for developers interested in contributing features or bugfixes for GitLab Observability."
title: GitLab Observability development guidelines
---

## GitLab Observability development setup

There are several options for developing and debugging GitLab Observability:

- [Run GDK and GitLab Observability Backend locally all-in-one](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_observability_backend.md): This is the simplest and recommended approach for those looking to make changes, or verify changes to Rails, Sidekiq or Workhorse.
- [Run GDK locally and connect to the staging instance](#run-gdk-and-connect-to-the-staging-instance-of-gitlab-observability-backend) of [GitLab Observability Backend](https://gitlab.com/gitlab-org/opstrace/opstrace). This is an alternative approach for those looking to make changes, or verify changes to Rails, Sidekiq or Workhorse.
- [Use the purpose built `devvm`](#use-the-purpose-built-devvm). This is more involved but includes a development deployment of the [GitLab Observability Backend](https://gitlab.com/gitlab-org/opstrace/opstrace). This is recommended for those who want to make changes to the GitLab Observability Backend component.
- [Run GDK with mocked Observability data](#run-gdk-with-mocked-observability-data). This could be useful in case you just need to work on a frontend or Rails change and do not need the full stack, or when providing reproduction steps for an MR reviewer, who probably won't want to set up the full stack just for an MR.

### Run GDK and connect to the staging instance of GitLab Observability Backend

This method takes advantage of our Cloud Connected Observability Backend. Your GitLab instance will require a valid Cloud License and will be treated as a self-managed instance, connected to a multi-tenant GitLab-hosted instance of the GitLab Observability Backend. See [this design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/observability_for_self_managed/) for more details on how this works.

How to enable:

1. Add a **GitLab Ultimate Self-Managed** subscription to your GDK instance.

   1. Sign in to the [staging Customers Portal](https://customers.staging.gitlab.com) by selecting the **Continue with GitLab.com account** button.
   If you do not have an existing account, you are prompted to create one.
   1. If you do not have an existing cloud activation code, click the **Staging Self-Managed Ultimate Subscription** link on the [new subscription purchase links page](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/doc/flows/self_service_flow_urls.md#new-subscription-purchase-links).
   1. Select enough seats to cover the number of users in your GDK instance (200 should be plenty).
   1. Purchase the subscription using [a test credit card](https://gitlab.com/gitlab-org/customers-gitlab-com/#testing-credit-card-information).

   After this step is complete, you will have an activation code for a _GitLab Ultimate Self-Managed subscription_.

1. Set environment variables to point customers-dot to staging, and the Observability URL to staging. For GDK, this can be done in `<gdk-root>/env.runit`:

   ```shell
   export GITLAB_SIMULATE_SAAS=0
   export GITLAB_LICENSE_MODE=test
   export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
   export OVERRIDE_OBSERVABILITY_QUERY_URL=https://observe.staging.gitlab.com
   export OVERRIDE_OBSERVABILITY_INGEST_URL=https://observe.staging.gitlab.com
   ```

   On a non-GDK/GCK instance, you can set the variables using `gitlab_rails['env']` in the `gitlab.rb` file:

   ```shell
   gitlab_rails['env'] = {
   'GITLAB_LICENSE_MODE' => 'test',
   'CUSTOMER_PORTAL_URL' => 'https://customers.staging.gitlab.com',
   'OVERRIDE_OBSERVABILITY_QUERY_URL' => 'https://observe.staging.gitlab.com',
   'OVERRIDE_OBSERVABILITY_INGEST_URL' => 'https://observe.staging.gitlab.com'
   }
   ```

1. Enable the feature flag for GitLab Observability features:
   1. Start a rails console session:
      - GDK: `gdk rails console`
      - GCK: `make console`
      - GitLab Distribution: [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session)
   1. Run `Feature.enable(:observability_features);`
1. Restart your instance (e.g. `gdk restart`).
1. Follow the [instructions to activate your new license](../../administration/license.md#activate-gitlab-ee).
1. Test out the GitLab Observability feature by navigating to a project and selecting Tracing, Metrics, or Logs from the Monitor section of the navigation menu.
1. If you are seeing 404 errors you might need to manually [refresh](../../subscriptions/self_managed/_index.md#manually-synchronize-subscription-data) your license data.

### Use the purpose built `devvm`

Visit [`devvm`](https://gitlab.com/gitlab-org/opstrace/devvm) and follow the README instructions for setup and developing against it.

## Use the OpenTelemetry Demo app to send data to a project

The [OpenTelemetry Demo app](https://opentelemetry.io/docs/demo/) is a great way to run several Docker containers (representing a distributed system), and to send the logs, metrics, and traces to your local GDK instance.

You can reference the instructions for running the demo app [here](https://opentelemetry.io/docs/demo/docker-deployment/).

### OpenTelemetry Demo app Quickstart

1. Clone the Demo repository:

   ```shell
   git clone https://github.com/open-telemetry/opentelemetry-demo.git
   ```

1. Change to the demo folder:

   ```shell
   cd opentelemetry-demo/
   ```

1. Create a project in your local GDK instance. Take note of the project ID.
1. In the newly created project, create a project access token with **Developer** role and **API** scope. Save the token for use in the next step.
1. With an editor, edit the configuration in `src/otelcollector/otelcol-config-extras.yml`. Add the following YAML, replacing:

   - `$GDK_HOST` with the host and `$GDK_PORT` with the port number of your GitLab instance.
   - `$PROJECT_ID` with the project ID and `$TOKEN` with the token created in the previous steps.

   ```yaml
   exporters:
      otlphttp/gitlab:
         endpoint: http://$GDK_HOST:$GDK_PORT/api/v4/projects/$PROJECT_ID/observability/
         headers:
            "private-token": "$TOKEN"

   service:
      pipelines:
         traces:
            exporters: [spanmetrics, otlphttp/gitlab]
         metrics:
            exporters: [otlphttp/gitlab]
         logs:
            exporters: [otlphttp/gitlab]
   ```

NOTE:
For GDK and Docker to communicate you may need to set up a [loopback interface](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/local_network.md#create-loopback-interface).

1. Save the configuration and start the demo app:

   ```shell
   docker compose up --force-recreate --remove-orphans --detach
   ```

1. [Visit the UI to generate data](https://opentelemetry.io/docs/demo/docker-deployment/#verify-the-web-store-and-telemetry).
1. Verify Telemetry by exploring logs, metrics, and traces under the Monitor menu in your GitLab project.

### Run GDK with mocked Observability data

Apply the following [patch](https://gitlab.com/gitlab-org/opstrace/opstrace/-/snippets/3747939) to override Observability API calls with local mocks:

```shell
git apply < <(curl --silent "https://gitlab.com/gitlab-org/opstrace/opstrace/-/snippets/3747939/raw/main/mock.patch")
```
