---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Projet de gestion de cluster (déprécié)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Désactivé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) dans GitLab 15.0.

{{< /history >}}

> [!flag]
> Cette fonctionnalité n'est pas disponible par défaut sur GitLab Self-Managed. Pour rendre cette fonctionnalité disponible, un administrateur peut [activer le feature flag](../../administration/feature_flags/_index.md) `certificate_based_clusters`.

Un projet peut être désigné comme projet de gestion pour un cluster.

> [!warning]
> Le projet de gestion de cluster a été [déprécié](https://gitlab.com/groups/gitlab-org/configure/-/work_items/8) dans GitLab 14.5. Pour gérer les applications de cluster, utilisez l'[agent GitLab pour Kubernetes](agent/_index.md) avec le [modèle de projet de gestion de cluster](management_project_template.md).

Un projet de gestion peut être utilisé pour exécuter des jobs de déploiement avec les privilèges Kubernetes [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles).

Cela peut être utile pour :

- Créer des pipelines pour installer des applications à l'échelle du cluster dans votre cluster. Consultez le [modèle de projet de gestion](management_project_template.md) pour plus de détails.
- Tout job nécessitant des privilèges `cluster-admin`.

## Autorisations {#permissions}

Seul le projet de gestion reçoit les privilèges `cluster-admin`. Tous les autres projets continuent de recevoir [des privilèges de niveau `edit` limités à l'espace de nommage](../project/clusters/cluster_access.md#rbac-cluster-resources).

Les projets de gestion sont soumis aux restrictions suivantes :

- Pour les clusters au niveau projet, le projet de gestion doit se trouver dans le même espace de nommage (ou ses descendants) que le projet du cluster.
- Pour les clusters au niveau groupe, le projet de gestion doit se trouver dans le même groupe (ou ses descendants) que le groupe du cluster.
- Pour les clusters au niveau instance, aucune restriction de ce type n'est appliquée.

## Comment créer et configurer un projet de gestion de cluster {#how-to-create-and-configure-a-cluster-management-project}

Pour utiliser un projet de gestion de cluster afin de gérer votre cluster :

1. Créez un nouveau projet pour servir de projet de gestion de cluster pour votre cluster.
1. [Associez le cluster au projet de gestion](#associate-the-cluster-management-project-with-the-cluster).
1. [Configurez les pipelines de votre cluster](#configuring-your-pipeline).
1. [Définissez la portée de l'environnement](#setting-the-environment-scope).

### Associer le projet de gestion de cluster au cluster {#associate-the-cluster-management-project-with-the-cluster}

Prérequis :

- Accès administrateur pour associer un cluster au niveau instance.

Pour associer un projet de gestion de cluster à votre cluster :

1. Accédez à la page de configuration appropriée. Pour un :
   - [Cluster au niveau projet](../project/clusters/_index.md), accédez à la page **Opération** > **Clusters Kubernetes** de votre projet.
   - [Cluster au niveau groupe](../group/clusters/_index.md), accédez à la page **Kubernetes** de votre groupe.
   - [Cluster au niveau instance](../instance/clusters/_index.md) :
     1. Dans le coin supérieur droit, sélectionnez **Admin**.
     1. Sélectionnez **Kubernetes**.
1. Développez **Paramètres avancés**.
1. Dans la liste déroulante **Projet de gestion de cluster**, sélectionnez le projet de gestion de cluster créé à l'étape précédente.

### Configuration de votre pipeline {#configuring-your-pipeline}

Après avoir désigné un projet comme projet de gestion pour le cluster, ajoutez un fichier `.gitlab-ci.yml` dans ce projet. Par exemple :

```yaml
configure cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

### Définition de la portée de l'environnement {#setting-the-environment-scope}

Les [portées d'environnement](../project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope) sont utilisables lors de l'association de plusieurs clusters au même projet de gestion.

Chaque portée ne peut être utilisée que par un seul cluster pour un projet de gestion.

Par exemple, les clusters Kubernetes suivants sont associés à un projet de gestion :

| Cluster     | Portée d'environnement |
| ----------- | ----------------- |
| Développement | `*`               |
| Staging     | `staging`         |
| Production  | `production`      |

Les environnements définis dans le fichier `.gitlab-ci.yml` sont déployés sur le cluster Développement, Staging et Production.

```yaml
stages:
  - deploy

configure development cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: development

configure staging cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: staging

configure production cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```
