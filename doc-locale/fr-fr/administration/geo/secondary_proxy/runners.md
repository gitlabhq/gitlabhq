---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Runners secondaires
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/9779) dans GitLab 16.8 [avec un flag](../../feature_flags/_index.md) nommé `geo_proxy_check_pipeline_refs`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/434041) dans GitLab 16.9.

{{< /history >}}

Avec [le proxying Geo pour les sites secondaires](_index.md), il est possible d'enregistrer un `gitlab-runner` auprès d'un site secondaire. Cela décharge le trafic de l'instance primaire.

> [!note]
> Les jobs qui démarrent lors de la première étape d'un pipeline ont presque toujours leurs requêtes de clonage Git transmises au site primaire. En effet, ces clonages ont généralement lieu avant que les données Git ne soient répliquées et vérifiées par le site secondaire. Les étapes ultérieures ne sont pas non plus garanties d'être servies par le site secondaire, par exemple si la modification Git est volumineuse, la bande passante est faible ou les étapes du pipeline sont courtes. Dans la plupart des cas, les étapes suivantes du pipeline servent les données Git depuis le site secondaire. [Issue 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176) propose une amélioration pour augmenter la probabilité que la requête de clonage de la première étape soit servie depuis le site secondaire.

## Utiliser des runners secondaires avec une URL publique Location Aware (URL unifiée) {#use-secondary-runners-with-a-location-aware-public-url-unified-url}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

L'utilisation du [DNS Location-Aware](_index.md#configure-location-aware-dns), avec le feature flag activé, fonctionne sans configuration supplémentaire. Après avoir installé et enregistré un runner au même emplacement qu'un site secondaire, il communique automatiquement avec le site le plus proche et ne proxifie vers le primaire que si le secondaire n'est pas à jour.

## Utiliser des runners secondaires avec des URL séparées {#use-secondary-runners-with-separate-urls}

En utilisant des URL secondaires séparées, les runners doivent être :

1. Enregistrés avec l'URL externe secondaire.
1. Configurés avec [`clone_url`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-clone_url-works) défini sur le `external_url` de l'instance secondaire.

## Gestion d'un basculement planifié avec des runners secondaires {#handling-a-planned-failover-with-secondary-runners}

Lors de l'exécution [d'un basculement planifié](../disaster_recovery/planned_failover.md), les runners secondaires tentent de continuer à communiquer avec leur instance locale. Cela entraîne une diminution de la capacité des runners, ce qui peut nécessiter d'être pris en compte.

### Avec une URL publique Location Aware {#with-location-aware-public-url}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Lors de l'utilisation du [DNS Location-Aware](_index.md#configure-location-aware-dns), tous les runners se connectent automatiquement au site Geo le plus proche.

Lors du basculement vers un nouveau primaire :

- Tant que l'ancien primaire figure encore dans l'enregistrement DNS, les runners précédemment connectés à votre ancien primaire tentent toujours de prendre en charge des jobs depuis l'ancien primaire. S'il est inaccessible, les runners [le détectent](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-unhealthy_requests_limit-and-unhealthy_interval-works) et cessent d'envoyer des requêtes pendant une période prolongée après le retour de l'instance.
- Si vous avez [plusieurs nœuds secondaires](../disaster_recovery/_index.md#promoting-secondary-geo-replica-in-multi-secondary-configurations), après le basculement initial, les secondaires restants sont dans un état non sain jusqu'à ce qu'ils soient [répliqués](../disaster_recovery/_index.md#step-2-initiate-the-replication-process) avec le nouveau primaire. Les runners qui leur sont rattachés ne peuvent alors plus effectuer d'enregistrement, et leur vérification de l'état de santé s'active également.
- Si vous retirez l'un des nœuds non sains de l'entrée DNS Geo, les runners choisissent l'instance suivante la plus proche. Selon votre architecture, ce n'est peut-être pas ce que vous souhaitez, car vous pourriez surcharger votre site dans son état réduit.

Pour atténuer ces problèmes, vous pouvez [mettre en pause](#pausing-runners) ou arrêter certains des runners jusqu'à ce que le site soit de nouveau opérationnel à 100 %.

Si ces problèmes ne vous préoccupent pas, vous n'avez rien à faire ici.

### Avec des URL séparées {#with-separate-urls}

- Si vous remettez l'ancien primaire en service, vous pouvez mettre en pause les runners de l'ancien primaire jusqu'à ce qu'il soit de nouveau en ligne. Cela empêche la vérification de l'état de santé de s'activer.
- Si l'ancien primaire ne revient pas, ou si vous souhaitez éviter une réduction temporaire de la capacité des runners, les runners primaires doivent être reconfigurés pour se connecter au nouveau primaire.
- Si plusieurs secondaires sont utilisés, les runners doivent être [mis en pause](#pausing-runners), arrêtés ou reconfigurés pour se connecter au nouveau primaire pendant qu'ils sont répliqués vers le nouveau primaire.

### Mise en pause des runners {#pausing-runners}

Vous devez disposer d'un accès administrateur pour utiliser l'une des méthodes suivantes :

- Via la zone **Admin** :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Sélectionnez **Paramètres** > **Runners**.
  1. Identifiez les runners que vous souhaitez mettre en pause.
  1. Sélectionnez le bouton `pause` en regard de chaque runner que vous souhaitez mettre en pause.
  1. Une fois le basculement terminé, réactivez les runners que vous avez mis en pause à l'étape précédente.
- Utilisez l'[API Runners](../../../api/runners.md) :
  1. Récupérez ou créez un [jeton d'accès personnel](../../../user/profile/personal_access_tokens.md) avec un accès administrateur.
  1. Obtenez la liste des runners. Vous pouvez filtrer la liste [à l'aide de l'API](../../../api/runners.md#list-all-runners).
  1. Identifiez les runners que vous souhaitez mettre en pause et notez leur `id`.
  1. [Suivez la documentation de l'API](../../../api/runners.md#pause-a-runner) pour mettre en pause chaque runner.
  1. Une fois le basculement terminé, réactivez la liste des runners à l'aide de l'API en définissant `paused=false`.
