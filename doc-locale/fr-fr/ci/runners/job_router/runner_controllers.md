---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Contrôleurs de runner
description: "Contrôlez l'admission des jobs avec des contrôleurs de runner."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Statut :  Expérience

{{< /details >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) dans GitLab 18.9 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `job_router_admission_control`. Désactivé par défaut. Cette fonctionnalité est une [version expérimentale](../../../policy/development_stages_support.md) et est soumise au [contrat de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- [Portée du runner introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/586417) dans GitLab 18.10.

{{< /history >}}

Les contrôleurs de runner permettent le contrôle d'admission pour les jobs CI/CD acheminés via le [routeur de jobs](_index.md). Lorsqu'un job est sur le point d'être exécuté, le routeur de jobs envoie une demande d'admission aux contrôleurs de runner connectés, qui peuvent admettre ou rejeter le job en fonction de politiques personnalisées.

Les contrôleurs de runner sont au niveau de l'instance et s'appliquent aux jobs en fonction de leur [portée](#scoping).

Utilisez les contrôleurs de runner pour :

- Appliquer des politiques d'admission personnalisées telles que des listes d'autorisation d'images, des quotas de ressources ou des exigences de sécurité.
- Contrôler la mise en file d'attente des jobs et l'allocation des ressources pour la gestion de la capacité.
- S'assurer que les jobs respectent les politiques organisationnelles avant leur exécution pour la conformité.
- Limiter l'exécution des jobs en fonction des contraintes budgétaires ou de ressources pour la maîtrise des coûts.

## Workflow de contrôle d'admission {#admission-control-workflow}

Lorsque vous configurez des contrôleurs de runner avec le routeur de jobs, le workflow de contrôle d'admission fonctionne comme suit :

1. Un contrôleur de runner se connecte au routeur de jobs.
1. Le contrôleur s'enregistre et commence à traiter les demandes d'admission.
1. Lorsqu'un job nécessite une admission, le routeur de jobs envoie les détails du job aux contrôleurs connectés.
1. Le contrôleur évalue le job par rapport aux politiques personnalisées.
1. Le contrôleur envoie une décision d'admission (admission ou rejet avec motif).
1. Le routeur de jobs procède à l'exécution du job ou signale le rejet.

## Afficher les motifs de rejet {#view-rejection-reasons}

Lorsqu'un contrôleur de runner rejette un job, le job échoue avec le motif d'échec `job_router_failure`. La page de détails du job affiche un message qui inclut :

- Informations sur le routeur de jobs
- Informations sur le contrôleur de runner
- Le motif de rejet fourni par le contrôleur de runner

![Message de rejet du job indiquant le motif de rejet du contrôleur de runner](img/job_rejection_message_v18_9.png)

### Journalisation en mode simulation {#dry-run-mode-logging}

Lorsqu'un contrôleur de runner est dans l'état `dry_run`, les décisions de rejet ne sont pas appliquées, mais sont consignées en tant que messages d'information dans les journaux du backend du routeur de jobs (KAS). Utilisez ces journaux pour valider le comportement de votre contrôleur avant d'activer l'application des règles.

## États des contrôleurs de runner {#runner-controller-states}

Les contrôleurs de runner peuvent se trouver dans l'un des trois états suivants :

| État | Description |
|-------|-------------|
| `disabled` | Le contrôleur de runner ne reçoit pas de demandes d'admission. Il s'agit de l'état par défaut. |
| `enabled` | Le contrôleur de runner reçoit des demandes d'admission et ses décisions affectent l'exécution des jobs. |
| `dry_run` | Le contrôleur de runner reçoit des demandes d'admission. Le routeur de jobs consigne les décisions, mais celles-ci ne sont pas appliquées. Utilisez cet état pour des déploiements progressifs afin de valider le comportement du contrôleur et de réduire les risques liés aux déploiements avant d'activer l'application des règles. |

## Portée {#scoping}

Les contrôleurs de runner doivent être délimités par une portée pour être actifs. Un contrôleur de runner sans aucune portée ne reçoit pas de demandes d'admission, même lorsque son état est `enabled` ou `dry_run`.

Les contrôleurs de runner prennent en charge deux types de portée mutuellement exclusifs :

| Portée | Description |
|-------|-------------|
| Instance | Le contrôleur de runner évalue les jobs pour tous les runners de l'instance GitLab. Cette portée ne peut pas être combinée avec la portée du runner. |
| Runner | Le contrôleur de runner évalue les jobs uniquement pour des runners spécifiques. Vous pouvez délimiter un contrôleur à un ou plusieurs runners. Le runner doit être un runner d'instance. |

Des types de portée supplémentaires (groupe, projet) sont proposés dans le [ticket 586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419).

Pour gérer la portée des contrôleurs de runner, consultez l'[API des contrôleurs de runner](../../../api/runner_controllers.md).

## Gérer les contrôleurs de runner {#manage-runner-controllers}

Les contrôleurs de runner sont gérés via l'API REST. Il n'existe pas encore d'interface utilisateur pour gérer les contrôleurs de runner.

- Pour créer, lister, mettre à jour ou supprimer des contrôleurs de runner, consultez l'[API des contrôleurs de runner](../../../api/runner_controllers.md).
- Pour créer, lister ou supprimer des portées pour les contrôleurs de runner, consultez l'[API des portées de contrôleurs de runner](../../../api/runner_controllers.md#runner-controller-scopes).
- Pour gérer les jetons d'authentification des contrôleurs de runner, consultez l'[API des jetons de contrôleurs de runner](../../../api/runner_controller_tokens.md).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance GitLab.

## Implémenter un contrôleur de runner {#implement-a-runner-controller}

Pour un guide étape par étape, consultez [Tutoriel : Créer un contrôleur d'admission de runner](../../../tutorials/build_runner_admission_controller/_index.md).

Pour implémenter votre propre contrôleur de runner, vous devez :

1. Créer un contrôleur de runner dans GitLab.
1. Définir la portée du contrôleur de runner.
1. Obtenir un jeton de contrôleur de runner.
1. Se connecter au routeur de jobs avec le jeton.
1. Enregistrer votre contrôleur auprès du routeur de jobs.
1. Traiter les demandes d'admission et envoyer des décisions.

Pour les spécifications techniques et les définitions protobuf, consultez la [documentation du contrôleur de runner](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md) dans le dépôt GitLab Agent for Kubernetes.

## Sujets connexes {#related-topics}

- [Routeur de jobs](_index.md)
- [API des contrôleurs de runner](../../../api/runner_controllers.md)
- [API des portées de contrôleurs de runner](../../../api/runner_controllers.md#runner-controller-scopes)
- [API des jetons de contrôleurs de runner](../../../api/runner_controller_tokens.md)
- [Tutoriel : Créer un contrôleur d'admission de runner](../../../tutorials/build_runner_admission_controller/_index.md)
- [Exemple de contrôleur de runner](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example) (implémentation de référence)
