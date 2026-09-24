---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de GitLab CI/CD avec un cluster Kubernetes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La limite de partage de connexions d'agent [a été modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844) de 100 à 500 dans GitLab 17.0.

{{< /history >}}

Vous pouvez utiliser GitLab CI/CD pour connecter, déployer et mettre à jour vos clusters Kubernetes en toute sécurité.

Pour ce faire, [installez un agent dans votre cluster](install/_index.md). Une fois cela fait, vous disposez d'un contexte Kubernetes et pouvez exécuter des commandes API Kubernetes dans votre pipeline CI/CD GitLab.

Pour garantir la sécurité de l'accès à votre cluster :

- Chaque agent possède un contexte distinct (`kubecontext`).
- Seul le projet dans lequel l'agent est configuré, ainsi que tout projet supplémentaire que vous autorisez, peut accéder à l'agent dans votre cluster.

Pour utiliser GitLab CI/CD afin d'interagir avec votre cluster, les runners doivent être enregistrés auprès de GitLab. Cependant, ces runners n'ont pas à se trouver dans le cluster où se trouve l'agent.

Prérequis :

- Assurez-vous que [GitLab CI/CD est activé](../../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines).

## Utiliser GitLab CI/CD avec votre cluster {#use-gitlab-cicd-with-your-cluster}

Pour mettre à jour un cluster Kubernetes avec GitLab CI/CD :

