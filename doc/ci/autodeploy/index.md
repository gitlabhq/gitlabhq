# Auto deploy

> [Introduced][mr-8135] in GitLab 8.15.
> Auto deploy is an experimental feature and is not recommended for Production use at this time.
> As of GitLab 9.1, access to the container registry is only available while the Pipeline is running. Restarting a pod, scaling a service, or other actions which require on-going access will fail. On-going secure access is planned for a subsequent release.

Auto deploy is an easy way to configure GitLab CI for the deployment of your
application. GitLab Community maintains a list of `.gitlab-ci.yml`
templates for various infrastructure providers and deployment scripts
powering them. These scripts are responsible for packaging your application,
setting up the infrastructure and spinning up necessary services (for
example a database).

You can use [project services][project-services] to store credentials to
your infrastructure provider and they will be available during the
deployment.

## Quick start

We made a [simple guide](quick_start_guide.md) to using Auto Deploy with GitLab.com.

## Supported templates

The list of supported auto deploy templates is available in the
[gitlab-ci-yml project][auto-deploy-templates].

## Configuration

1. Enable a deployment [project service][project-services] to store your
credentials. For example, if you want to deploy to OpenShift you have to
enable [Kubernetes service][kubernetes-service].
1. Configure GitLab Runner to use Docker or Kubernetes executor with
[privileged mode enabled][docker-in-docker].
1. Navigate to the "Project" tab and click "Set up auto deploy" button.
   ![Auto deploy button](img/auto_deploy_button.png)
1. Select a template.
  ![Dropdown with auto deploy templates](img/auto_deploy_dropdown.png)
1. Commit your changes and create a merge request.
1. Test your deployment configuration using a [Review App][review-app] that was
created automatically for you.

## Using the Kubernetes deploy example project with Nginx

The Autodeploy templates are based on the [kubernetes-deploy][kube-deploy]
project which is used to simplify the deployment process to Kubernetes by
providing intelligent `build`, `deploy` and `destroy` commands which you can
use in your `.gitlab-ci.yml` as-is. It uses Heroku'ish build packs to do some
of the work, plus some of GitLab's own tools to package it all up. For your
convenience, a [Docker image][kube-image] is also provided.

---

A simple example would be the deployment of Nginx on Kubernetes.
Consider a `nginx-deployment.yaml` file in your project with contents:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: __CI_ENVIRONMENT_SLUG__
  labels:
    app: __CI_ENVIRONMENT_SLUG__
    track: stable
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: __CI_ENVIRONMENT_SLUG__
        track: stable
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

The important part is where we set up `app: __CI_ENVIRONMENT_SLUG__`. As you'll
see later this is replaced by the [`CI_ENVIRONMENT_SLUG` env variable][variables].

The `.gitlab-ci.yml` would be:

```yaml
image: registry.gitlab.com/gitlab-examples/kubernetes-deploy

stages:
  - deploy

kubernetes deploy:
  stage: deploy
  environment:
    name: production
  script:
    - echo "$KUBE_CA_PEM" > kube_ca.pem
    - cat kube_ca.pem
    - kubectl config set-cluster default-cluster --server=$KUBE_URL --certificate-authority="$(pwd)/kube_ca.pem"
    - kubectl config set-credentials default-admin --token=$KUBE_TOKEN
    - kubectl config set-context default-system --cluster=default-cluster --user=default-admin --namespace $KUBE_NAMESPACE
    - kubectl config use-context default-system

    - sed -i "s/__CI_ENVIRONMENT_SLUG__/$CI_ENVIRONMENT_SLUG/" nginx-deployment.yaml
    - cat nginx-deployment.yaml
    - kubectl cluster-info
    - kubectl get deployments -l app=$CI_ENVIRONMENT_SLUG
    - kubectl create -f nginx-deployment.yaml || kubectl replace -f nginx-deployment.yaml
```

Notice that we use a couple of Kubernetes environment variables to configure
the Kubernetes cluster. These are exposed from the
[Kubernetes service](../../user/project/integrations/kubernetes.md#deployment-variables).
The most important one is the `$KUBE_NAMESPACE` which should be unique for
every project.

Next, we replace `__CI_ENVIRONMENT_SLUG__` with the content of the
`CI_ENVIRONMENT_SLUG` variable, so that the `app` label has the correct value.

Finally, the Nginx pod is created from the definition of the
`nginx-deployment.yaml` file.

## Private Project Support

> Experimental support [introduced][mr-2] in GitLab 9.1.

When a project has been marked as private, GitLab's [Container Registry][container-registry] requires authentication when downloading containers. Auto deploy will automatically provide the required authentication information to Kubernetes, allowing temporary access to the registry. Authentication credentials will be valid while the pipeline is running, allowing for a successful initial deployment.

After the pipeline completes, Kubernetes will no longer be able to access the container registry. Restarting a pod, scaling a service, or other actions which require on-going access to the registry will fail. On-going secure access is planned for a subsequent release.

## PostgreSQL Database Support

> Experimental support [introduced][mr-8] in GitLab 9.1.

In order to support applications that require a database, [PostgreSQL][postgresql] is provisioned by default. Credentials to access the database are preconfigured, but can be customized by setting the associated [variables](#postgresql-variables). These credentials can be used for defining a `DATABASE_URL` of the format: `postgres://user:password@postgres-host:postgres-port/postgres-database`. It is important to note that the database itself is temporary, and contents will be not be saved.

PostgreSQL provisioning can be disabled by setting the variable `DISABLE_POSTGRES` to `"yes"`.

### PostgreSQL Variables

1. `DISABLE_POSTGRES: "yes"`: disable automatic deployment of PostgreSQL
1. `POSTGRES_USER: "my-user"`: use custom username for PostgreSQL
1. `POSTGRES_PASSWORD: "password"`: use custom password for PostgreSQL
1. `POSTGRES_DB: "my database"`: use custom database name for PostgreSQL

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
