---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration des intégrations
description: "Configurez et gérez les paramètres des intégrations de projets et de groupes sur les instances GitLab Self-Managed."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Cette page contient la documentation administrateur pour les intégrations de projets et de groupes. Pour la documentation utilisateur, voir [Intégrations de projets](../../user/project/integrations/_index.md).

Les administrateurs de projets et de groupes peuvent configurer et activer des intégrations. En tant qu'administrateur d'instance, vous pouvez :

- Définir les paramètres de configuration par défaut d'une intégration.
- Configurer une liste blanche pour contrôler les intégrations pouvant être activées sur une instance GitLab.

## Configurer les paramètres par défaut d'une intégration {#configure-default-settings-for-an-integration}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour configurer les paramètres par défaut d'une intégration :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez une intégration.
1. Remplissez les champs.
1. Sélectionnez **Sauvegarder les modifications**.

> [!warning]
> Cela peut affecter la totalité ou la plupart des groupes et projets de votre instance GitLab. Consultez les détails ci-dessous.

Si c'est la première fois que vous configurez des paramètres au niveau de l'instance pour une intégration :

- L'intégration est activée pour tous les groupes et projets qui n'ont pas encore cette intégration configurée, si le bouton **Activer l'intégration** est activé dans les paramètres au niveau de l'instance.
- Les groupes et projets qui ont déjà l'intégration configurée ne sont pas affectés, mais peuvent choisir d'utiliser les paramètres hérités à tout moment.

Lorsque vous apportez d'autres modifications aux paramètres par défaut de l'instance :

- Ils sont immédiatement appliqués à tous les groupes et projets dont l'intégration est configurée pour utiliser les paramètres par défaut.
- Ils sont immédiatement appliqués aux groupes et projets plus récents, créés après la dernière sauvegarde des paramètres par défaut de l'intégration. Si le paramètre par défaut au niveau de l'instance a le bouton **Activer l'intégration** activé, l'intégration est automatiquement activée pour tous ces groupes et projets.
- Les groupes et projets disposant de paramètres personnalisés sélectionnés pour l'intégration ne sont pas immédiatement affectés et peuvent choisir d'utiliser les derniers paramètres par défaut à tout moment.

Si des [paramètres au niveau du groupe](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) ont également été configurés pour la même intégration, les projets de ce groupe héritent des paramètres au niveau du groupe plutôt que des paramètres au niveau de l'instance.

Seuls les paramètres complets d'une intégration peuvent être hérités. L'héritage par champ est proposé dans l'epic [2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Supprimer les paramètres par défaut d'une intégration {#remove-default-settings-for-an-integration}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour supprimer les paramètres par défaut d'une intégration :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez une intégration.
1. Sélectionnez **Réinitialiser** et confirmez.

La réinitialisation d'un paramètre par défaut au niveau de l'instance supprime l'intégration de tous les projets dont l'intégration est configurée pour utiliser les paramètres par défaut.

### Afficher les projets qui utilisent des paramètres personnalisés {#view-projects-that-use-custom-settings}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour afficher les projets de votre instance qui [utilisent des paramètres personnalisés](../../user/project/integrations/_index.md#use-custom-settings-for-a-project-or-group-integration) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez une intégration.
1. Sélectionnez l'onglet **Projets utilisant des paramètres personnalisés**.

## Liste blanche des intégrations {#integration-allowlist}

{{< details >}}

- Niveau :  Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) dans GitLab 17.7.

{{< /history >}}

Par défaut, les administrateurs de projets et de groupes peuvent activer des intégrations. Cependant, les administrateurs d'instance peuvent configurer une liste blanche pour contrôler les intégrations pouvant être activées sur une instance GitLab.

Les intégrations activées qui sont ensuite bloquées par les paramètres de la liste blanche sont désactivées. Si ces intégrations sont de nouveau autorisées, elles sont réactivées avec leur configuration existante.

Si vous configurez une liste blanche vide, aucune intégration n'est autorisée sur l'instance. Après avoir configuré une liste blanche, les nouvelles intégrations GitLab ne figurent pas sur la liste blanche par défaut.

### Autoriser certaines intégrations {#allow-some-integrations}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour n'autoriser que les intégrations figurant sur la liste blanche :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Paramètres d'intégration**.
1. Sélectionnez **Autoriser uniquement les intégrations sur cette liste blanche**.
1. Cochez la case de chaque intégration que vous souhaitez autoriser sur l'instance.
1. Sélectionnez **Sauvegarder les modifications**.

### Autoriser toutes les intégrations {#allow-all-integrations}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour autoriser toutes les intégrations sur une instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Paramètres d'intégration**.
1. Sélectionnez **Autoriser toutes les intégrations**.
1. Sélectionnez **Sauvegarder les modifications**.