1. Assurez-vous de disposer d'un cluster Kubernetes fonctionnel et que les manifestes se trouvent dans un projet GitLab.
1. Dans le même projet GitLab, [enregistrez et installez l'agent GitLab pour Kubernetes](install/_index.md).
1. [Mettez à jour votre fichier `.gitlab-ci.yml`](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) pour sélectionner le contexte Kubernetes de l'agent et exécuter les commandes API Kubernetes.
1. Exécutez votre pipeline pour effectuer un déploiement vers le cluster ou le mettre à jour.

Si vous avez plusieurs projets GitLab contenant des manifestes Kubernetes :

1. [Installez l'agent GitLab pour Kubernetes](install/_index.md) dans son propre projet, ou dans l'un des projets GitLab où vous conservez vos manifestes Kubernetes.
1. [Autorisez l'accès à l'agent](#authorize-agent-access) dans vos projets GitLab.
1. Facultatif. Pour plus de sécurité, [utilisez l'usurpation d'identité](#restrict-project-and-group-access-by-using-impersonation).
1. [Mettez à jour votre fichier `.gitlab-ci.yml`](#update-your-gitlab-ciyml-file-to-run-kubectl-commands) pour sélectionner le contexte Kubernetes de l'agent et exécuter les commandes API Kubernetes.
1. Exécutez votre pipeline pour effectuer un déploiement vers le cluster ou le mettre à jour.

## Autoriser l'accès à l'agent {#authorize-agent-access}

Si vous avez plusieurs projets contenant des manifestes Kubernetes, vous devez autoriser ces projets à accéder à l'agent. Vous pouvez autoriser l'accès à l'agent pour des projets individuels, des groupes ou des sous-groupes afin que tous les projets y aient accès. Pour plus de sécurité, vous pouvez également [utiliser l'usurpation d'identité](#restrict-project-and-group-access-by-using-impersonation).

La propagation de la configuration des autorisations peut prendre une à deux minutes.

### Autoriser vos projets à accéder à l'agent {#authorize-your-projects-to-access-the-agent}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/377932) pour permettre l'autorisation de groupes appartenant à différents groupes principaux dans GitLab 18.1.

{{< /history >}}

Pour autoriser le projet GitLab dans lequel vous conservez vos manifestes Kubernetes à accéder à l'agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient le [fichier de configuration de l'agent](install/_index.md#create-an-agent-configuration-file) (`config.yaml`).
1. Modifiez le fichier `config.yaml`. Sous le mot-clé `ci_access`, ajoutez l'attribut `projects`.
1. Pour le champ `id`, ajoutez le chemin d'accès au projet.

   ```yaml
   ci_access:
     projects:
       - id: path/to/project
   ```

   - Les projets autorisés doivent avoir le même groupe principal ou espace de nommage d'utilisateur que le projet de configuration de l'agent, sauf si le paramètre d'application [d'autorisation au niveau de l'instance](#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) est activé.
   - Vous pouvez installer des agents supplémentaires dans le même cluster pour prendre en charge des hiérarchies supplémentaires.
   - Vous pouvez autoriser jusqu'à 500 projets.

Après avoir effectué ces modifications :

- Tous les jobs CI/CD incluent désormais un fichier `kubeconfig` avec des contextes pour chaque connexion d'agent partagée.
- Le chemin d'accès `kubeconfig` est disponible dans la variable d'environnement `$KUBECONFIG`.
- Vous pouvez choisir le contexte pour exécuter des commandes `kubectl` depuis vos scripts CI/CD.

### Autoriser les projets de vos groupes à accéder à l'agent {#authorize-projects-in-your-groups-to-access-the-agent}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/377932) pour permettre l'autorisation de groupes appartenant à différents groupes principaux dans GitLab 18.1.

{{< /history >}}

Pour autoriser tous les projets GitLab d'un groupe ou sous-groupe à accéder à l'agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient le [fichier de configuration de l'agent](install/_index.md#create-an-agent-configuration-file) (`config.yaml`).
1. Modifiez le fichier `config.yaml`. Sous le mot-clé `ci_access`, ajoutez l'attribut `groups`.
1. Pour le champ `id`, ajoutez le chemin d'accès :

   ```yaml
   ci_access:
     groups:
       - id: path/to/group/subgroup
   ```

   - Les groupes autorisés doivent avoir le même groupe principal que le projet de configuration de l'agent, sauf si le paramètre d'application [d'autorisation au niveau de l'instance](#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) est activé.
   - Vous pouvez installer des agents supplémentaires dans le même cluster pour prendre en charge des hiérarchies supplémentaires.
   - Tous les sous-groupes d'un groupe autorisé ont également accès au même agent (sans avoir à les spécifier individuellement).
   - Vous pouvez autoriser jusqu'à 500 groupes.

Après avoir effectué ces modifications :

- Tous les projets appartenant au groupe et à ses sous-groupes sont désormais autorisés à accéder à l'agent.
- Tous les jobs CI/CD incluent désormais un fichier `kubeconfig` avec des contextes pour chaque connexion d'agent partagée.
- Le chemin d'accès `kubeconfig` est disponible dans la variable d'environnement `$KUBECONFIG`.
- Vous pouvez choisir le contexte pour exécuter des commandes `kubectl` depuis vos scripts CI/CD.

### Autoriser tous les projets de votre instance GitLab à accéder à l'agent {#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/357516) dans GitLab 17.11.

{{< /history >}}

Prérequis :

- Vous devez être administrateur.

Pour permettre aux agents d'être configurés afin d'autoriser tous les projets de votre instance GitLab :

{{< tabs >}}

{{< tab title="Via l'interface utilisateur" >}}

1. Dans la zone **Admin**, sélectionnez **Paramètres** > **Général**, et développez la section **Agent GitLab pour Kubernetes**.
1. Sélectionnez **Activer l'autorisation au niveau de l'instance**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Via l'API" >}}

1. [Mettez à jour le paramètre d'application](../../../api/settings.md#update-application-settings) `organization_cluster_agent_authorization_enabled` à `true`.

{{< /tab >}}

{{< /tabs >}}

Pour autoriser l'agent à accéder à tous les projets GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient le [fichier de configuration de l'agent](install/_index.md#create-an-agent-configuration-file) (`config.yaml`).
1. Modifiez le fichier `config.yaml`. Sous le mot-clé `ci_access`, ajoutez l'attribut `instance` :

   ```yaml
   ci_access:
     instance: {}
   ```

Après avoir effectué ces modifications dans le fichier de configuration de l'agent :

- Tous les jobs CI/CD de tous les projets de votre instance sont autorisés à accéder à l'agent. Vous pouvez utiliser l'usurpation d'identité des jobs CI/CD avec RBAC pour accorder ou restreindre l'accès selon vos besoins. Pour plus d'informations, consultez [Restreindre l'accès aux projets et aux groupes par usurpation d'identité](#restrict-project-and-group-access-by-using-impersonation).
- Tous les jobs CI/CD incluent un fichier `kubeconfig` avec des contextes pour chaque connexion d'agent partagée.
- Le chemin d'accès `kubeconfig` est disponible dans la variable d'environnement `$KUBECONFIG`.
- Vous pouvez choisir le contexte pour exécuter des commandes `kubectl` depuis vos scripts CI/CD.

## Mettre à jour votre fichier `.gitlab-ci.yml` pour exécuter des commandes `kubectl` {#update-your-gitlab-ciyml-file-to-run-kubectl-commands}

Dans le projet dans lequel vous souhaitez exécuter des commandes Kubernetes, modifiez le fichier `.gitlab-ci.yml` de votre projet.

Dans la première commande sous le mot-clé `script`, définissez le contexte de votre agent. Utilisez le format `<path/to/agent/project>:<agent-name>`. Par exemple :

```yaml
deploy:
  image: debian:13-slim
  variables:
    KUBECTL_VERSION: v1.34
    DEBIAN_FRONTEND: noninteractive
  script:
    # Follows https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
    - apt-get update
    - apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg
    - curl --fail --silent --show-error --location "https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/Release.key" | gpg --dearmor --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    - chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
    - chmod 644 /etc/apt/sources.list.d/kubernetes.list
    - apt-get update
    - apt-get install -y --no-install-recommends kubectl
    - kubectl config get-contexts
    - kubectl config use-context path/to/agent/project:agent-name
    - kubectl get pods
```

Si vous n'êtes pas sûr du contexte de votre agent, exécutez `kubectl config get-contexts` depuis un job CI/CD où vous souhaitez accéder à l'agent.

### Environnements utilisant Auto DevOps {#environments-that-use-auto-devops}

Si Auto DevOps est activé, vous devez définir la variable CI/CD `KUBE_CONTEXT`. Définissez la valeur de `KUBE_CONTEXT` sur le contexte de l'agent que vous souhaitez qu'Auto DevOps utilise :

```yaml
deploy:
  variables:
    KUBE_CONTEXT: path/to/agent/project:agent-name
```

Vous pouvez attribuer différents agents à des jobs Auto DevOps distincts. Par exemple, Auto DevOps peut utiliser un agent pour les jobs `staging` et un autre agent pour les jobs `production`. Pour utiliser plusieurs agents, définissez une [variable CI/CD à portée d'environnement](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) pour chaque agent. Par exemple :

1. Définissez deux variables nommées `KUBE_CONTEXT`.
1. Pour la première variable :
   1. Définir `environment` sur `staging`.
   1. Définissez la valeur sur le contexte de votre agent de staging.
1. Pour la deuxième variable :
   1. Définir `environment` sur `production`.
   1. Définissez la valeur sur le contexte de votre agent de production.

### Environnements avec des connexions à la fois basées sur des certificats et basées sur des agents {#environments-with-both-certificate-based-and-agent-based-connections}

Lorsque vous effectuez un déploiement vers un environnement disposant à la fois d'un [cluster basé sur des certificats](../../infrastructure/clusters/_index.md) (obsolète) et d'une connexion d'agent :

- Le contexte du cluster basé sur des certificats est appelé `gitlab-deploy`. Ce contexte est toujours sélectionné par défaut.
- Les contextes d'agent sont inclus dans `$KUBECONFIG`. Vous pouvez les sélectionner en utilisant `kubectl config use-context <path/to/agent/project>:<agent-name>`.

Pour utiliser une connexion d'agent lorsque des connexions basées sur des certificats sont présentes, vous pouvez configurer manuellement un nouveau contexte de configuration `kubectl`. Par exemple :

```yaml
deploy:
  variables:
    KUBE_CONTEXT: my-context # The name to use for the new context
    AGENT_ID: 1234 # replace with your agent's numeric ID
    K8S_PROXY_URL: https://<KAS_DOMAIN>/k8s-proxy/ # For agent server (KAS) deployed in Kubernetes cluster (for gitlab.com use kas.gitlab.com); replace with your URL
    # K8S_PROXY_URL: https://<GITLAB_DOMAIN>/-/kubernetes-agent/k8s-proxy/ # For agent server (KAS) in Omnibus
    # Include any additional variables
  before_script:
    - kubectl config set-credentials agent:$AGENT_ID --token="ci:${AGENT_ID}:${CI_JOB_TOKEN}"
    - kubectl config set-cluster gitlab --server="${K8S_PROXY_URL}"
    - kubectl config set-context "$KUBE_CONTEXT" --cluster=gitlab --user="agent:${AGENT_ID}"
    - kubectl config use-context "$KUBE_CONTEXT"
  # Include the remaining job configuration
```

### Environnements avec KAS utilisant des certificats auto-signés {#environments-with-kas-that-use-self-signed-certificates}

Si vous utilisez un environnement avec KAS et un certificat auto-signé, vous devez configurer votre client Kubernetes pour qu'il approuve l'autorité de certification (CA) qui a signé votre certificat.

Pour configurer votre client, effectuez l'une des opérations suivantes :

- Définissez une variable CI/CD `SSL_CERT_FILE` avec le certificat KAS au format PEM.
- Configurez le client Kubernetes avec `--certificate-authority=$KAS_CERTIFICATE`, où `KAS_CERTIFICATE` est une variable CI/CD contenant le certificat CA de KAS.
- Placez les certificats dans un emplacement approprié dans le conteneur du job en mettant à jour l'image du conteneur ou en effectuant un montage via le runner.
- Non recommandé. Configurez le client Kubernetes avec `--insecure-skip-tls-verify=true`.

## Restreindre l'accès aux projets et aux groupes par usurpation d'identité {#restrict-project-and-group-access-by-using-impersonation}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, votre job CI/CD hérite de toutes les autorisations du compte de service utilisé pour installer l'agent dans le cluster. Pour restreindre l'accès à votre cluster, vous pouvez utiliser [l'usurpation d'identité](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

Pour spécifier des usurpations d'identité, utilisez l'attribut `access_as` dans votre fichier de configuration d'agent et utilisez les règles RBAC Kubernetes pour gérer les autorisations des comptes usurpés.

Vous pouvez usurper l'identité :

- De l'agent lui-même (par défaut).
- Du job CI/CD qui accède au cluster.
- D'un utilisateur spécifique ou d'un compte système défini dans le cluster.

La propagation de la configuration des autorisations peut prendre une à deux minutes.

### Usurper l'identité de l'agent {#impersonate-the-agent}

L'identité de l'agent est usurpée par défaut. Vous n'avez rien à faire pour usurper son identité.

### Usurper l'identité du job CI/CD qui accède au cluster {#impersonate-the-cicd-job-that-accesses-the-cluster}

Pour usurper l'identité du job CI/CD qui accède au cluster, sous la clé `access_as`, ajoutez la paire clé-valeur `ci_job: {}`.

Lorsque l'agent effectue la requête vers l'API Kubernetes réelle, il définit les informations d'identification d'usurpation d'identité de la manière suivante :

- `UserName` est défini sur `gitlab:ci_job:<job id>`. Exemple : `gitlab:ci_job:1074499489`.
- `Groups` est défini sur :

  - `gitlab:ci_job` pour identifier toutes les requêtes provenant des jobs CI.
  - La liste des identifiants des groupes auxquels appartient le projet.
  - L'identifiant du projet.
  - Le slug et l'édition de l'environnement auquel appartient ce job.

    Exemple : pour un job CI dans `group1/group1-1/project1` où :

    - Le groupe `group1` a l'ID 23.
    - Le groupe `group1/group1-1` a l'ID 25.
    - Le projet `group1/group1-1/project1` a l'ID 150.
    - Job s'exécutant dans l'environnement `prod`, qui possède l'édition d'environnement `production`.

  La liste de groupes serait `[gitlab:ci_job, gitlab:group:23, gitlab:group_env_tier:23:production, gitlab:group:25, gitlab:group_env_tier:25:production, gitlab:project:150, gitlab:project_env:150:prod, gitlab:project_env_tier:150:production]`.

- `Extra` contient des informations supplémentaires sur la requête. Les propriétés suivantes sont définies sur l'identité usurpée :

| Propriété                             | Description                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| `agent.gitlab.com/id`                | Contient l'ID de l'agent.                                                       |
| `agent.gitlab.com/config_project_id` | Contient l'ID du projet de configuration de l'agent.                               |
| `agent.gitlab.com/project_id`        | Contient l'ID du projet CI.                                                  |
| `agent.gitlab.com/ci_pipeline_id`    | Contient l'ID du pipeline CI.                                                 |
| `agent.gitlab.com/ci_job_id`         | Contient l'ID du job CI.                                                      |
| `agent.gitlab.com/username`          | Contient le nom d'utilisateur de l'utilisateur sous lequel s'exécute le job CI.                  |
| `agent.gitlab.com/environment_slug`  | Contient le slug de l'environnement. Défini uniquement si le job s'exécute dans un environnement. |
| `agent.gitlab.com/environment_tier`  | Contient l'édition de l'environnement. Défini uniquement si le job s'exécute dans un environnement. |

Exemple de fichier `config.yaml` pour restreindre l'accès par l'identité du job CI/CD :

```yaml
ci_access:
  projects:
    - id: path/to/project
      access_as:
        ci_job: {}
```

#### Exemple RBAC pour restreindre les jobs CI/CD {#example-rbac-to-restrict-cicd-jobs}

La ressource `RoleBinding` suivante restreint tous les jobs CI/CD aux droits de lecture uniquement.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ci-job-view
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:ci_job
    kind: Group
```

### Usurper une identité statique {#impersonate-a-static-identity}

Pour une connexion donnée, vous pouvez utiliser une identité statique pour l'usurpation d'identité.

Sous la clé `access_as`, ajoutez la clé `impersonate` pour effectuer la requête en utilisant l'identité fournie.

L'identité peut être spécifiée avec les clés suivantes :

- `username` (obligatoire)
- `uid`
- `groups`
- `extra`

Consultez la [documentation officielle de Kubernetes pour plus de détails](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation).

## Restreindre l'accès aux projets et aux groupes à des environnements spécifiques {#restrict-project-and-group-access-to-specific-environments}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, si votre agent est [disponible pour un projet](#authorize-agent-access), tous les jobs CI/CD du projet peuvent utiliser cet agent.

Pour restreindre l'accès à l'agent aux seuls jobs avec des environnements spécifiques, ajoutez `environments` à `ci_access.projects` ou `ci_access.groups`. Par exemple :

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
      - id: path/to/project-2
        environments:
          - staging
          - review/*
    groups:
      - id: path/to/group-1
        environments:
          - production
  ```

Dans cet exemple :

- Tous les jobs CI/CD sous `project-1` peuvent accéder à l'agent.
- Les jobs CI/CD sous `project-2` avec les environnements `staging` ou `review/*` peuvent accéder à l'agent.
  - `*` est un caractère générique, donc `review/*` correspond à tous les environnements sous `review`.
- Les jobs CI/CD des projets sous `group-1` avec les environnements `production` peuvent accéder à l'agent.

## Restreindre l'accès à l'agent aux branches protégées {#restrict-access-to-the-agent-to-protected-branches}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/467936) dans GitLab 17.3 [avec le feature flag](../../../administration/feature_flags/_index.md) `kubernetes_agent_protected_branches`. Fonctionnalité désactivée par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/467936) dans GitLab 17.10. Le feature flag `kubernetes_agent_protected_branches` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Pour restreindre l'accès à l'agent aux seuls jobs exécutés sur des [branches protégées](../../project/repository/branches/protected.md) :

- Ajoutez `protected_branches_only: true` à `ci_access.projects` ou `ci_access.groups`. Par exemple :

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
        protected_branches_only: true
    groups:
      - id: path/to/group-1
        protected_branches_only: true
        environments:
          - production
  ```

Par défaut, `protected_branches_only` est défini sur `false`, et l'agent est accessible depuis les branches protégées et non protégées.

Pour une sécurité accrue, vous pouvez combiner cette fonctionnalité avec les [restrictions d'environnement](#restrict-project-and-group-access-to-specific-environments).

Si un projet possède plusieurs configurations, seule la configuration la plus spécifique est utilisée. Par exemple, la configuration suivante accorde l'accès aux branches non protégées dans `example/my-project`, même si le groupe `example` est configuré pour n'accorder l'accès qu'aux branches protégées :

```yaml
# .gitlab/agents/my-agent/config.yaml
ci_access:
  project:
    - id: example/my-project # Project of the group below
      protected_branches_only: false # This configuration supersedes the group configuration
      environments:
        - dev
  groups:
    - id: example
      protected_branches_only: true
      environments:
        - dev
```

Pour plus de détails, consultez [Accès à Kubernetes depuis CI/CD](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md#apiv4joballowed_agents-api).

## Sujets connexes {#related-topics}

- [Atelier en classe à votre rythme](https://gitlab-for-eks.awsworkshop.io) (utilise AWS EKS, mais peut être utilisé pour d'autres clusters Kubernetes)
- [Configurer Auto DevOps](../../../topics/autodevops/cloud_deployments/auto_devops_with_gke.md#configure-auto-devops)

## Dépannage {#troubleshooting}

### Accorder des autorisations d'écriture à `~/.kube/cache` {#grant-write-permissions-to-kubecache}

Des outils tels que `kubectl`, Helm, `kpt` et `kustomize` mettent en cache des informations sur le cluster dans `~/.kube/cache`. Si ce répertoire n'est pas accessible en écriture, l'outil récupère les informations à chaque invocation, ce qui ralentit les interactions et crée une charge inutile sur le cluster. Pour une expérience optimale, dans l'image que vous utilisez dans votre fichier `.gitlab-ci.yml`, assurez-vous que ce répertoire est accessible en écriture.

### Activer TLS {#enable-tls}

Si vous utilisez GitLab Self-Managed, assurez-vous que votre instance est configurée avec le protocole TLS (Transport Layer Security).

Si vous tentez d'utiliser `kubectl` sans TLS, vous pourriez obtenir une erreur de ce type :

```shell
$ kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

### Impossible de se connecter au serveur : certificat signé par une autorité inconnue {#unable-to-connect-to-the-server-certificate-signed-by-unknown-authority}

Si vous utilisez un environnement avec KAS et un certificat auto-signé, votre appel `kubectl` peut renvoyer cette erreur :

```plaintext
kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority
```

Cette erreur se produit car le job n'approuve pas l'autorité de certification (CA) qui a signé le certificat KAS.

Pour résoudre ce problème, [configurez `kubectl` pour approuver la CA](#environments-with-kas-that-use-self-signed-certificates).

### Erreurs de validation {#validation-errors}

Si vous utilisez `kubectl` versions v1.27.0 ou v1.27.1, vous pourriez obtenir l'erreur suivante :

```plaintext
error: error validating "file.yml": error validating data: the server responded with the status code 426 but did not return more information; if you choose to ignore these errors, turn validation off with --validate=false
```

Ce problème est causé par [un bug](https://github.com/kubernetes/kubernetes/issues/117463) avec `kubectl` et d'autres outils utilisant les bibliothèques Kubernetes partagées.

Pour résoudre ce problème, utilisez une autre version de `kubectl`.
