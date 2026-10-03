---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment GitLab Secrets Manager est facturé, comment il consomme des GitLab Credits et comment démarrer un essai."
title: Utilisation des crédits par GitLab Secrets Manager
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/10723) dans GitLab 19.3 pour GitLab.com

{{< /history >}}

L'utilisation de GitLab Secrets Manager consomme des [GitLab Credits](../../../subscriptions/gitlab_credits.md) selon deux compteurs :

- Secrets stockés : nombre de secrets conservés dans GitLab Secrets Manager, mesuré par secret et par mois.
- Opérations sur les secrets : la récupération d'un secret (dans les pipelines, depuis des clusters Kubernetes ou via l'API) compte comme une opération. Les mises à jour et suppressions de secrets ne sont pas comptabilisées comme des opérations.

## Consommation de GitLab Credits {#gitlab-credits-consumption}

Les GitLab Credits utilisés pour GitLab Secrets Manager sont prélevés depuis le [pool d'engagement mensuel](../../../subscriptions/gitlab_credits.md#monthly-commitment-pool) et les [crédits à la demande](../../../subscriptions/gitlab_credits.md#on-demand-credits) disponibles dans l'abonnement du groupe principal (espace de nommage). L'utilisation de GitLab Secrets Manager dans les projets et sous-groupes du groupe consomme les crédits du groupe principal.

> [!note]
> Les [crédits inclus](../../../subscriptions/gitlab_credits.md#included-credits) alloués à chaque utilisateur ne s'appliquent pas à GitLab Secrets Manager.

Les plafonds d'utilisation des GitLab Credits ne limitent pas l'utilisation de GitLab Secrets Manager. Les plafonds par utilisateur ne s'appliquent pas, car l'utilisation n'est pas attribuée à des utilisateurs individuels, et les plafonds de dépenses par espace de nommage ne bloquent pas la consommation de GitLab Secrets Manager.

Les crédits sont consommés pour le stockage des secrets et les opérations selon les tarifs suivants :

| Type           | Tarifs                 | Crédits | Détails |
|----------------|-----------------------|---------|---------|
| Secrets stockés | Un secret, par mois | 1       | La consommation de crédits est calculée au prorata quotidien, en fonction de la durée d'existence d'un secret. Par exemple, deux secrets stockés pendant la moitié d'un mois consomment un crédit. |
| Lectures de secrets   | 2 500 lectures       | 1       | Opérations de lecture de secrets sur l'ensemble des secrets. Inclut la récupération de secrets avec un job CI/CD, l'API GitLab Secrets Manager ou des intégrations (ESO, Terraform, OpenBao CLI). |

Consultez et gérez l'utilisation des crédits dans le [tableau de bord GitLab Credits](../../../subscriptions/gitlab_credits_dashboard.md).

### Dans les jobs CI/CD {#in-cicd-jobs}

Chaque secret récupéré avec succès dans un job CI/CD compte comme une opération de lecture, même si le job échoue par la suite. Un job qui référence plusieurs secrets effectue une opération de lecture pour chaque secret. Si vous relancez le job, les secrets sont à nouveau récupérés.

Les opérations sur les secrets ne consomment pas de crédits si l'opération de lecture échoue, notamment dans les cas suivants :

- Le secret référencé n'existe pas.
- La lecture échoue en raison d'une erreur de permission.

### Exemples {#examples}

Pour vous aider à estimer la consommation mensuelle attendue de secrets dans différentes situations, voici quelques exemples :

- Une petite équipe avec 25 secrets stockés, 500 pipelines par mois et 5 secrets lus par pipeline.
  - Stockage : 25 secrets = 25 crédits
  - Opérations : 2 500 lectures = 1 crédit
  - Total mensuel : 26 crédits
- Une application multi-environnement avec 120 secrets répartis entre les environnements de développement, de staging et de production, 2 000 pipelines par mois et 5 secrets lus par pipeline.
  - Stockage : 120 secrets = 120 crédits
  - Opérations : 10 000 lectures = 4 crédits
  - Total mensuel : 124 crédits
- Utilisation au niveau entreprise avec 1 000 secrets stockés, 50 000 pipelines par mois et 10 secrets lus par pipeline.
  - Stockage : 1 000 secrets = 1 000 crédits
  - Opérations : 500 000 lectures = 200 crédits
  - Total mensuel : 1 200 crédits

## Fin de votre abonnement {#when-your-subscription-ends}

Lorsque l'abonnement GitLab Premium ou GitLab Ultimate pour votre espace de nommage est annulé ou expire, GitLab Secrets Manager entre dans une période de grâce de 14 jours à compter de la date de fin d'abonnement.

Pendant la période de grâce :

- Les pipelines et les comptes de service peuvent toujours effectuer des opérations de lecture de secrets.
- Vous ne pouvez pas créer, mettre à jour ni supprimer des secrets.

À la fin de la période de grâce, les opérations sur les secrets sont bloquées. GitLab ne supprime pas vos secrets et vous pouvez toujours les consulter dans l'interface utilisateur.

Pour rétablir l'accès complet, renouvelez votre abonnement.

## Fin de la version bêta {#end-of-beta}

L'utilisation en version bêta de GitLab Secrets Manager ne consomme pas de GitLab Credits. La version bêta pour GitLab.com se termine le 21 septembre 2026.

À tout moment avant la fin de la version bêta, vous pouvez démarrer un essai et utiliser des crédits d'évaluation temporaires. À la fin de l'essai, vous devez vous assurer que vous disposez de GitLab Credits disponibles dans votre abonnement afin d'éviter toute interruption de service.

Si vous ne démarrez pas l'essai, GitLab Secrets Manager est désactivé à la fin de la version bêta.

## Démarrer un essai {#start-a-trial}

Vous pouvez évaluer GitLab Secrets Manager avec un essai gratuit de 30 jours. L'essai fournit un pool de 500 [crédits d'évaluation temporaires](../../../subscriptions/gitlab_credits.md#temporary-evaluation-credits) pour les secrets stockés et les opérations sur les secrets.

L'essai se termine dès que l'un des événements suivants se produit en premier :

- 30 jours se sont écoulés depuis l'activation.
- Tous les crédits d'évaluation temporaires sont consommés.

Les crédits d'évaluation temporaires sont partagés entre l'ensemble de l'espace de nommage et ne sont pas alloués par utilisateur. Ils ne sont pas reportés et ne peuvent pas être utilisés après leur expiration.

Vous ne pouvez activer un essai qu'une seule fois pour votre abonnement. Si votre espace de nommage a déjà utilisé un essai, il n'est pas éligible pour en activer un autre.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Gestionnaire de secrets**.
1. Sélectionnez **Commencer un essai de 30 jours**.

À la fin de l'essai :

- Si vous disposez de [GitLab Credits disponibles](../../../subscriptions/gitlab_credits.md) dans votre abonnement, l'utilisation se poursuit sans interruption, en prélevant d'abord depuis le pool d'engagement mensuel, puis depuis les crédits à la demande.
- Si vous n'avez pas accès aux GitLab Credits, les opérations de GitLab Secrets Manager sont bloquées et les opérations de lecture ainsi que les pipelines dépendants échouent. Pour rétablir l'accès, vous devez [acheter des GitLab Credits](../../../subscriptions/gitlab_credits.md#buy-gitlab-credits).
