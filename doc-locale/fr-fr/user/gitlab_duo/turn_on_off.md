---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Désactiver les fonctionnalités GitLab Duo pour les instances, les groupes et les projets."
title: Contrôler la disponibilité de GitLab Duo
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction des paramètres permettant d'activer et de désactiver les fonctionnalités d'IA](https://gitlab.com/groups/gitlab-org/-/epics/12404) dans GitLab 16.10.
- [Ajout à l'interface utilisateur des paramètres permettant d'activer et de désactiver les fonctionnalités d'IA](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) dans GitLab 16.11.

{{< /history >}}

GitLab Duo est activé par défaut. GitLab Duo comprend un [ensemble de fonctionnalités](feature_summary.md).

Vous pouvez activer ou désactiver GitLab Duo :

- Sur GitLab.com : pour les groupes principaux, les autres groupes ou sous-groupes et les projets.
- Sur GitLab Self-Managed : pour les instances, les groupes ou sous-groupes et les projets.
- Sur GitLab Dedicated : les administrateurs peuvent également verrouiller des sous-groupes spécifiques sur **Toujours désactivée** afin que les utilisateurs disposant du rôle Propriétaire ne puissent pas activer GitLab Duo dans ces sous-groupes.

## Verrouiller GitLab Duo en mode activé {#lock-gitlab-duo-on}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/21844) dans GitLab 19.1.

{{< /history >}}

Activation de GitLab Duo pour l'ensemble des utilisateurs, quels que soient les paramètres du groupe ou du projet.

Lorsque vous définissez la disponibilité de GitLab Duo sur **Toujours activé**, les fonctionnalités en version expérimentale et en version bêta ne sont pas automatiquement activées. Pour utiliser les fonctionnalités en version expérimentale et en version bêta, vous devez [les activer séparément](#turn-on-beta-and-experimental-features).

{{< tabs >}}

{{< tab title="Sur GitLab.com" >}}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour verrouiller GitLab Duo en mode activé pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez **Toujours activé**.
1. Sélectionnez **Enregistrer les modifications**.

GitLab Duo est verrouillé en mode activé pour tous les sous-groupes et projets. Les personnes qui disposent du rôle Propriétaire pour un sous-groupe ou un projet ne peuvent pas désactiver GitLab Duo.

{{< /tab >}}

{{< tab title="Sur GitLab Self-Managed" >}}

Prérequis :

- Disposer d'un accès administrateur.

Pour verrouiller GitLab Duo en mode activé pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez **Toujours activé**.
1. Sélectionnez **Enregistrer les modifications**.

GitLab Duo est verrouillé en mode activé pour tous les groupes, sous-groupes et projets. Les personnes qui disposent du rôle Propriétaire pour un groupe, un sous-groupe ou un projet ne peuvent pas désactiver GitLab Duo.

{{< /tab >}}

{{< /tabs >}}

## Verrouiller GitLab Duo pour les sous-groupes sélectionnés {#lock-gitlab-duo-off-for-selected-subgroups}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated, GitLab Dedicated for Government

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/22389) dans GitLab 19.2.

{{< /history >}}

En tant qu'administrateur GitLab Dedicated, vous pouvez verrouiller des sous-groupes spécifiques sur **Toujours désactivée** pour GitLab Duo et GitLab Duo Agent Platform. Les utilisateurs disposant du rôle Propriétaire dans ces sous-groupes ne peuvent pas activer GitLab Duo, tandis que les autres sous-groupes restent sous le contrôle du propriétaire.

Le verrou s'applique au sous-groupe et à tous ses groupes et projets descendants. Les utilisateurs disposant du rôle Propriétaire pour le sous-groupe ou ses descendants ne peuvent pas modifier ce paramètre. Les propriétaires concernés voient un message indiquant que GitLab Duo est verrouillé par un groupe parent.

Un seul verrou peut exister dans une chaîne de groupes ancêtres et descendants. Lorsque vous verrouillez un sous-groupe :

- Si un groupe ancêtre possède déjà un verrou, le verrou n'est pas appliqué. Vous devez d'abord [effacer le verrou](#clear-the-lock-for-a-subgroup) du groupe ancêtre.
- Si un ou plusieurs sous-groupes descendants ont déjà des verrous d'administration, vous êtes invité à confirmer. Lorsque vous confirmez, les verrous sur ces sous-groupes descendants sont effacés et le verrou est appliqué au sous-groupe que vous avez sélectionné.

### Verrouiller un sous-groupe {#lock-a-subgroup}

Prérequis :

- Accès administrateur sur une instance GitLab Dedicated.

Pour désactiver et verrouiller GitLab Duo pour un sous-groupe :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Dans la section **Namespace availability overrides**, trouvez le sous-groupe.
1. Dans la ligne du sous-groupe, sous **Disponibilité de GitLab Duo**, sélectionnez **Toujours désactivée**.

### Effacer le verrou pour un sous-groupe {#clear-the-lock-for-a-subgroup}

Prérequis :

- Accès administrateur sur une instance GitLab Dedicated.

Pour effacer le verrou d'administration pour un sous-groupe :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Dans la section **Namespace availability overrides**, trouvez le sous-groupe.
1. Dans la ligne du sous-groupe, sélectionnez **Réinitialiser**.

Le sous-groupe revient à la valeur par défaut de l'instance. Les utilisateurs disposant du rôle Propriétaire pour le sous-groupe peuvent désormais contrôler la disponibilité de GitLab Duo.

## Activer ou désactiver GitLab Duo {#turn-gitlab-duo-on-or-off}

### Sur GitLab.com {#on-gitlabcom}

#### Pour un groupe principal {#for-a-top-level-group}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour modifier la disponibilité de GitLab Duo pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sélectionnez **Enregistrer les modifications**.

La disponibilité de GitLab Duo est modifiée pour tous les sous-groupes et projets.

#### Pour un groupe ou un sous-groupe {#for-a-group-or-subgroup}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe ou le sous-groupe.

Pour modifier la disponibilité de GitLab Duo pour un groupe ou un sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre sous-groupe.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sélectionnez **Enregistrer les modifications**.

La disponibilité de GitLab Duo est modifiée pour tous les sous-groupes et projets.

#### Pour un projet {#for-a-project}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour modifier la disponibilité de GitLab Duo pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **GitLab Duo**.
1. Activez ou désactivez le bouton bascule **GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

### Sur GitLab Self-Managed {#on-gitlab-self-managed}

#### Pour une instance {#for-an-instance}

Prérequis :

- Disposer d'un accès administrateur.

Pour modifier la disponibilité de GitLab Duo pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sélectionnez **Enregistrer les modifications**.

#### Pour un groupe ou un sous-groupe {#for-a-group-or-subgroup-1}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe ou le sous-groupe.

Pour modifier la disponibilité de GitLab Duo pour un groupe ou un sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre sous-groupe.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sélectionnez **Enregistrer les modifications**.

La disponibilité de GitLab Duo est modifiée pour tous les sous-groupes et projets.

#### Pour un projet {#for-a-project-1}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour modifier la disponibilité de GitLab Duo pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **GitLab Duo**.
1. Activez ou désactivez le bouton bascule **GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

### Pour les versions antérieures de GitLab {#for-earlier-gitlab-versions}

Pour savoir comment activer ou désactiver GitLab Duo dans les versions antérieures de GitLab, consultez la section [Contrôler la disponibilité de GitLab Duo pour les versions antérieures de GitLab](turn_on_off_earlier.md).

## Activer ou désactiver GitLab Duo Core {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/538857) dans GitLab 18.0.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/551895) des paramètres de disponibilité de GitLab Duo, ainsi que des contrôles au niveau des groupes, des sous-groupes et des projets, dans GitLab 18.2.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) de GitLab Duo Non-Agentic Chat à GitLab Duo Core dans GitLab 18.3.

{{< /history >}}

GitLab Duo Core est inclus avec les abonnements GitLab Premium et GitLab Ultimate.

- Si vous étiez déjà client sous GitLab 17.11 ou une version antérieure, vous devez activer les fonctionnalités de GitLab Duo Core.
- Si vous êtes un nouveau client sous GitLab 18.0 ou une version ultérieure, GitLab Duo Core est automatiquement activé et aucune autre action n'est requise.

Si vous disposiez déjà d'un abonnement GitLab Premium ou GitLab Ultimate avant le 15 mai 2025, vous devez activer GitLab Duo Core pour l'utiliser lorsque vous passez à GitLab 18.0 ou à une version ultérieure.

### Sur GitLab.com {#on-gitlabcom-1}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour modifier la disponibilité de GitLab Duo Core pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sous **GitLab Duo Core**, cochez ou décochez la case **Activer les fonctionnalités pour Gitlab Duo Core**. Si vous avez défini la disponibilité de GitLab Duo sur **Toujours désactivé**, vous ne pouvez pas accéder à ce paramètre.
1. Sélectionnez **Enregistrer les modifications**.

La modification peut ne prendre effet qu'au bout de 10 minutes.

### Sur GitLab Self-Managed {#on-gitlab-self-managed-1}

Prérequis :

- Disposer d'un accès administrateur.

Pour modifier la disponibilité de GitLab Duo Core pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Disponibilité de GitLab Duo**, sélectionnez une option.
1. Sous **GitLab Duo Core**, cochez ou décochez la case **Activer les fonctionnalités pour Gitlab Duo Core**. Si vous avez défini la disponibilité de GitLab Duo sur **Toujours désactivé**, vous ne pouvez pas accéder à ce paramètre.
1. Sélectionnez **Enregistrer les modifications**.

## Activer les fonctionnalités en version bêta et en version expérimentale {#turn-on-beta-and-experimental-features}

Les fonctionnalités GitLab Duo en version expérimentale et en version bêta sont désactivées par défaut. Ces fonctionnalités sont soumises au [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### Sur GitLab.com {#on-gitlabcom-2}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour activer les fonctionnalités GitLab Duo en version expérimentale et en version bêta pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Aperçu des fonctionnalités**, sélectionnez **Activer les fonctionnalités expérimentales et bêta de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Ce paramètre [s'applique en cascade à tous les projets](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group) appartenant au groupe.

### Sur GitLab Self-Managed {#on-gitlab-self-managed-2}

{{< tabs >}}

{{< tab title="Dans la version 17.4 et les versions ultérieures" >}}

Dans GitLab 17.4 et les versions ultérieures, suivez ces instructions pour activer les fonctionnalités GitLab Duo en version expérimentale et en version bêta pour votre instance GitLab Self-Managed.

Prérequis :

- Disposer d'un accès administrateur.

Pour activer les fonctionnalités GitLab Duo en version expérimentale et en version bêta pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Développez **Modifier la configuration**.
1. Sous **Aperçu des fonctionnalités**, sélectionnez **Utiliser les fonctionnalités expérimentales et bêta de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Dans la version 17.3 et les versions antérieures" >}}

Prérequis :

- Disposer d'un accès administrateur.
- [Connectivité réseau](../../administration/gitlab_duo/configure/_index.md) activée.
- [Mode silencieux](../../administration/silent_mode/_index.md) désactivé.

Pour activer les fonctionnalités GitLab Duo en version expérimentale et en version bêta pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Développez **Modifier la configuration**.
1. Sous **Aperçu des fonctionnalités**, sélectionnez **Utiliser les fonctionnalités expérimentales et bêta de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.
1. Pour que GitLab Duo Chat fonctionne immédiatement, [synchronisez manuellement votre abonnement](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).

   Si vous ne synchronisez pas manuellement votre abonnement, l'activation de GitLab Duo Chat sur votre instance peut prendre jusqu'à 24 heures.

{{< /tab >}}

{{< /tabs >}}
