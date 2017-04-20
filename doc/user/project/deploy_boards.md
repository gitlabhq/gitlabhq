# Deploy Boards

> [Introduced][ce-1589] in [GitLab Enterprise Edition Premium][ee] 9.0.

GitLab's Deploy Boards offer a consolidated view of the current health and
status of each CI [environment] running on [Kubernetes], displaying the status
of the pods in the deployment. Developers and other teammates can view the
progress and status of a rollout, pod by pod, in the workflow they already use
without any need to access Kubernetes.

## Overview

With Deploy Boards you can gain more insight into deploys with benefits such as:

- Following a deploy from the start, not just when it's done
- Watching the rollout of a build across multiple servers
- Finer state detail (Waiting, Deploying, Finished, Unknown)
- See canary deployments

Since Deploy Boards are tightly coupled with Kubernetes, there is some required
knowledge. In particular you should be familiar with:

- [Kubernetes pods](https://kubernetes.io/docs/user-guide/pods)
- [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Kubernetes namespaces](https://kubernetes.io/docs/user-guide/namespaces/)
- [Kubernetes canary deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

Here's an example of a Deploy Board of the production environment.

![Deploy Boards landing page](img/deploy_boards_landing_page.png)

The squares represent pods in your Kubernetes cluster that are associated with
the given environment. Hovering above each square you can see the state of a
deploy rolling out. The percentage is the percent of the pods that are updated
to the latest release. The squares with dots represent canary deployment pods.

## Deploy Board requirements

In order to gather the deployment status you need to label your deployments,
replica sets, and pods with the `app` key and use the `CI_ENVIRONMENT_SLUG` as
a value. Each project will need to have a unique namespace in Kubernetes as well.

![Deploy Boards Kubernetes Label](img/deploy_boards_kubernetes_label.png)

The complete requirements for Deploy Boards to display for a specific [environment] are:

1. You should have a Kubernetes cluster up and running.
1. GitLab Runner should be configured with the [Docker][docker-exec] or
   [Kubernetes][kube-exec] executor.
1. Configure the [Kubernetes service][kube-service] in your project for the
   cluster. The Kubernetes namespace is of particular note as you will need it
   for your deployment scripts (exposed by the `KUBE_NAMESPACE` env variable).
1. Ensure a Kubernetes label of `app: $CI_ENVIRONMENT_SLUG` is applied to the
   deployments, replica sets, and pods, where `$CI_ENVIRONMENT_SLUG` the value
   of the CI variable. This is so we can lookup the proper environment in a
   cluster/namespace which may have more than one. These resources should be
   contained in the namespace defined in the Kubernetes service setting.
   You can use an [Autodeploy] `.gitlab-ci.yml` template which has predefined
   stages and commands to use, and automatically applies the labeling. GitLab
   also has a [Kubernetes deployment example](#using-the-kubernetes-deploy-example-project)
   which can simplify the build and deployment process.
1. To track canary deployments you need to label your deployments and pods
   with `track: canary`. This allows GitLab to discover whether deployment
   is stable or canary (temporary). Read more in the [Canary deployments](#canary-deployments)
   section.

Once all of the above are set up and the pipeline has run at least once,
navigate to the environments page under **Pipelines ➔ Environments**.

Deploy Boards is visible by default. You can explicitly click
the triangle next to their respective environment name in order to hide them.
GitLab will then query Kubernetes for the state of each node (e.g., waiting,
deploying, finished, unknown), and the Deploy Board status will finally appear.

GitLab will only display a Deploy Board for top-level environments. Foldered
environments like `review/*` (usually used for [Review Apps]) won't have a
Deploy Board attached to them.

## Using the Kubernetes deploy example project

The [kubernetes-deploy][kube-deploy] project is used to simplify the deployment
process to Kubernetes by providing intelligent `build`, `deploy` and `destroy`
commands which you can use in your `.gitlab-ci.yml` as-is. It uses Heroku'ish
build packs to do some of the work, plus some of GitLab's own tools to package
it all up. For your convenience, a [Docker image][kube-image] is also provided.

---

Another simple example would be the deployment of Nginx on Kubernetes.
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

Notice that we use a couple of environment Kubernetes variables to configure
the Kubernetes cluster. These are exposed from the
[Kubernetes service](integrations/kubernetes.md#deployment-variables).
The most important one is the `$KUBE_NAMESPACE` which should be unique for
every project.

Next, we replace `__CI_ENVIRONMENT_SLUG__` with the content of the
`CI_ENVIRONMENT_SLUG` variable, so that the `app` label has the correct value.

Finally, the Nginx pod is created from the definition of the
`nginx-deployment.yaml` file.

## Canary deployments

When embracing [Continuous Delivery](https://en.wikipedia.org/wiki/Continuous_delivery),
a company needs to decide what type of deployment strategy to use. One of the
most popular strategies is canary deployments, where a small portion of the fleet
is updated to the new version first. This subset, the canaries, then serve as
the proverbial [canary in the coal mine](https://en.wiktionary.org/wiki/canary_in_a_coal_mine).
If there is a problem with the new version of the application, only a small
percentage of users are affected and the change can either be fixed or quickly
reverted.

---

To start using canary deployments, in addition to the
[requirements of Deploy Boards](#deploy-boards-requirements), you also need
to label your deployments and pods with `track: canary`. This allows GitLab to
discover whether deployment is stable or canary (temporary).

Expanding on the [Kubernetes deploy example above](#using-the-kubernetes-deploy-example-project),
you can also use it to expose canary deployments. Canary deployments should
include `track: canary` and have a different deployment name than normal
deployments.

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: __CI_ENVIRONMENT_SLUG__-canary
  labels:
    app: __CI_ENVIRONMENT_SLUG__
    track: canary
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: __CI_ENVIRONMENT_SLUG__
        track: canary
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

The `.gitlab-ci.yml` would be:

```yaml
image: registry.gitlab.com/gitlab-examples/kubernetes-deploy

stages:
  - canary

kubernetes canary deploy:
  stage: canary
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
    - kubectl create -f nginx-deployment-canary.yaml || kubectl replace -f nginx-deployment-canary.yaml
```

## Further reading

- [GitLab CI environment variables][variables]
- [Environments and deployments][environment]
- [Kubernetes project service][kube-service]
- [Kubernetes deploy example][kube-deploy]
- [GitLab Autodeploy][autodeploy]

[ce-1589]: https://gitlab.com/gitlab-org/gitlab-ee/issues/1589 "Deploy Boards intial issue"
[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[kube-deploy]: https://gitlab.com/gitlab-examples/kubernetes-deploy "Kubernetes deploy example project"
[kubernetes]: https://kubernetes.io "Kubernetes website"
[environment]: ../../ci/environments.md "Environments and deployments documentation"
[docker-exec]: https://docs.gitlab.com/runner/executors/docker.html "GitLab Runner Docker executor"
[kube-exec]: https://docs.gitlab.com/runner/executors/kubernetes.html "GitLab Runner Kubernetes executor"
[kube-service]: integrations/kubernetes.md "Kubernetes project service"
[review apps]: ../../ci/review_apps/index.md "Review Apps documentation"
[variables]: ../../ci/variables/README.md "GitLab CI variables"
[autodeploy]: ../../ci/autodeploy/index.md "GitLab Autodeploy"
[kube-image]: https://gitlab.com/gitlab-examples/kubernetes-deploy/container_registry "Kubernetes deploy Container Registry"
