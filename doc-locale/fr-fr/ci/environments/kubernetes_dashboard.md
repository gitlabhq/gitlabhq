---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tableau de bord pour Kubernetes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/390769) dans GitLab 16.1, avec les [feature flags](../../administration/feature_flags/_index.md) nommés `environment_settings_to_graphql`, `kas_user_access`, `kas_user_access_project` et `expose_authorized_cluster_agents`. Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md#beta).
- Le feature flag `environment_settings_to_graphql` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177) dans GitLab 16.2.
- Les feature flags `kas_user_access`, `kas_user_access_project` et `expose_authorized_cluster_agents` ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835) dans GitLab 16.2.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/431746) vers la page des détails de l'environnement dans la version 16.10.

{{< /history >}}

Utilisez le tableau de bord pour Kubernetes afin de comprendre le statut de vos clusters grâce à une interface visuelle intuitive. Le tableau de bord fonctionne avec chaque cluster Kubernetes connecté, que vous les ayez déployés avec CI/CD ou GitOps.

![Tableau de bord affichant le statut des pods et services Kubernetes.](img/kubernetes_summary_ui_v17_2.png)

## Configurer un tableau de bord {#configure-a-dashboard}

{{< history >}}

- Le filtrage des ressources par espace de nommage a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/403618) dans GitLab 16.2 [avec un flag](../../administration/feature_flags/_index.md) nommé `kubernetes_namespace_for_environment`. Désactivé par défaut.
- Le filtrage des ressources par espace de nommage est [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127043) dans GitLab 16.3. L'indicateur de fonctionnalité `kubernetes_namespace_for_environment` a été supprimé.
- La sélection de la ressource Flux associée a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857) dans GitLab 16.3 [avec un flag](../../administration/feature_flags/_index.md) nommé `flux_resource_for_environment`.
- La sélection de la ressource Flux associée est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648) dans GitLab 16.4. L'indicateur de fonctionnalité `flux_resource_for_environment` a été supprimé.

{{< /history >}}

Configurez un tableau de bord pour l'utiliser dans un environnement donné. Vous pouvez configurer un tableau de bord pour un environnement qui existe déjà, ou en ajouter un lors de la création d'un environnement.

Prérequis :

- Un agent GitLab pour Kubernetes est [installé](../../user/clusters/agent/install/_index.md) et [`user_access`](../../user/clusters/agent/user_access.md) est configuré pour le projet de l'environnement ou son groupe parent.

{{< tabs >}}

{{< tab title="L'environnement existe déjà" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez l'environnement à associer à l'agent pour Kubernetes.
1. Sélectionnez **Éditer**.
1. Sélectionnez un agent GitLab pour Kubernetes.
1. facultatif. Dans la liste déroulante **Kubernetes namespace**, sélectionnez un espace de nommage.
1. facultatif. Dans la liste déroulante **Flux resource**, sélectionnez une ressource Flux.
1. Sélectionnez **Enregistrer**.

{{< /tab >}}

{{< tab title="L'environnement n'existe pas" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez **Nouvel environnement**.
1. Renseignez le champ **Nom**.
1. Sélectionnez un agent GitLab pour Kubernetes.
1. facultatif. Dans la liste déroulante **Kubernetes namespace**, sélectionnez un espace de nommage.
1. facultatif. Dans la liste déroulante **Flux resource**, sélectionnez une ressource Flux.
1. Sélectionnez **Enregistrer**.

{{< /tab >}}

{{< /tabs >}}

### Configurer un tableau de bord pour un environnement dynamique {#configure-a-dashboard-for-a-dynamic-environment}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467912) dans GitLab 17.6.

{{< /history >}}

Pour configurer un tableau de bord pour un environnement dynamique :

- Spécifiez l'agent dans votre fichier `.gitlab-ci.yml`. Vous devez spécifier le chemin complet vers le projet de configuration de l'agent, suivi d'un deux-points et du nom de l'agent.

Par exemple :

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

Pour plus d'informations, consultez la [référence de syntaxe YAML CI/CD](../yaml/_index.md#environmentkubernetes).

## Afficher un tableau de bord {#view-a-dashboard}

{{< history >}}

- L'intégration de l'API watch Kubernetes a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/422945) dans GitLab 16.6 [avec un flag](../../administration/feature_flags/_index.md) nommé `k8s_watch_api`. Désactivé par défaut.
- L'intégration de l'API watch Kubernetes est [activée par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136831) dans GitLab 16.7.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/427762) dans GitLab 17.1. L'indicateur de fonctionnalité `k8s_watch_api` a été supprimé.

{{< /history >}}

Affichez un tableau de bord pour voir le statut des clusters connectés. Le statut de vos ressources Kubernetes et le rapprochement Flux sont mis à jour en temps réel.

Pour afficher un tableau de bord configuré :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez l'environnement associé à l'agent pour Kubernetes.
1. Sélectionnez l'onglet **Présentation de Kubernetes**.

Une liste de pods s'affiche. Sélectionnez un pod pour afficher ses détails.

### Statut de synchronisation Flux {#flux-sync-status}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/391581) dans GitLab 16.3.
- La personnalisation du nom de la ressource Flux a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857) dans GitLab 16.3 [avec un flag](../../administration/feature_flags/_index.md) nommé `flux_resource_for_environment`.
- La personnalisation du nom de la ressource Flux est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648) dans GitLab 16.4. L'indicateur de fonctionnalité `flux_resource_for_environment` a été supprimé.

