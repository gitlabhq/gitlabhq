---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started deploying to Kubernetes

This page introduces you to deploying to Kubernetes using methods supported by GitLab.
In the end, you will understand:

- How to deploy with Flux
- How to deploy or run commands against your cluster from GitLab CI/CD pipelines
- How to combine Flux and GitLab CI/CD for the best outcome

## Before you begin

This tutorial builds on the project you created in [Get started connecting a Kubernetes cluster to GitLab](getting_started.md). You'll use the same project you created in that tutorial. However, you can use any project with a connected Kubernetes cluster and a bootstrapped Flux installation.

## Run commands against your cluster from GitLab CI/CD

The agent for Kubernetes [integrates with GitLab CI/CD pipelines](ci_cd_workflow.md). You can use CI/CD to run commands like `kubectl apply` and `helm upgrade` against your cluster in a secure and scalable way.

In this section, you'll use the GitLab pipeline integration to create a secret in the cluster and use it to access the GitLab container registry. The rest of this tutorial will use the deployed secret.

1. [Create a deploy token](../../project/deploy_tokens/_index.md#create-a-deploy-token) with the `read_registry` scope.
1. Save your deploy token and username as CI/CD variables called `CONTAINER_REGISTRY_ACCESS_TOKEN` and `CONTAINER_REGISTRY_ACCESS_USERNAME`.
   - For both variables, set the environment to `container-registry-secret*`.
   - For `CONTAINER_REGISTRY_ACCESS_TOKEN`:
      - [Mask the variable](../../../ci/variables/_index.md#mask-a-cicd-variable).
      - [Protect the variable](../../../ci/variables/_index.md#protect-a-cicd-variable).
1. Add the following snippet to your `.gitlab-ci.yml` file, and update both `AGENT_KUBECONTEXT` variables to match your project's path:

   ```yaml
   stages:
   - setup
   - deploy
   - stop

   create-registry-secret:
     stage: setup
     image: "portainer/kubectl-shell:latest"
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # We need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret gitlab-registry-auth -n flux-system --ignore-not-found
       - kubectl create secret docker-registry gitlab-registry-auth -n flux-system
         --docker-password="${CONTAINER_REGISTRY_ACCESS_TOKEN}" --docker-username="${CONTAINER_REGISTRY_ACCESS_USERNAME}" --docker-server="${CI_REGISTRY}"
     environment:
       name: container-registry-secret
       on_stop: delete-registry-secret

   delete-registry-secret:
     stage: stop
     image: ""
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # We need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret -n flux-system gitlab-registry-auth
     environment:
       name: container-registry-secret
       action: stop
     when: manual
   ```

Before you continue, consider how you might run other commands with CI/CD.

## Build a simple manifest into an OCI image and deploy it to the cluster

For production use cases, it is a best practice to use an OCI repository as a caching layer between the Git repository and FluxCD.
FluxCD checks for new images in the OCI repository, while GitLab pipeline builds the Flux-compliant OCI images.
To learn more about enterprise best practices, see [enterprise considerations](enterprise_considerations.md).

In this section, you'll build a simple Kubernetes manifest as an OCI artifact, then deploy it to your cluster.

1. Add the following YAML to `clusters/testing/nginx.yaml`. This lets Flux know to retrieve the specified OCI image and deploy its content.

   ```yaml
   apiVersion: source.toolkit.fluxcd.io/v1beta2
   kind: OCIRepository
   metadata:
      name: nginx-example
      namespace: flux-system
   spec:
      interval: 1m
      url: oci://registry.gitlab.example.org/my-group/optional-subgroup/my-repository/nginx-example
      ref:
         tag: latest
      secretRef:
         name: gitlab-registry-auth
   ---
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
      name: nginx-example
      namespace: flux-system
   spec:
      interval: 1m
      targetNamespace: default
      path: "."
      sourceRef:
         kind: OCIRepository
         name: nginx-example
      prune: true
   ```

    You can find the container registry URL for your GitLab instance on the left sidebar, under **Deploy > Container registry**.

1. We'll deploy NGINX as an example. Add the following YAML to `clusters/applications/nginx/nginx.yaml`:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
       name: nginx-example
       namespace: default
   spec:
       replicas: 1
       selector:
           matchLabels:
               app: nginx-example
       template:
           metadata:
               labels:
               app: nginx-example
           spec:
               containers:
                   - name: nginx
                   image: nginx:1.25
                   ports:
                       - containerPort: 80
                       protocol: TCP
   ---
   apiVersion: v1
   kind: Service
   metadata:
       name: nginx-example
       namespace: default
   spec:
       ports:
       - port: 80
       targetPort: 80
       protocol: TCP
       selector:
           app: nginx-example
   ```

1. Now, let's package the previous YAML into an OCI image.
   Extend your `.gitlab-ci.yml` file with the following snippet, and again update the `AGENT_KUBECONTEXT` variable:

   ```yaml
    nginx-deployment:
        stage: deploy
        variables:
            IMAGE_NAME: nginx-example   # Image name to push
            IMAGE_TAG: latest
            MANIFEST_PATH: "./clusters/applications/nginx"
            IMAGE_TITLE: NGINX example   # Image title to use in OCI annotation
            AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
            FLUX_OCI_REPO_NAME: nginx-example  # Flux OCIRepository to reconcile
            NAMESPACE: flux-system  # Namespace for the OCIRepository resource
        # This section configures a GitLab environment for the nginx deployment specifically
        environment:
            name: applications/nginx
            kubernetes:
                agent: $AGENT_KUBECONTEXT
                namespace: default
                flux_resource_path: kustomize.toolkit.fluxcd.io/v1/namespaces/flux-system/kustomizations/nginx-example  # We will deploy this resource in the next step
        image:
            name: "fluxcd/flux-cli:v2.4.0"
            entrypoint: [""]
        before_script:
            - kubectl config use-context $AGENT_KUBECONTEXT
        script:
            # This line builds and pushes the OCI container to the GitLab container registry.
            # You can read more about this command in https://fluxcd.io/flux/cmd/flux_push_artifact/
            - flux push artifact oci://${CI_REGISTRY_IMAGE}/${IMAGE_NAME}:${IMAGE_TAG}
                --source="${CI_REPOSITORY_URL}"
                --path="${MANIFEST_PATH}"
                --revision="${CI_COMMIT_SHORT_SHA}"
                --creds="${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}"
                --annotations="org.opencontainers.image.url=${CI_PROJECT_URL}"
                --annotations="org.opencontainers.image.title=${IMAGE_TITLE}"
                --annotations="com.gitlab.job.id=${CI_JOB_ID}"
                --annotations="com.gitlab.job.url=${CI_JOB_URL}"
            # This line triggers an immediate reconciliation of the resource. Otherwise Flux would reconcile following its configured reconciliation period.
            # You can read more about the various reconcile commands in https://fluxcd.io/flux/cmd/flux_reconcile/
            - flux reconcile source oci -n ${NAMESPACE} ${FLUX_OCI_REPO_NAME}
   ```

1. On the left sidebar, select **Operate > Environments** and check the available [dashboard for Kubernetes](../../../ci/environments/kubernetes_dashboard.md).
   The `applications/nginx` environment should be healthy.

## Secure the GitLab pipeline access

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The previously deployed agent is configured using the `.gitlab/agents/testing/config.yaml` file.
By default, the configuration enables access to the clusters configured in the project where the GitLab pipelines run.
By default, this access uses the deployed agent's service account to run commands against the cluster.
This access can be restricted either to a static service account identity or by using the CI/CD job as an identity in the cluster.
Finally, regular Kubernetes RBAC can be used to limit the access of the CI/CD jobs in the cluster.

In this section, we'll restrict CI/CD access by adding an identity to every CI/CD job, and impersonating the job in the cluster.

1. To configure the CI/CD job impersonation, edit the `.gitlab/agents/testing/config.yaml` file, and add the following snippet to it (replacing `path/to/project`):

   ```yaml
   ci_access:
      projects:
         - id: my-group/optional-subgroup/my-repository
           access_as:
              ci_job: {}
   ```

1. As the CI/CD jobs don't have any cluster bindings yet, we can not run any Kubernetes commands from GitLab CI/CD.
   Let's enable CI/CD jobs to create `Secret` objects in the `flux-system` namespace.
   Create the `clusters/testing/gitlab-ci-job-secret-write.yaml` file with the following content:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
      name: secret-manager
      namespace: default
   rules:
      - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["create", "delete"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
      name: gitlab-ci-secrets-binding
      namespace: default
   subjects:
      - kind: Group
        name: gitlab:ci_job
        apiGroup: rbac.authorization.k8s.io
   roleRef:
      kind: Role
      name: secret-manager
      apiGroup: rbac.authorization.k8s.io
   ```

1. Let's enable CI/CD jobs to trigger a FluxCD reconciliation too.
   Create the `clusters/testing/gitlab-ci-job-flux-reconciler.yaml` file with the following content:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-admin
   roleRef:
       name: flux-edit-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-view
   roleRef:
       name: flux-view-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ```

For more information about CI/CD access, see [Using GitLab CI/CD with a Kubernetes cluster](ci_cd_workflow.md).

## Clean up resources

To finish, let's remove the deployed resources and delete the secret we used to access the container registry:

1. Delete the `clusters/testing/nginx.yaml` file.
   Flux will take care of removing the related resources from the cluster.
1. Stop the `container-registry-secret`  environment.
   Stopping the environment will trigger its `on_stop` job, removing the secret from the cluster.

## Next steps

You can use the techniques in this tutorial to scale deployments across projects. The OCI image can be built in a different project, and as long as Flux is pointed at the right registry, Flux will retrieve it. This exercise is left for the reader.

For more practice, try changing the original Flux `GitRepository` in `/clusters/testing/flux-system/gotk-sync.yaml` to an `OCIRepository`.

Finally, see the following resources for more information about Flux and the GitLab integration with Kubernetes:

- [Enterprise considerations](enterprise_considerations.md) for the Kubernetes integration
- Use the agent for [operational container scanning](vulnerabilities.md)
- Use the agent to provide [remote workspaces](../../workspace/_index.md) for your engineers
