---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Ressources Kubernetes gérées par GitLab
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/16130) dans GitLab 17.9 [avec le feature flag](../../../administration/feature_flags/_index.md) `gitlab_managed_cluster_resources`. Fonctionnalité désactivée par défaut.
- Feature flag `gitlab_managed_cluster_resources` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/520042) dans GitLab 18.1.

{{< /history >}}

Utilisez les ressources Kubernetes gérées par GitLab pour provisionner des ressources Kubernetes avec des modèles d'environnement. Un modèle d'environnement peut :

- Créer automatiquement des espaces de nommage et des comptes de service pour les nouveaux environnements
- Gérer les autorisations d'accès via des liaisons de rôles
- Configurer d'autres ressources Kubernetes requises

Lorsque les équipes de développement déploient des applications, GitLab crée les ressources en fonction du modèle d'environnement.

## Configurer les ressources Kubernetes gérées par GitLab {#configure-gitlab-managed-kubernetes-resources}

Prérequis :

- Vous devez disposer d'un [agent GitLab pour Kubernetes](install/_index.md) configuré.
- Vous avez [autorisé l'agent](ci_cd_workflow.md#authorize-agent-access) à accéder aux projets ou groupes concernés.
- (Facultatif) Vous avez configuré [l'emprunt d'identité de l'agent](ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation) pour éviter les élévations de privilèges. Le modèle d'environnement par défaut suppose que vous avez configuré l'emprunt d'identité [`ci_job`](ci_cd_workflow.md#impersonate-the-cicd-job-that-accesses-the-cluster).

### Activer la gestion des ressources Kubernetes {#turn-on-kubernetes-resource-management}

#### Dans votre fichier de configuration de l'agent {#in-your-agent-configuration-file}

Pour activer la gestion des ressources, modifiez le fichier de configuration de l'agent afin d'inclure les autorisations requises :

```yaml
ci_access:
  projects:
    - id: <your_group/your_project>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
  groups:
    - id: <your_other_group>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
```

#### Dans vos jobs CI/CD {#in-your-cicd-jobs}

Pour que l'agent gère les ressources d'un environnement, spécifiez l'agent dans votre job de déploiement. Par exemple :

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

Les variables CI/CD peuvent être utilisées dans le chemin de l'agent. Pour plus d'informations, consultez [Où les variables peuvent être utilisées](../../../ci/variables/where_variables_can_be_used.md).

### Créer des modèles d'environnement {#create-environment-templates}

Les modèles d'environnement définissent les ressources Kubernetes à créer, mettre à jour ou supprimer.

Le [modèle d'environnement par défaut](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml) crée un `Namespace` et configure un `RoleBinding` pour le job CI/CD.

Pour remplacer le modèle par défaut, ajoutez un fichier de configuration de modèle nommé `default.yaml` dans le répertoire de l'agent :

```plaintext
.gitlab/agents/<agent-name>/environment_templates/default.yaml
```

#### Ressources Kubernetes prises en charge {#supported-kubernetes-resources}

Les ressources Kubernetes (`kind`) suivantes sont prises en charge :

- `Namespace`
- `ServiceAccount`
- `RoleBinding`
- Objets FluxCD Source Controller :
  - `GitRepository`
  - `HelmRepository`
  - `HelmChart`
  - `Bucket`
  - `OCIRepository`
- Objets FluxCD Kustomize Controller :
  - `Kustomization`
- Objets FluxCD Helm Controller :
  - `HelmRelease`
- Objets FluxCD Notification Controller :
  - `Alert`
  - `Provider`
  - `Receiver`

#### Exemple de modèle d'environnement {#example-environment-template}

L'exemple suivant crée un espace de nommage et accorde à un administrateur de groupe l'accès à un cluster.

```yaml
objects:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: bind-{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}
      namespace: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
    subjects:
      - kind: Group
        apiGroup: rbac.authorization.k8s.io
        name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: admin

# Resource lifecycle configuration
apply_resources: on_start    # Resources are applied when environment is started/restarted
delete_resources: on_stop    # Resources are removed when environment is stopped
```

### Variables de modèle {#template-variables}

Les modèles d'environnement prennent en charge une substitution de variables limitée. Les variables suivantes sont disponibles :

| Catégorie       | Variable                      | Description               | Type    | Valeur par défaut si non définie |
|----------------|-------------------------------|---------------------------|---------|----------------------------|
| Agent          | `{{ .agent.id }}`             | L'ID de l'agent.             | Entier | N/A                       |
| Agent          | `{{ .agent.name }}`           | Le nom de l'agent.           | Chaîne  | N/A                       |
| Agent          | `{{ .agent.url }}`            | L'URL de l'agent.            | Chaîne  | N/A                       |
| Environnement    | `{{ .environment.id }}`       | L'ID de l'environnement.       | Entier | N/A                       |
| Environnement    | `{{ .environment.name }}`     | Le nom de l'environnement.     | Chaîne  | N/A                       |
| Environnement    | `{{ .environment.slug }}`     | Le slug de l'environnement basé sur le nom de l'environnement. Maximum 24 caractères alphanumériques en minuscules, incluant `-`, commençant par une lettre et ne se terminant pas par `-`. | Chaîne  | N/A                       |
| Environnement    | `{{ .environment.url }}`      | L'URL de l'environnement.      | Chaîne  | Chaîne vide               |
| Environnement    | `{{ .environment.page_url }}` | L'URL de la page de l'environnement. | Chaîne  | N/A                       |
| Environnement    | `{{ .environment.tier }}`     | L'édition de l'environnement.     | Chaîne  | N/A                       |
| Projet        | `{{ .project.id }}`           | L'ID du projet.           | Entier | N/A                       |
| Projet        | `{{ .project.slug }}`         | Le slug du projet. Il s'agit du dernier composant non modifié du chemin du projet.        | Chaîne  | N/A                       |
| Projet        | `{{ .project.path }}`         | Le chemin du projet.         | Chaîne  | N/A                       |
| Projet        | `{{ .project.url }}`          | L'URL du projet.          | Chaîne  | N/A                       |
| Pipeline CI/CD | `{{ .ci_pipeline.id }}`       | L'ID du pipeline.          | Entier | Zéro                       |
| Job CI/CD      | `{{ .ci_job.id }}`            | L'ID du job CI/CD.         | Entier | Zéro                       |
| Utilisateur           | `{{ .user.id }}`              | L'ID de l'utilisateur.              | Entier | N/A                       |
| Utilisateur           | `{{ .user.username }}`        | Le nom d'utilisateur.             | Chaîne  | N/A                       |
| Espace de nommage      | `{{ .legacy_namespace }}`     | L'espace de nommage Kubernetes que l'intégration de cluster basée sur les certificats (désormais obsolète) aurait produit pour cet environnement. Cet espace de nommage est uniquement destiné à la migration de l'intégration de cluster basée sur les certificats vers les ressources gérées par GitLab. Ne l'utilisez à aucune autre fin. | Chaîne | N/A |

Toutes les variables doivent être référencées à l'aide de la syntaxe à double accolades, par exemple : `{{ .project.id }}`. Consultez la documentation [`text/template`](https://pkg.go.dev/text/template) pour plus d'informations sur le système de modélisation utilisé.

### Fonctions de modèle {#template-functions}

Les modèles d'environnement prennent en charge des fonctions limitées pour manipuler les valeurs des variables. Les fonctions suivantes sont disponibles :

| Nom         | Arguments                | Description                                          | Exemple                                    |
|--------------|--------------------------|------------------------------------------------------|--------------------------------------------|
| `lower`      | `<string>`               | Convertir en minuscules.                               | `lower "HELLO"` -> `"hello"`               |
| `substr`     | `<start> <end> <string>` | Extraire une sous-chaîne d'une chaîne.                      | `substr 0 5 "hello world"` -> `"hello"`    |
| `replace`    | `<old> <new> <string>`   | Remplacer toutes les occurrences d'une sous-chaîne dans la chaîne. | `replace "_" "-" "foo_bar"` -> `"foo-bar"` |
| `trimPrefix` | `<prefix> <string>`      | Supprimer le préfixe de la chaîne.                   | `trimPrefix "-" "-hello"` -> `"hello"`     |
| `trimSuffix` | `<suffix> <string>`      | Supprimer le suffixe de la chaîne.                   | `trimSuffix "-" "hello-"` -> `"hello"`   |
| `slugify`    | `[<len>] <string>`       | Convertir la chaîne donnée en slug selon la RFC1123. Par défaut, tronque à `63` caractères. | `slugify "hello WORLD"` -> `"hello-world"`   |

Pour rendre les variables conformes aux valeurs Kubernetes, le nombre de fonctions est intentionnellement limité à un ensemble minimal, comme les noms d'espaces de nommage ou les labels.

### Gestion du cycle de vie des ressources {#resource-lifecycle-management}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/507486) dans GitLab 18.0.

{{< /history >}}

Utilisez les paramètres suivants pour configurer le moment auquel les ressources Kubernetes doivent être supprimées :

```yaml
# Never delete resources
delete_resources: never

# Delete resources when environment is stopped
delete_resources: on_stop
```

La valeur par défaut est `on_stop`, telle que spécifiée dans le [modèle d'environnement par défaut](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml).

### Labels et annotations des ressources gérées {#managed-resource-labels-and-annotations}

Les ressources créées par GitLab utilisent une série de labels et d'annotations à des fins de suivi et de résolution des problèmes.

Les labels suivants sont définis sur chaque ressource créée par GitLab. Les valeurs sont intentionnellement laissées vides :

- `agent.gitlab.com/id-<agent_id>: ""`
- `agent.gitlab.com/project_id-<project_id>: ""`
- `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>: ""`
- `agent.gitlab.com/environment_slug-<gitlab_environment_slug>: ""`

Sur chaque ressource créée par GitLab, une annotation `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>` est définie. La valeur de l'annotation est un objet JSON avec les clés suivantes :

| Clé | Description                                      |
|-----|--------------------------------------------------|
| `environment_id` | L'ID d'environnement GitLab.                       |
| `environment_name` | Le nom d'environnement GitLab.                     |
| `environment_slug` | Le slug d'environnement GitLab.                     |
| `environment_url` | Le lien vers l'environnement. Facultatif.           |
| `environment_page_url` | Le lien vers la page d'environnement GitLab.         |
| `environment_tier` | L'édition de déploiement de l'environnement GitLab.          |
| `agent_id` | L'ID de l'agent.                                    |
| `agent_name` | Le nom de l'agent.                                  |
| `agent_url` | L'URL de l'agent dans le projet d'enregistrement de l'agent. |
| `project_id` | L'ID du projet GitLab.                           |
| `project_slug` | Le slug du projet GitLab.                         |
| `project_path` | Le chemin complet du projet GitLab.                    |
| `project_url` | Le lien vers le projet GitLab.                  |
| `template_name` | Le nom du modèle utilisé.                   |

### Désactiver les ressources Kubernetes gérées par GitLab {#disable-gitlab-managed-kubernetes-resources}

Vous pouvez désactiver les ressources Kubernetes gérées par GitLab pour des environnements spécifiques tout en continuant à utiliser d'autres fonctionnalités Kubernetes comme le tableau de bord. La désactivation des ressources gérées est utile lorsque vous travaillez avec des agents globaux pour lesquels les ressources gérées sont activées par défaut, mais que vous devez exclure des projets ou des environnements spécifiques.

Pour désactiver les ressources gérées pour un environnement, ajoutez la configuration `managed_resources.enabled: false` :

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
```

## Dépannage {#troubleshooting}

Toutes les erreurs liées aux ressources Kubernetes gérées se trouvent sur :

- La page d'environnement dans votre projet GitLab
- Les job logs CI/CD lors de l'utilisation de la fonctionnalité dans les pipelines