{{< /history >}}

Vous pouvez consulter le statut de synchronisation de vos déploiements Flux depuis un tableau de bord. Pour afficher le statut du déploiement, votre tableau de bord doit pouvoir récupérer les ressources `Kustomization` et `HelmRelease`, ce qui nécessite qu'un espace de nommage soit configuré pour l'environnement.

GitLab recherche les ressources `Kustomization` et `HelmRelease` spécifiées par la liste déroulante **Flux resource** dans les paramètres de l'environnement.

Un tableau de bord affiche l'un des badges de statut suivants :

| Statut | Description |
|---------|-------------|
| **Rapprochement fait** | Le déploiement a été rapproché avec succès de son environnement. |
| **Rapprochement en cours** | Un rapprochement est en cours. |
| **Point mort** | Un rapprochement est bloqué en raison d'une erreur qui ne peut pas être résolue sans intervention humaine. |
| **Échec** | Le déploiement n'a pas pu être rapproché en raison d'une erreur irrécupérable. |
| **Inconnu(e)** | Le statut de synchronisation du déploiement n'a pas pu être récupéré. |
| **Non disponible** | La ressource `Kustomization` ou `HelmRelease` n'a pas pu être récupérée. |

### Rapprochement des déclencheurs Flux {#trigger-flux-reconciliation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/434248) dans GitLab 17.3.

{{< /history >}}

Vous pouvez rapprocher manuellement votre déploiement avec ses ressources Flux.

Pour déclencher un rapprochement :

1. Sur un tableau de bord, sélectionnez le badge de statut de synchronisation d'un déploiement Flux.
1. Sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Rapprochement des déclencheurs** ({{< icon name="retry" >}}).

### Suspendre ou reprendre le rapprochement Flux {#suspend-or-resume-flux-reconciliation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/478380) dans GitLab 17.5.

{{< /history >}}

Vous pouvez suspendre ou reprendre manuellement votre rapprochement Flux depuis l'interface utilisateur.

Pour suspendre ou reprendre le rapprochement :

1. Sur un tableau de bord, sélectionnez le badge de statut de synchronisation d'un déploiement Flux.
1. Sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}), puis choisissez l'une des options suivantes :
   - **Suspendre le rapprochement** ({{< icon name="stop" >}}) pour mettre en pause le rapprochement Flux.
   - **Reprendre le rapprochement** ({{< icon name="play" >}}) pour redémarrer le rapprochement Flux.

### Afficher les journaux de pod {#view-pod-logs}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13793) dans GitLab 17.2.

{{< /history >}}

Affichez les journaux de pod lorsque vous souhaitez comprendre rapidement et résoudre les problèmes dans vos environnements depuis un tableau de bord configuré. Vous pouvez afficher les journaux pour chaque conteneur dans un pod.

- Sélectionnez **Voir les journaux**, puis sélectionnez le conteneur dont vous souhaitez afficher les journaux.

Vous pouvez également afficher les journaux de pod depuis les détails du pod.

### Supprimer un pod {#delete-a-pod}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467653) dans GitLab 17.3.

