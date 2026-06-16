---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Attribuer automatiquement le rôle de relecteur à tous les propriétaires du code lorsqu'une merge request est prête."
title: Attribution automatique des relecteurs
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175) dans GitLab 18.10 [avec un indicateur](../../../../administration/feature_flags/_index.md) nommé `auto_assign_code_owner_reviewers`. Désactivé par défaut.

{{< /history >}}

Lorsque vous activez l'attribution automatique des relecteurs, GitLab attribue les [propriétaires du code](../../codeowners/_index.md) des fichiers modifiés comme relecteurs sur une merge request. Vous n'avez pas à sélectionner manuellement les relecteurs dans le fichier `CODEOWNERS`.

Cette fonctionnalité est en [bêta](../../../../policy/development_stages_support.md#beta). Pour laisser un commentaire, commentez le [ticket 589700](https://gitlab.com/gitlab-org/gitlab/-/issues/589700).

## Prérequis {#prerequisites}

- Le projet doit disposer d'un [fichier `CODEOWNERS`](../../codeowners/_index.md).
- Le rôle Maintainer ou Owner pour le projet.

## Activer l'attribution automatique des relecteurs {#enable-automatic-reviewer-assignment}

Pour activer l'attribution automatique des relecteurs pour un projet :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Sélectionnez **Paramètres** > **Merge requests**.
1. Accédez à la section **Affectation automatique des relecteurs**.
1. Sélectionnez **Attribuer automatiquement le rôle de relecteur à tous les propriétaires du code**.
1. Sélectionnez **Sauvegarder les modifications**.

## Quand GitLab attribue des relecteurs {#when-gitlab-assigns-reviewers}

Une fois le paramètre activé, GitLab attribue les propriétaires du code comme relecteurs dans les cas suivants :

- Une merge request est créée dans un état prêt.
- Une merge request en brouillon est marquée comme prête.

GitLab attribue chaque propriétaire du code correspondant aux fichiers modifiés dans la merge request.

GitLab ignore l'attribution automatique dans les cas suivants :

- La merge request est un brouillon.
- La merge request a déjà un relecteur. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code) est exclu de cette vérification.
- Aucun propriétaire du code ne correspond aux fichiers modifiés dans la merge request.
- L'auteur de la merge request ne dispose pas des autorisations nécessaires pour définir les métadonnées de la merge request.

## Stratégie d'attribution des relecteurs {#reviewer-assignment-strategy}

Dans les projets où [GitLab Duo Agent Platform](../../../../user/duo_agent_platform/_index.md) recommande des relecteurs, la section **Attribution automatique des relecteurs** affiche une **Stratégie d'affectation des relecteurs** avec les options suivantes :

- **Ne pas affecter automatiquement les relecteurs** : GitLab ne modifie pas les relecteurs.
- **Attribuer le rôle de relecteur à tous les propriétaires du code** : GitLab attribue chaque propriétaire du code du fichier `CODEOWNERS` correspondant aux fichiers modifiés.
- **Affecter des relecteurs à l'aide de GitLab Duo Agent Platform** : GitLab Duo Agent Platform recommande le nombre minimum de relecteurs requis pour satisfaire chaque règle d'approbation.

## Sujets connexes {#related-topics}

- [Propriétaires du code](../../codeowners/_index.md)
- [Revues de merge request](_index.md)
- [Règles d'approbation des merge requests](../approvals/rules.md)
