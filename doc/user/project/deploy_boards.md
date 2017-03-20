# Deploy Boards

> [Introduced][ce-1589] in [GitLab Enterprise Edition Premium][ee] 9.0.

If [Kubernetes] is your tool of choice for your application deployments, GitLab
offers a single place to view the current health and deployment status of each
[environment], displaying the specific status of each pod in the deployment.
Developers and other teammates can view the progress and status of a rollout,
pod by pod, in the workflow they already use without any need to access
Kubernetes.

## Overview

With Deploy Boards you can gain more insight into deploys with benefits such as:

- Following a deploy from the start, not just when it's done
- Watching the rollout of a build across multiple servers
- Finer state detail (Ready, Preparing, Waiting, Deploying, Finished, Failed)

Since Deploy Boards are tightly coupled with Kubernetes, there is some required
knowledge. In particular you should be familiar with:

- [Kubernetes pods](https://kubernetes.io/docs/user-guide/pods)
- [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

Here's an example of a Deploy Board of the production environment.

![Deploy Boards landing page](img/deploy_boards_landing_page.png)

The squares represent pods in your Kubernetes cluster that are associated with
the given environment. Hovering above each square you can see the state of a
deploy rolling out. The percentage is the percent of the pods that are updated
to the latest release.

## Enabling deploy boards

In order to have the Deploy Boards show up, you need to label your
deployments, replica sets and pods with `app=$CI_ENVIRONMENT_SLUG`.
Each project will need to have a unique namespace in Kubernetes as well.

In particular, here are the requirements for the Deploy Boards to show up in
your environments page:

1. You should have a Kubernetes cluster up and running
1. You should be using GitLab Runner using the [Docker][docker-exec] or
   [Kubernetes executor][kube-exec]
1. Enable the [Kubernetes service](integrations/kubernetes.md) in your project
1. Use the Kubernetes labels and label your deployments `app=$CI_ENVIRONMENT_SLUG`
   in the unique namespace specified in the Kubernetes service setting.
   Simplified by using the
   [Kubernetes deploy example](#using-the-kubernetes-deploy-example-project)
   Docker image.
1. Optionally, use an [auto-deploy](../../ci/autodeploy/index.md) `.gitlab-ci.yml`
   template which has some predefined stages and commands to use.

Once all of the above are set up and the pipeline has run at least once,
navigate to the environments page under **Pipelines ➔ Environments**. GitLab
will inspect Kubernetes for the state of each node (e.g., spinning up, down,
running version A, running version B) and Deploy Boards will be displayed on
the environments page.

Bare in mind that Deploy Boards are by default collapsed under their respective
environment but can be expanded. Only top-level environments can be expanded
by default, so if you for example use `review/*` for [review apps], the Deploy
Boards won't show up for that environment.

## Using the Kubernetes deploy example project

The [kubernetes-deploy] project is used to simplify the deployment process to
Kubernetes by providing the `build`, `deploy` and `destroy` commands which you
can use to your `.gitlab-ci.yml` as-is.

## Example

`nginx-deployment.yaml`:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: __CI_ENVIRONMENT_SLUG__
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

.gitlab-ci.yml:

```yaml
image: registry.gitlab.com/gitlab-examples/kubernetes-deploy

kubernetes deploy:
  stage:
    - deploy
  environment:
    name: $CI_BUILD_REF_NAME
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

[ce-1589]: https://gitlab.com/gitlab-org/gitlab-ee/issues/1589 "Deploy Boards intial issue"
[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[kubernetes-deploy]: https://gitlab.com/gitlab-examples/kubernetes-deploy "Kubernetes deploy example project"
[kubernetes]: https://kubernetes.io "Kubernetes website"
[environment]: ../../ci/environments.md "Environments and deployments documentation"
[docker-exec]: https://docs.gitlab.com/runner/executors/docker.html "GitLab Runner Docker executor"
[kube-exec]: https://docs.gitlab.com/runner/executors/kubernetes.html "GitLab Runner Kubernetes executor"
[review apps]: ../../ci/review_apps/index.md "Review Apps documentation"
