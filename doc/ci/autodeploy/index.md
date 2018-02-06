# Auto Deploy

> [Introduced][mr-8135] in GitLab 8.15.
> Auto deploy is an experimental feature and is **not recommended for Production use** at this time.

> As of GitLab 9.1, access to the container registry is only available while the
Pipeline is running. Restarting a pod, scaling a service, or other actions which
require on-going access **will fail**. On-going secure access is planned for a
subsequent release.

> As of GitLab 10.0, Auto Deploy templates are **deprecated** and the
functionality has been included in [Auto
DevOps](../../topics/autodevops/index.md).

Auto deploy is an easy way to configure GitLab CI for the deployment of your
application. GitLab Community maintains a list of `.gitlab-ci.yml`
templates for various infrastructure providers and deployment scripts
powering them. These scripts are responsible for packaging your application,
setting up the infrastructure and spinning up necessary services (for
example a database).

## How it works

The Autodeploy templates are based on the [kubernetes-deploy][kube-deploy]
project which is used to simplify the deployment process to Kubernetes by
providing intelligent `build`, `deploy`, and `destroy` commands which you can
use in your `.gitlab-ci.yml` as is. It uses [Herokuish](https://github.com/gliderlabs/herokuish),
which uses [Heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks)
to do some of the work, plus some of GitLab's own tools to package it all up. For
your convenience, a [Docker image][kube-image] is also provided.

You can use the [Kubernetes project service](../../user/project/integrations/kubernetes.md)
to store credentials to your infrastructure provider and they will be available
during the deployment.

## Quick start

We made a [simple guide](quick_start_guide.md) to using Auto Deploy with GitLab.com.

For a demonstration of GitLab Auto Deploy, read the blog post [Auto Deploy from GitLab to an OpenShift Container Cluster](https://about.gitlab.com/2017/05/16/devops-containers-gitlab-openshift/)

## Supported templates

The list of supported auto deploy templates is available in the
[gitlab-ci-yml project][auto-deploy-templates].

## Configuration

>**Note:**
In order to understand why the following steps are required, read the
[how it works](#how-it-works) section.

To configure Autodeploy, you will need to:

1. Enable a deployment [project service][project-services] to store your
   credentials. For example, if you want to deploy to OpenShift you have to
   enable [Kubernetes service][kubernetes-service].
1. Configure GitLab Runner to use the
   [Docker or Kubernetes executor](https://docs.gitlab.com/runner/executors/) with
   [privileged mode enabled][docker-in-docker].
1. Navigate to the "Project" tab and click "Set up auto deploy" button.
   ![Auto deploy button](img/auto_deploy_button.png)
1. Select a template.
  ![Dropdown with auto deploy templates](img/auto_deploy_dropdown.png)
1. Commit your changes and create a merge request.
1. Test your deployment configuration using a [Review App][review-app] that was
   created automatically for you.

## Private project support

> Experimental support [introduced][mr-2] in GitLab 9.1.

When a project has been marked as private, GitLab's [Container Registry][container-registry] requires authentication when downloading containers. Auto deploy will automatically provide the required authentication information to Kubernetes, allowing temporary access to the registry. Authentication credentials will be valid while the pipeline is running, allowing for a successful initial deployment.

After the pipeline completes, Kubernetes will no longer be able to access the container registry. Restarting a pod, scaling a service, or other actions which require on-going access to the registry will fail. On-going secure access is planned for a subsequent release.

## PostgreSQL database support

> Experimental support [introduced][mr-8] in GitLab 9.1.

In order to support applications that require a database, [PostgreSQL][postgresql] is provisioned by default. Credentials to access the database are preconfigured, but can be customized by setting the associated [variables](#postgresql-variables). These credentials can be used for defining a `DATABASE_URL` of the format: `postgres://user:password@postgres-host:postgres-port/postgres-database`. It is important to note that the database itself is temporary, and contents will be not be saved.

PostgreSQL provisioning can be disabled by setting the variable `DISABLE_POSTGRES` to `"yes"`.

The following PostgreSQL variables are supported:

1. `DISABLE_POSTGRES: "yes"`: disable automatic deployment of PostgreSQL
1. `POSTGRES_USER: "my-user"`: use custom username for PostgreSQL
1. `POSTGRES_PASSWORD: "password"`: use custom password for PostgreSQL
1. `POSTGRES_DB: "my database"`: use custom database name for PostgreSQL

## Auto Monitoring

> Introduced in [GitLab 9.5](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13438).

Apps auto-deployed using one the [Kubernetes templates](#supported-templates) can also be automatically monitored for:

* Response Metrics: latency, throughput, error rate
* System Metrics: CPU utilization, memory utilization

Metrics are gathered from [nginx-ingress](../../user/project/integrations/prometheus_library/nginx_ingress.md) and [Kubernetes](../../user/project/integrations/prometheus_library/kubernetes.md).

To view the metrics, open the [Monitoring dashboard for a deployed environment](../environments.md#monitoring-environments).

![Auto Metrics](img/auto_monitoring.png)

### Configuring Auto Monitoring

If GitLab has been deployed using the [omnibus-gitlab](../../install/kubernetes/gitlab_omnibus.md) Helm chart, no configuration is required.

If you have installed GitLab using a different method:

1. [Deploy Prometheus](../../user/project/integrations/prometheus.md#configuring-your-own-prometheus-server-within-kubernetes) into your Kubernetes cluster
1. If you would like response metrics, ensure you are running at least version 0.9.0 of NGINX Ingress and [enable Prometheus metrics](https://github.com/kubernetes/ingress/blob/master/examples/customization/custom-vts-metrics/nginx/nginx-vts-metrics-conf.yaml).
1. Finally, [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) the NGINX Ingress deployment to be scraped by Prometheus using `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

[mr-8135]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8135
[mr-2]: https://gitlab.com/gitlab-examples/kubernetes-deploy/merge_requests/2
[mr-8]: https://gitlab.com/gitlab-examples/kubernetes-deploy/merge_requests/8
[project-settings]: https://docs.gitlab.com/ce/public_access/public_access.html
[project-services]: ../../user/project/integrations/project_services.md
[auto-deploy-templates]: https://gitlab.com/gitlab-org/gitlab-ci-yml/tree/master/autodeploy
[kubernetes-service]: ../../user/project/integrations/kubernetes.md
[docker-in-docker]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[review-app]: ../review_apps/index.md
[kube-image]: https://gitlab.com/gitlab-examples/kubernetes-deploy/container_registry "Kubernetes deploy Container Registry"
[kube-deploy]: https://gitlab.com/gitlab-examples/kubernetes-deploy "Kubernetes deploy example project"
[container-registry]: https://docs.gitlab.com/ce/user/project/container_registry.html
[postgresql]: https://www.postgresql.org/