{{< /history >}}

Pour redémarrer un pod en échec, supprimez-le depuis le tableau de bord Kubernetes.

Pour supprimer un pod :

1. Dans l'onglet **Présentation de Kubernetes**, trouvez le pod que vous souhaitez supprimer.
1. Sélectionnez **Actions** ({{< icon name="ellipsis_v" >}}) > **Supprimer un pod** ({{< icon name="remove" >}}).

Vous pouvez également supprimer un pod depuis les détails du pod.

## Tableau de bord détaillé {#detailed-dashboard}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11351) dans GitLab 16.4, [avec un flag](../../administration/feature_flags/_index.md) nommé `k8s_dashboard`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/424237) dans GitLab 16.7 pour un sous-ensemble d'utilisateurs.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Le tableau de bord détaillé fournit des informations sur les ressources Kubernetes suivantes :

- Pods
- Services
- Déploiements
- ReplicaSets
- StatefulSets
- DaemonSets
- Jobs
- CronJobs

Chaque tableau de bord affiche une liste de ressources avec leurs statuts, espaces de nommage et leur ancienneté. Vous pouvez sélectionner une ressource pour ouvrir un panneau contenant davantage d'informations, notamment les labels et le statut au format YAML, les annotations et les spécifications.

![Tableau de bord avec des informations détaillées sur le cluster connecté.](img/kubernetes_dashboard_deployments_v16_9.png)

En raison du changement de priorité décrit dans [ce ticket](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/general/-/issues/53#note_1720060812), les travaux sur le tableau de bord détaillé sont suspendus.

Pour fournir un retour sur le tableau de bord détaillé, consultez le [ticket 460279](https://gitlab.com/gitlab-org/gitlab/-/issues/460279).

### Afficher un tableau de bord détaillé {#view-a-detailed-dashboard}

Prérequis :

- Un agent GitLab pour Kubernetes est [configuré](../../user/clusters/agent/install/_index.md) et partagé avec le projet de l'environnement, ou son groupe parent, à l'aide du mot-clé [`user_access`](../../user/clusters/agent/user_access.md).

Le tableau de bord détaillé n'est pas accessible depuis la navigation dans la barre latérale. Pour afficher un tableau de bord détaillé :

1. Trouvez l'ID de votre agent pour Kubernetes :
   1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
   1. Sélectionnez **Opération** > **Clusters Kubernetes**.
   1. Copiez l'ID numérique de l'agent auquel vous souhaitez accéder.
1. Accédez à l'une des URL suivantes en remplaçant `<agent_id>` par l'ID de votre agent :

   | Type de ressource | URL |
   | --- | --- |
   | Pods | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/pods` |
   | Services | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/services` |
   | Déploiements | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/deployments` |
   | ReplicaSets | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/replicaSets` |
   | StatefulSets | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/statefulSets` |
   | DaemonSets | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/daemonSets` |
   | Jobs | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/jobs` |
   | CronJobs | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/cronJobs` |

## Dépannage {#troubleshooting}

Lorsque vous utilisez le tableau de bord pour Kubernetes, vous pouvez rencontrer les problèmes suivants.

### L'utilisateur ne peut pas lister la ressource dans le groupe d'API {#user-cannot-list-resource-in-api-group}

Vous pourriez obtenir une erreur indiquant `Error: services is forbidden: User "gitlab:user:<user-name>" cannot list resource "<resource-name>" in API group "" at the cluster scope`.

Cette erreur se produit lorsqu'un utilisateur n'est pas autorisé à effectuer l'opération spécifiée dans le [RBAC Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).

Pour résoudre ce problème, vérifiez votre [configuration RBAC](../../user/clusters/agent/user_access.md#configure-kubernetes-access). Si le RBAC est correctement configuré, contactez votre administrateur Kubernetes.

### La liste déroulante Agent GitLab est vide {#gitlab-agent-dropdown-list-is-empty}

Lorsque vous configurez un nouvel environnement, la liste déroulante **Agent GitLab** peut être vide, même si vous avez configuré des clusters Kubernetes.

Pour remplir la liste déroulante **Agent GitLab**, accordez à un agent l'accès Kubernetes avec le mot-clé [`user_access`](../../user/clusters/agent/user_access.md).
