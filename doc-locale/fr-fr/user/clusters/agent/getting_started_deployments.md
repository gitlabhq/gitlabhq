---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Premiers pas avec le déploiement sur Kubernetes
---

Cette page vous présente le déploiement sur Kubernetes à l'aide des méthodes prises en charge par GitLab. À la fin, vous comprendrez :

- Comment déployer avec Flux
- Comment déployer des applications ou exécuter des commandes sur votre cluster depuis les pipelines CI/CD GitLab
- Comment combiner Flux et GitLab CI/CD pour obtenir les meilleurs résultats

## Avant de commencer {#before-you-begin}

Ce tutoriel s'appuie sur le projet que vous avez créé dans [Premiers pas avec la connexion d'un cluster Kubernetes à GitLab](getting_started.md). Vous utiliserez le même projet que celui créé dans ce tutoriel. Cependant, vous pouvez utiliser n'importe quel projet avec un cluster Kubernetes connecté et une installation Flux amorcée.

## Exécuter des commandes sur votre cluster depuis GitLab CI/CD {#run-commands-against-your-cluster-from-gitlab-cicd}

L'agent pour Kubernetes [s'intègre aux pipelines CI/CD GitLab](ci_cd_workflow.md). Vous pouvez utiliser CI/CD pour exécuter des commandes telles que `kubectl apply` et `helm upgrade` sur votre cluster de manière sécurisée et évolutive.

Dans cette section, vous utiliserez l'intégration de pipeline GitLab pour créer un secret dans le cluster et l'utiliser pour accéder au registre de conteneurs GitLab. Le reste de ce tutoriel utilisera le secret déployé.

