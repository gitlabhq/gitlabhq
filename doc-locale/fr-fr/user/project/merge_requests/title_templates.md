---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez des modèles de titre de merge request pour définir un format de titre par défaut pour les nouvelles merge requests dans votre projet.
title: Modèles de titre de merge request
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut. Cette fonctionnalité est en [bêta](../../../policy/development_stages_support.md#beta).
- Disponible en général dans GitLab 19.0. Feature flag `mr_default_title_template` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642).

{{< /history >}}

Les modèles de titre de merge request définissent le titre par défaut des nouvelles merge requests dans un projet. Utilisez des modèles pour standardiser les conventions de nommage des merge requests au sein de votre équipe.

Les modèles prennent en charge des variables qui se développent en valeurs telles que le nom de la branche source ou le message du premier commit. Les utilisateurs peuvent modifier le titre avant de créer la merge request.

## Configurer un modèle de titre de merge request {#configure-a-merge-request-title-template}

Prérequis :

- Vous devez disposer au minimum du rôle Maintainer pour le projet.

Pour configurer un modèle de titre de merge request :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Faites défiler jusqu'à **Modèle de titre de requête de fusion**.
1. Saisissez un modèle à l'aide de texte statique et de [variables prises en charge](#supported-variables). Le modèle est limité à 100 caractères.
1. Sélectionnez **Sauvegarder les modifications**.

Pour supprimer le modèle et restaurer le comportement par défaut, effacez le champ du modèle et sélectionnez **Sauvegarder les modifications**.

## Variables prises en charge {#supported-variables}

Les modèles de titre prennent en charge les variables suivantes :

| Variable               | Description                                                                                                    | Exemple de résultat |
|------------------------|----------------------------------------------------------------------------------------------------------------|----------------|
| `%{source_branch}`     | Le nom de la branche source.                                                                                 | `my-feature-branch` |
| `%{target_branch}`     | Le nom de la branche cible.                                                                                 | `main`         |
| `%{title_from_branch}` | Le nom de la branche source converti en un format lisible par l'homme. Les tirets et les underscores sont remplacés par des espaces. | `My feature branch` |
| `%{first_commit_title}` | L'objet (première ligne) du premier commit dans la merge request.                                            | `Update README.md` |
| `%{issue_id}`           | L'IID du ticket lié via le nom de la branche source (par exemple, `123` à partir de `123-fix-bug`). Vide si aucun ticket n'est détecté. | `123` |
| `%{issue_title}`        | Le titre du ticket lié via le nom de la branche source. Vide si aucun ticket n'est détecté.                   | `Fix login bug` |

## Exemples de modèles {#template-examples}

| Modèle                                          | Résultat |
|---------------------------------------------------|--------|
| `%{source_branch}`                                | `my-feature-branch` |
| `%{title_from_branch}`                            | `My feature branch` |
| `%{first_commit_title}`                           | `Update README.md` |
| `Draft: %{title_from_branch}`                     | `Draft: My feature branch` |
| `[%{source_branch}] %{first_commit_title}`        | `[my-feature-branch] Update README.md` |
| `Resolve %{issue_id} "%{issue_title}"`            | `Resolve 123 "Fix login bug"` |

## Attribution du modèle de titre {#title-template-assignment}

Lorsque vous créez une merge request, GitLab attribue le titre dans cet ordre :

1. Si vous fournissez un titre, GitLab l'utilise.
1. Si un modèle de titre est configuré, GitLab utilise le modèle développé.
1. Si aucun modèle n'est défini, GitLab utilise le [comportement du titre par défaut](#default-title-behavior).

## Comportement du titre par défaut {#default-title-behavior}

Lorsqu'aucun modèle de titre n'est configuré et que vous ne fournissez pas de titre, GitLab génère le titre en vérifiant ces conditions dans l'ordre :

1. Si la merge request comporte un seul commit, le titre du commit.
1. Si la merge request comporte plusieurs commits, le titre du premier commit avec un message de commit multiligne.
1. Si le nom de la branche source commence par un IID de ticket suivi d'un tiret, par exemple `123-fix-typo`, le titre est `Resolve "<your_issue_title>"`.
1. Sinon, le nom de la branche source, avec les tirets et les underscores remplacés par des espaces.

Si la merge request n'a aucun commit, ou si vous la marquez comme brouillon, GitLab ajoute `Draft:` au début du titre.

## Sujets connexes {#related-topics}

- [Modèles de message de commit](commit_templates.md)
- [Créer une merge request](creating_merge_requests.md)
