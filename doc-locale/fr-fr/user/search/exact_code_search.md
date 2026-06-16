---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez la recherche exacte de code pour trouver du code dans un projet spécifique ou dans l'ensemble de GitLab."
title: Recherche exacte de code
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Disponibilité limitée

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) en tant que [bêta](../../policy/development_stages_support.md#beta) dans GitLab 15.9 [avec les feature flags](../../administration/feature_flags/_index.md) nommés `index_code_with_zoekt` et `search_code_with_zoekt`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) dans GitLab 16.6.
- La recherche de code globale [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) dans GitLab 16.11 [avec un flag](../../administration/feature_flags/_index.md) nommé `zoekt_cross_namespace_search`. Désactivé par défaut.
- Les feature flags `index_code_with_zoekt` et `search_code_with_zoekt` [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) dans GitLab 17.1.
- [Modifié](https://gitlab.com/groups/gitlab-org/-/epics/17918) de bêta à disponibilité limitée dans GitLab 18.6.
- Le feature flag `zoekt_cross_namespace_search` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) dans GitLab 18.7.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [disponibilité limitée](../../policy/development_stages_support.md#limited-availability). Pour plus d'informations, consultez l'[epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404). Donnez votre avis dans le [ticket 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920).

Avec la recherche exacte de code, vous pouvez utiliser les modes de correspondance exacte et d'expression régulière pour rechercher du code dans tout GitLab ou dans un projet spécifique.

La recherche exacte de code est propulsée par Zoekt et est utilisée par défaut dans les groupes où la fonctionnalité est activée.

## Utiliser la recherche exacte de code {#use-exact-code-search}

Prérequis :

- La recherche exacte de code doit être activée :
  - Pour GitLab.com, la recherche exacte de code est activée par défaut dans les abonnements payants.
  - Pour GitLab Self-Managed, un administrateur doit [installer Zoekt](../../integration/zoekt/_index.md#install-zoekt) et [activer la recherche exacte de code](../../integration/zoekt/_index.md#enable-exact-code-search).

Pour utiliser la recherche exacte de code :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à**.
1. Dans la zone de recherche, saisissez votre terme de recherche.
1. Dans la barre latérale gauche, sélectionnez **Code**.

Vous pouvez également utiliser la recherche exacte de code dans un projet ou un groupe.

## Portées disponibles {#available-scopes}

Les portées décrivent le type de données que vous recherchez. Les portées suivantes sont disponibles pour la recherche exacte de code :

| Portée | Global <sup>1</sup> <sup>2</sup> |    Groupe    | Projet     |
|-------|:--------------------------------:|:-----------:|:-----------:|
| Code  |           {{< no >}}             | {{< yes >}} | {{< yes >}} |

**Footnotes** :

1. Un administrateur peut [désactiver les portées de recherche globale](_index.md#disable-global-search-scopes). Dans GitLab 18.6 et versions antérieures, pour activer la recherche globale sur GitLab Self-Managed, un administrateur doit également activer le feature flag `zoekt_cross_namespace_search`.
1. Sur GitLab.com, la recherche globale n'est pas activée.

## API de recherche Zoekt {#zoekt-search-api}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666) dans GitLab 16.9 [avec un flag](../../administration/feature_flags/_index.md) nommé `zoekt_search_api`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17522) dans GitLab 18.4. Feature flag `zoekt_search_api` supprimé.

{{< /history >}}

Avec l'API de recherche Zoekt, vous pouvez utiliser l'API de recherche pour la recherche exacte de code. Pour utiliser la recherche avancée ou la recherche de base à la place, [spécifiez un type de recherche](_index.md#specify-a-search-type).

## Modes de recherche {#search-modes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/434417) dans GitLab 16.8 [avec un flag](../../administration/feature_flags/_index.md) nommé `zoekt_exact_search`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/436457) dans GitLab 17.3. Feature flag `zoekt_exact_search` supprimé.

{{< /history >}}

GitLab dispose de deux modes de recherche :

- **Mode de correspondance exacte** : renvoie les résultats qui correspondent exactement à la requête.
- **Mode d'expression régulière** : prend en charge les expressions régulières et booléennes.

Le mode de correspondance exacte est utilisé par défaut. Pour passer en mode d'expression régulière, à droite de la zone de recherche, sélectionnez **Utiliser une expression régulière** ({{< icon name="regular-expression" >}}).

### Syntax {#syntax}

{{< history >}}

- Le filtre `repo:` [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467) dans GitLab 19.0.

{{< /history >}}

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

Ce tableau présente quelques exemples de requêtes pour les modes de correspondance exacte et d'expression régulière.

| Requête                | Mode de correspondance exacte                                                                | Mode d'expression régulière                                                         |
|----------------------|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `"foo"`              | `"foo"`                                                                         | `foo`                                                                           |
| `foo file:^doc/`     | `foo` dans les répertoires qui commencent par `/doc`                                     | `foo` dans les répertoires qui commencent par `/doc`                                     |
| `"class foo"`        | `"class foo"`                                                                   | `class foo`                                                                     |
| `class foo`          | `class foo`                                                                     | `class` et `foo`                                                               |
| `foo or bar`         | `foo or bar`                                                                    | `foo` ou `bar`                                                                  |
| `class Foo`          | `class Foo` (sensible à la casse)                                                    | `class` (insensible à la casse) et `Foo` (sensible à la casse)                           |
| `class Foo case:yes` | `class Foo` (sensible à la casse)                                                    | `class` et `Foo` (tous deux sensibles à la casse)                                         |
| `foo -bar`           | `foo -bar`                                                                      | `foo` mais pas `bar`                                                             |
| `foo file:js`        | `foo` dans les fichiers dont le nom contient `js`                                     | `foo` dans les fichiers dont le nom contient `js`                                     |
| `foo -file:test`     | `foo` dans les fichiers dont le nom ne contient pas `test`                            | `foo` dans les fichiers dont le nom ne contient pas `test`                            |
| `foo lang:ruby`      | `foo` dans le code source Ruby                                                       | `foo` dans le code source Ruby                                                       |
| `foo file:\.js$`     | `foo` dans les fichiers dont le nom se termine par `.js`                                   | `foo` dans les fichiers dont le nom se termine par `.js`                                   |
| `foo.*bar`           | `foo.*bar` (littéral)                                                            | `foo.*bar` (expression régulière)                                                 |
| `sym:foo`            | `foo` dans les symboles tels que les noms de classes, de méthodes et de variables                         | `foo` dans les symboles tels que les noms de classes, de méthodes et de variables                         |
| `test repo:(?i)foo`  | `test` dans les projets dont le nom contient `foo` (insensible à la casse) | `test` dans les projets dont le nom contient `foo` (insensible à la casse) |

## Problèmes connus {#known-issues}

- Vous pouvez rechercher uniquement les fichiers de moins de 1 Mo avec moins de `20_000` trigrammes. Pour plus d'informations, consultez le [ticket 455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073).
- Vous pouvez utiliser la recherche exacte de code uniquement sur la branche par défaut d'un projet. Pour plus d'informations, consultez le [ticket 403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307).
- Plusieurs correspondances sur une même ligne sont comptées comme un seul résultat.
- Si vous rencontrez des résultats où les sauts de ligne ne s'affichent pas correctement, mettez à jour `gitlab-zoekt` vers la version 1.5.0 ou ultérieure.