1. [Créez un jeton de déploiement](../../project/deploy_tokens/_index.md#create-a-deploy-token) avec la portée `read_registry`.
1. Enregistrez votre jeton de déploiement et votre nom d'utilisateur en tant que variables CI/CD appelées `CONTAINER_REGISTRY_ACCESS_TOKEN` et `CONTAINER_REGISTRY_ACCESS_USERNAME`.
   - Pour les deux variables, définissez l'environnement sur `container-registry-secret*`.
   - Pour `CONTAINER_REGISTRY_ACCESS_TOKEN` :
     - [Masquez la variable](../../../ci/variables/_index.md#mask-a-cicd-variable).
     - [Protégez la variable](../../../ci/variables/_index.md#protect-a-cicd-variable).
1. Ajoutez l'extrait de code suivant à votre fichier `.gitlab-ci.yml`, et mettez à jour les deux variables `AGENT_KUBECONTEXT` pour qu'elles correspondent au chemin de votre projet :

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
       # You need to select the agent to use
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
       # You need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret -n flux-system gitlab-registry-auth
     environment:
       name: container-registry-secret
       action: stop
     when: manual
   ```

Avant de continuer, réfléchissez à la façon dont vous pourriez exécuter d'autres commandes avec CI/CD.

## Construire un manifeste simple sous forme d'image OCI et le déployer dans le cluster {#build-a-simple-manifest-into-an-oci-image-and-deploy-it-to-the-cluster}

Pour les cas d'usage en production, il est recommandé d'utiliser un dépôt OCI comme couche de mise en cache entre le dépôt Git et FluxCD. FluxCD vérifie la présence de nouvelles images dans le dépôt OCI, tandis que le pipeline GitLab construit les images OCI conformes à Flux. Pour en savoir plus sur les bonnes pratiques en entreprise, consultez [les considérations pour les entreprises](enterprise_considerations.md).

Dans cette section, vous allez construire un manifeste Kubernetes simple sous forme d'artefact OCI, puis le déployer dans votre cluster.

1. Exécutez les commandes CLI `flux` suivantes pour indiquer à Flux où récupérer l'image OCI spécifiée et déployer son contenu. Ajustez la valeur `--url` pour votre instance GitLab. Vous pouvez trouver l'URL du registre de conteneurs sous **Déployer** > **Registre de conteneurs**. Vous pouvez inspecter le fichier `clusters/testing/nginx.yaml` créé pour mieux comprendre comment Flux trouve les manifestes à déployer.

   ```shell
   flux create source oci nginx-example \
    --url oci://registry.gitlab.example.org/my-group/optional-subgroup/my-repository/nginx-example \
    --tag latest \
    --secret-ref gitlab-registry-auth \
    --interval 1m \
    --namespace flux-system \
    --export > clusters/testing/nginx.yaml
    flux create kustomization nginx-example \
    --source OCIRepository/nginx-example \
    --path "." \
    --prune true \
    --target-namespace default \
    --interval 1m \
    --namespace flux-system \
    --export >> clusters/testing/nginx.yaml
   ```

1. Déployez NGINX à titre d'exemple. Ajoutez le YAML suivant à `clusters/applications/nginx/nginx.yaml` :

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

1. Maintenant, empaquetez le YAML précédent dans une image OCI. Étendez votre fichier `.gitlab-ci.yml` avec l'extrait de code suivant, et mettez à nouveau à jour la variable `AGENT_KUBECONTEXT` :

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
                dashboard:
                  namespace: default
                  flux_resource_path: kustomize.toolkit.fluxcd.io/v1/namespaces/flux-system/kustomizations/nginx-example  # You will deploy this resource in the next step
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

1. Commitez et poussez les modifications vers votre projet, puis attendez que le pipeline de build se termine.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements** et consultez le [tableau de bord pour Kubernetes](../../../ci/environments/kubernetes_dashboard.md) disponible. L'environnement `applications/nginx` devrait être opérationnel.

## Sécuriser l'accès au pipeline GitLab {#secure-the-gitlab-pipeline-access}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'agent précédemment déployé est configuré à l'aide du fichier `.gitlab/agents/testing/config.yaml`. Par défaut, la configuration autorise l'accès aux clusters configurés dans le projet où les pipelines GitLab s'exécutent. Par défaut, cet accès utilise le compte de service de l'agent déployé pour exécuter des commandes sur le cluster. Cet accès peut être limité soit à une identité de compte de service statique, soit en utilisant le job CI/CD comme identité dans le cluster. Enfin, le RBAC Kubernetes standard peut être utilisé pour limiter l'accès des jobs CI/CD dans le cluster.

Cette section explique comment restreindre l'accès CI/CD en ajoutant une identité à chaque job CI/CD et en usurpant l'identité du job dans le cluster.

1. Pour configurer l'usurpation d'identité du job CI/CD, modifiez le fichier `.gitlab/agents/testing/config.yaml` et ajoutez-y l'extrait de code suivant (en remplaçant `path/to/project`) :

   ```yaml
   ci_access:
      projects:
         - id: my-group/optional-subgroup/my-repository
           access_as:
              ci_job: {}
   ```

1. Les jobs CI/CD n'ayant pas encore de liaisons de cluster, vous ne pouvez pas exécuter de commandes Kubernetes depuis GitLab CI/CD. Activons les jobs CI/CD pour créer des objets `Secret` dans l'espace de nommage `flux-system`. Créez le fichier `clusters/testing/gitlab-ci-job-secret-write.yaml` avec le contenu suivant :

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

1. Activons également les jobs CI/CD pour déclencher une réconciliation FluxCD. Créez le fichier `clusters/testing/gitlab-ci-job-flux-reconciler.yaml` avec le contenu suivant :

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

Pour plus d'informations sur l'accès CI/CD, consultez [Utiliser GitLab CI/CD avec un cluster Kubernetes](ci_cd_workflow.md).

## Nettoyer les ressources {#clean-up-resources}

Pour terminer, supprimez les ressources déployées et effacez le secret que vous avez utilisé pour accéder au registre de conteneurs :

1. Supprimez le fichier `clusters/testing/nginx.yaml`. Flux se chargera de supprimer les ressources associées du cluster.
1. Arrêtez l'environnement `container-registry-secret`. L'arrêt de l'environnement déclenchera son job `on_stop`, qui supprimera le secret du cluster.

## Étapes suivantes {#next-steps}

Vous pouvez utiliser les techniques de ce tutoriel pour faire évoluer les déploiements entre plusieurs projets. L'image OCI peut être construite dans un projet différent, et tant que Flux pointe vers le bon registre, Flux la récupérera. Cet exercice est laissé à l'appréciation du lecteur.

Pour vous entraîner davantage, essayez de remplacer le `GitRepository` Flux original dans `/clusters/testing/flux-system/gotk-sync.yaml` par un `OCIRepository`.

Enfin, consultez les ressources suivantes pour plus d'informations sur Flux et l'intégration GitLab avec Kubernetes :

- [Considérations pour les entreprises](enterprise_considerations.md) pour l'intégration Kubernetes
- Utiliser l'agent pour [l'analyse de conteneurs opérationnels](vulnerabilities.md)
- Utiliser l'agent pour fournir des [workspaces distants](../../workspace/_index.md) à vos ingénieurs
