---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurer la limitation du débit en cas d'abus Git pour restreindre et bannir automatiquement les utilisateurs qui dépassent les limites de téléchargement de dépôt définies sur une instance GitLab"
title: Taux limite avant abus de Git (administration)
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/8066) dans GitLab 15.2 [avec un indicateur](../feature_flags/_index.md) nommé `git_abuse_rate_limit_feature_flag`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/394996) dans GitLab 15.11. Indicateur de feature flag `git_abuse_rate_limit_feature_flag` supprimé.

{{< /history >}}

Il s'agit de la documentation d'administration. Pour plus d'informations sur la limitation du débit en cas d'abus Git pour un groupe, consultez la [documentation du groupe](../../user/group/reporting/git_abuse_rate_limit.md).

La limitation du débit en cas d'abus Git est une fonctionnalité permettant de [bannir automatiquement les utilisateurs](../moderate_users.md#ban-and-unban-users) qui téléchargent, clonent ou dupliquent plus d'un nombre spécifié de dépôts dans n'importe quel projet de l'instance pendant une période donnée. Les utilisateurs bannis ne peuvent pas se connecter à l'instance et ne peuvent pas accéder à un groupe non public via HTTP ou SSH. La limite de débit s'applique également aux utilisateurs qui s'authentifient avec un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) ou un [jeton d'accès de groupe](../../user/group/settings/group_access_tokens.md).

La limitation du débit en cas d'abus Git ne s'applique pas aux administrateurs d'instance, aux [jetons de déploiement](../../user/project/deploy_tokens/_index.md), ni aux [clés de déploiement](../../user/project/deploy_keys/_index.md).

La manière dont GitLab détermine la limite de débit d'un utilisateur est en cours de développement. Les membres de l'équipe GitLab peuvent consulter plus d'informations dans cet epic confidentiel : `https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`.

## Configurer la limitation du débit en cas d'abus Git {#configure-git-abuse-rate-limiting}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Développez **Taux limite avant abus de Git**.
1. Mettez à jour les paramètres de limitation du débit en cas d'abus Git :
   1. Entrez un nombre dans le champ **Nombre de dépôts**, supérieur ou égal à `0` et inférieur ou égal à `10000`. Ce nombre spécifie le nombre maximum de dépôts uniques qu'un utilisateur peut télécharger pendant la période spécifiée avant d'être banni. Lorsque la valeur est `0`, la limitation du débit en cas d'abus Git est désactivée.
   1. Entrez un nombre dans le champ **Durée considérée (secondes)**, supérieur ou égal à `0` et inférieur ou égal à `864000` (10 jours). Ce nombre spécifie le temps en secondes pendant lequel un utilisateur peut télécharger le nombre maximum de dépôts avant d'être banni. Lorsque la valeur est `0`, la limitation du débit en cas d'abus Git est désactivée.
   1. Facultatif. Excluez jusqu'à `100` utilisateurs en les ajoutant au champ **Utilisateurs et utilisatrices exclus**. Les utilisateurs exclus ne sont pas automatiquement bannis.
   1. Ajoutez jusqu'à `100` utilisateurs dans le champ **Envoyer des notifications à**. Vous devez sélectionner au moins un utilisateur. Tous les administrateurs d'application sont sélectionnés par défaut.
   1. Facultatif. Activez le bouton **Automatically ban users from this namespace when they exceed the specified limits** pour activer le bannissement automatique.
1. Sélectionnez **Sauvegarder les modifications**.

## Notifications de bannissement automatique {#automatic-ban-notifications}

Si le bannissement automatique est désactivé, un utilisateur n'est pas automatiquement banni lorsqu'il dépasse la limite. Cependant, des notifications sont toujours envoyées aux utilisateurs répertoriés sous **Envoyer des notifications à**. Vous pouvez utiliser cette configuration pour déterminer les valeurs correctes des paramètres de limite de débit avant d'activer le bannissement automatique.

Si le bannissement automatique est activé, une notification par e-mail est envoyée lorsqu'un utilisateur est sur le point d'être banni, et l'utilisateur est automatiquement banni de l'instance GitLab.

## Gracier un utilisateur banni {#unban-a-user}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez l'onglet **Banni** et recherchez le compte que vous souhaitez gracier.
1. Dans la liste déroulante **Administration des utilisateurs**, sélectionnez **Gracier l'utilisateur banni**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Gracier l'utilisateur banni**.
