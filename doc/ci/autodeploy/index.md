# Auto deploy

> [Introduced][mr-8135] in GitLab 8.15. Currently requires a [Public project][project-settings].

Auto deploy is an easy way to configure GitLab CI for the deployment of your
application. GitLab Community maintains a list of `.gitlab-ci.yml`
templates for various infrastructure providers and deployment scripts
powering them. These scripts are responsible for packaging your application,
setting up the infrastructure and spinning up necessary services (for
example a database).

You can use [project services][project-services] to store credentials to
your infrastructure provider and they will be available during the
deployment.

## Supported templates

The list of supported auto deploy templates is available [here][auto-deploy-templates].

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

[mr-8135]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8135
[project-settings]: https://docs.gitlab.com/ce/public_access/public_access.html
[project-services]: ../../user/project/integrations/project_services.md
[auto-deploy-templates]: https://gitlab.com/gitlab-org/gitlab-ci-yml/tree/master/autodeploy
[kubernetes-service]: ../../user/project/integrations/kubernetes.md
[docker-in-docker]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[review-app]: ../review_apps/index.md
