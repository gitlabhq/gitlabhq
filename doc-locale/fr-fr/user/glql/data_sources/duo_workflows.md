---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Duo workflows
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/606576) dans GitLab 19.5 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment).
- La dimension `model` [introduite](https://gitlab.com/gitlab-org/glql/-/merge_requests/511) dans GitLab 19.5.
- Le filtre et la dimension `status`, ainsi que les métriques `flowTypesCount`, `returningUsersCount`, `joinedUsersCount`, `churnedUsersCount`, `previousPeriodUsersCount`, `createdMrCount`, `mergedMrCount` et `closedMrCount` [introduits](https://gitlab.com/gitlab-org/glql/-/merge_requests/514) dans GitLab 19.5.
- La dimension `userTier` et les filtres `flowTypesUsed` et `activeDays` [introduits](https://gitlab.com/gitlab-org/glql/-/merge_requests/516) dans GitLab 19.5.
- Le paramètre `status` sur `totalCount` [introduit](https://gitlab.com/gitlab-org/glql/-/merge_requests/527) dans GitLab 19.5.
- La dimension `group` [introduite](https://gitlab.com/gitlab-org/glql/-/merge_requests/530) dans GitLab 19.5.
- Les métriques `openMrCount` [introduites](https://gitlab.com/gitlab-org/glql/-/merge_requests/534) dans GitLab 19.5.
- La métrique `creditsPerMergedMrRatio` [introduite](https://gitlab.com/gitlab-org/glql/-/merge_requests/533) dans GitLab 19.5.
- Les opérateurs `!=` et `not in` sur les filtres `flowType`, `status` et `user` [introduits](https://gitlab.com/gitlab-org/glql/-/merge_requests/537) dans GitLab 19.5.
- La dimension `model` [modifiée](https://gitlab.com/gitlab-org/glql/-/merge_requests/539) pour afficher le nom du catalogue de modèles dans GitLab 19.5.

{{< /history >}}

> [!flag]
> Cette source de données lit depuis le moteur d'analyse des flows de la plateforme GitLab Duo Agent, qui est contrôlé par un [feature flag](../../../administration/feature_flags/_index.md) nommé `dap_impact_v1`. Le flag est désactivé par défaut. Jusqu'à ce qu'un administrateur l'active, les requêtes renvoient une erreur.

Cette source de données fournit des métriques agrégées sur les flows de la plateforme GitLab Duo Agent (également appelés Duo workflows) exécutés dans votre projet ou groupe, notamment le nombre de crédits utilisés.

## Modes autorisés {#allowed-modes}

- [`analytics`](../_index.md#analytics-mode)

## Portées autorisées {#allowed-scopes}

| Portée     | Description |
|-----------|-------------|
| `project` | Interroge les flows de la plateforme GitLab Duo Agent dans un projet spécifique. |
| `group`   | Interroge les flows de la plateforme GitLab Duo Agent dans tous les projets d'un groupe, y compris les sous-groupes. |

Pour agréger les Duo workflows GitLab sur plusieurs groupes ou projets, utilisez une liste avec l'opérateur `in`. Pour plus d'informations, consultez [plusieurs groupes et projets](_index.md#multiple-groups-and-projects).

## Champs de requête {#query-fields}

Utilisez ces champs dans le paramètre `query` pour filtrer vos résultats.

| Champ                               | Nom (et alias)                              | Opérateurs                 |
| ----------------------------------- | --------------------------------------------- | ------------------------- |
| [Jours actifs](#active-days)         | `activeDays`                                  | `=`, `>`, `<`, `>=`, `<=` |
| [Créé](#created)                 | `created` (`opened`, `openedAt`, `createdAt`) | `=`, `>`, `<`, `>=`, `<=` |
| [Type de flow](#flow-type)             | `flowType`                                    | `=`, `!=`, `in`, `not in` |
| [Types de flows utilisés](#flow-types-used) | `flowTypesUsed`                               | `=`, `>`, `<`, `>=`, `<=` |
| [Statut](#status)                   | `status`                                      | `=`, `!=`, `in`, `not in` |
| [Utilisateur](#user)                       | `user`                                        | `=`, `!=`, `in`, `not in` |

### Jours actifs {#active-days}

**Description** : filtre les flows selon le nombre de jours distincts où leur utilisateur a créé des flows au cours de la période sélectionnée. `activeDays = 1` correspond aux utilisateurs actifs exactement un jour.

**Types de valeurs autorisés** : `Number`

**Notes** :

- Le comptage couvre l'ensemble de la période sélectionnée, par utilisateur.
- Vous pouvez combiner deux opérateurs de plage pour une fenêtre, par exemple `activeDays >= 2 and activeDays <= 5`, mais pas `=` avec une autre comparaison sur le même champ.

### Créé {#created}

**Description** : filtre les flows par date de création. Utilisez plusieurs conditions `created` pour définir une période spécifiée.

**Types de valeurs autorisés** :

- `AbsoluteDate` (au format `YYYY-MM-DD`)
- `RelativeDate` (au format `<sign><digit><unit>`, où le signe est `+`, `-`, ou omis, le chiffre est un entier, et `unit` est l'un de `d` (jours), `w` (semaines), `m` (mois) ou `y` (années))

**Notes** :

- Pour l'opérateur `=`, GLQL prend en compte la plage horaire de 00:00 à 23:59 dans le fuseau horaire de l'utilisateur.

### Type de flow {#flow-type}

**Description** : filtre les flows par type. Par exemple, `software_development` ou `code_review/v1`.

**Types de valeurs autorisés** :

- `String`
- `List` (utilisez l'opérateur `in` ou `not in` pour plusieurs valeurs)

### Types de flows utilisés {#flow-types-used}

**Description** : filtre les flows selon le nombre de types de flows distincts exécutés par leur utilisateur au cours de la période sélectionnée. `flowTypesUsed >= 2` correspond aux utilisateurs ayant utilisé deux types de flows ou plus.

**Types de valeurs autorisés** : `Number`

**Notes** :

- Le comptage couvre l'ensemble de la période sélectionnée, par utilisateur.
- La même règle de combinaison s'applique : utilisez deux opérateurs de plage pour une fenêtre, mais pas `=` avec une autre comparaison sur le même champ.

### Statut {#status}

**Description** : filtre les flows par statut de cycle de vie.

**Types de valeurs autorisés** :

- `Enum`, l'un de `created`, `running`, `paused`, `finished`, `failed`, `stopped`, `input_required`, `plan_approval_required` ou `tool_call_approval_required`
- `List` (utilisez l'opérateur `in` ou `not in` pour plusieurs valeurs)

**Notes** :

- Les trois statuts `*_required` sont des flows en attente d'une action de l'utilisateur, distincts de `paused`.
- Les statuts sont mis en correspondance sans tenir compte de la casse. D'autres orthographes, comme `completed` ou `aborted`, ne sont pas acceptées.

### Utilisateur {#user}

**Description** : filtre par l'utilisateur qui a exécuté le flow.

**Types de valeurs autorisés** :

- `Number` (identifiant utilisateur)
- `List` (utilisez l'opérateur `in` ou `not in` pour plusieurs identifiants utilisateur)

> [!note]
> La prise en charge du filtrage par nom d'utilisateur est suivie dans le [ticket 599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750).

## Dimensions {#dimensions}

| Dimension | Nom       | Description |
| --------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Créé   | `created`  | Regrouper par date. Accepte un [paramètre `granularity`](../_index.md#field-parameters) de `daily`, `weekly`, `monthly`, ou un nombre de jours tel que `30d` (par défaut : `monthly`), et un `origin` facultatif. Par exemple, `created(weekly)` ou `created(granularity=30d, origin=2026-07-16)`. |
| Type de flow | `flowType` | Regrouper par type de flow. |
| Groupe     | `group`    | Regrouper par groupe. Accepte un paramètre `depth` compté depuis le groupe principal, de `1` à `99` (par défaut : `1`), ainsi `group` renvoie les groupes principaux et `group(depth=2)` leurs sous-groupes. Les flows au-delà de cette profondeur, ou dans un projet à cette profondeur plutôt que dans un sous-groupe (par exemple, un projet directement sous le groupe principal lorsque `depth=2`), n'ont pas de groupe, et le résultat peut contenir plusieurs lignes sans groupe. |
| Modèle     | `model`    | Regrouper par modèle utilisé par le flow (affiche le nom du catalogue de modèles). Les modèles absents du catalogue affichent leur identifiant brut. Les flows sans attribution de modèle n'ont pas de nom. Les lignes sont regroupées par l'identifiant de modèle indiqué par le flow, de sorte qu'un même nom du catalogue peut apparaître dans plusieurs lignes ou barres de graphique. |
| Projet   | `project`  | Regrouper par projet. Les flows non limités à un projet sont regroupés dans une seule ligne sans projet. |
| Statut    | `status`   | Regrouper par statut de flow. Les lignes sont triées dans l'ordre du cycle de vie, et non alphabétiquement. |
| Utilisateur      | `user`     | Regrouper par utilisateur (affiche l'avatar, le nom et le nom d'utilisateur). |
| Niveau d'utilisateur | `userTier` | Regrouper les utilisateurs par nombre de flows exécutés sur l'ensemble de la période sélectionnée, même lorsqu'une autre dimension telle que `created(weekly)` est également sélectionnée. Nécessite un paramètre `thresholds` : une liste de un à neuf entiers strictement croissants d'au moins `1`, sans valeur par défaut. Par exemple, `userTier(thresholds=[4, 25, 100])` renvoie `tier_0` (moins de 4 flows), `tier_1` (4 à 24), `tier_2` (25 à 99) et `tier_3` (100 ou plus). Un seuil unique peut être écrit sans crochets : `userTier(8)`. |

## Métriques {#metrics}

| Métrique                      | Nom                       | Description |
|-----------------------------|----------------------------|-------------|
| Nombre d'utilisateurs partis         | `churnedUsersCount`        | Nombre d'utilisateurs uniques ayant exécuté un flow au cours de la période précédente mais pas au cours de celle-ci. |
| Nombre max de MR fermées         | `closedMrCountMax`         | Nombre maximal de merge requests fermées créées par un seul flow. |
| Nombre moyen de MR fermées        | `closedMrCountMean`        | Nombre moyen de merge requests fermées créées par flow. |
| Nombre min de MR fermées         | `closedMrCountMin`         | Nombre minimal de merge requests fermées créées par un seul flow. |
| Quantile du nombre de MR fermées    | `closedMrCountQuantile`    | Merge requests fermées créées par flow à un quantile donné. Accepte un [paramètre `quantile`](../_index.md#field-parameters) compris entre `0.01` et `0.99` (par défaut : `0.5`). Par exemple, `closedMrCountQuantile(0.95)`. |
| Somme du nombre de MR fermées         | `closedMrCountSum`         | Total des merge requests fermées créées par tous les flows. |
| Nombre max de MR créées        | `createdMrCountMax`        | Nombre maximal de merge requests créées par un seul flow. |
| Nombre moyen de MR créées       | `createdMrCountMean`       | Nombre moyen de merge requests créées par flow. |
| Nombre min de MR créées        | `createdMrCountMin`        | Nombre minimal de merge requests créées par un seul flow. |
| Quantile du nombre de MR créées   | `createdMrCountQuantile`   | Merge requests créées par flow à un quantile donné. Accepte un [paramètre `quantile`](../_index.md#field-parameters) compris entre `0.01` et `0.99` (par défaut : `0.5`). Par exemple, `createdMrCountQuantile(0.95)`. |
| Somme du nombre de MR créées        | `createdMrCountSum`        | Total des merge requests créées par tous les flows. |
| Ratio crédits par MR fusionnée | `creditsPerMergedMrRatio`  | Crédits utilisés par merge request créée par un flow et ensuite fusionnée. Les crédits de chaque flow sont comptabilisés, y compris ceux des flows n'ayant créé aucune merge request. |
| Maximum de crédits utilisés            | `creditsUsedMax`           | Nombre maximal de crédits utilisés par un seul flow. |
| Moyenne de crédits utilisés           | `creditsUsedMean`          | Nombre moyen de crédits utilisés par flow. |
| Minimum de crédits utilisés            | `creditsUsedMin`           | Nombre minimal de crédits utilisés par un seul flow. |
| Quantile de crédits utilisés       | `creditsUsedQuantile`      | Crédits utilisés par flow à un quantile donné. Accepte un [paramètre `quantile`](../_index.md#field-parameters) compris entre `0.01` et `0.99` (par défaut : `0.5`). Par exemple, `creditsUsedQuantile(0.95)`. |
| Somme des crédits utilisés            | `creditsUsedSum`           | Total des crédits utilisés par tous les flows. |
| Nombre de types de flows            | `flowTypesCount`           | Nombre de types de flows uniques. |
| Nombre d'utilisateurs rejoints          | `joinedUsersCount`         | Nombre d'utilisateurs uniques ayant exécuté un flow au cours de cette période mais pas au cours de la précédente. |
| Nombre max de MR fusionnées         | `mergedMrCountMax`         | Nombre maximal de merge requests fusionnées créées par un seul flow. |
| Nombre moyen de MR fusionnées        | `mergedMrCountMean`        | Nombre moyen de merge requests fusionnées créées par flow. |
| Nombre min de MR fusionnées         | `mergedMrCountMin`         | Nombre minimal de merge requests fusionnées créées par un seul flow. |
| Quantile du nombre de MR fusionnées    | `mergedMrCountQuantile`    | Merge requests fusionnées créées par flow à un quantile donné. Accepte un [paramètre `quantile`](../_index.md#field-parameters) compris entre `0.01` et `0.99` (par défaut : `0.5`). Par exemple, `mergedMrCountQuantile(0.95)`. |
| Somme du nombre de MR fusionnées         | `mergedMrCountSum`         | Total des merge requests fusionnées créées par tous les flows. |
| Nombre max de MR ouvertes           | `openMrCountMax`           | Nombre maximal de merge requests ouvertes créées par un seul flow. |
| Nombre moyen de MR ouvertes          | `openMrCountMean`          | Nombre moyen de merge requests ouvertes créées par flow. |
| Nombre min de MR ouvertes           | `openMrCountMin`           | Nombre minimal de merge requests ouvertes créées par un seul flow. |
| Quantile du nombre de MR ouvertes      | `openMrCountQuantile`      | Merge requests ouvertes créées par flow à un quantile donné. Accepte un [paramètre `quantile`](../_index.md#field-parameters) compris entre `0.01` et `0.99` (par défaut : `0.5`). Par exemple, `openMrCountQuantile(0.95)`. |
| Somme du nombre de MR ouvertes           | `openMrCountSum`           | Total des merge requests ouvertes créées par tous les flows. |
| Nombre d'utilisateurs de la période précédente | `previousPeriodUsersCount` | Nombre d'utilisateurs uniques au cours de la période précédente. |
| Nombre de projets              | `projectsCount`            | Nombre de projets uniques. Les flows non limités à un projet ne sont pas comptabilisés ; la ligne correspondante affiche donc `0`. |
| Nombre d'utilisateurs récurrents       | `returningUsersCount`      | Nombre d'utilisateurs uniques ayant également exécuté un flow au cours de la période précédente. |
| Nombre total                 | `totalCount`               | Nombre total de flows, filtré optionnellement par statut. Accepte un paramètre `status` facultatif avec un ou plusieurs statuts de flow (les mêmes valeurs que le filtre `status`), par exemple `totalCount(status="finished")` ou `totalCount(status=["paused", "input_required"])`. Sans le paramètre, ou avec `status=[]`, tous les flows sont comptabilisés. |
| Nombre d'utilisateurs                 | `usersCount`               | Nombre d'utilisateurs uniques. |

> [!note]
> Les métriques de crédits, notamment `creditsPerMergedMrRatio`, nécessitent le rôle Propriétaire ou Responsable sécurité pour le groupe ou le projet, ou un [rôle personnalisé](../../custom_roles/abilities.md) avec la permission `read_agent_artifacts`. Pour les autres utilisateurs, ces métriques sont vides.

**Notes** :

- Les métriques `returningUsersCount`, `joinedUsersCount`, `churnedUsersCount` et `previousPeriodUsersCount` comparent chaque compartiment `created` avec le précédent ; elles ne sont donc valides que lorsque la dimension `created` est également sélectionnée. Un filtre `created` seul n'est pas suffisant.
- Les métriques `mergedMrCount`, `closedMrCount` et `openMrCount` comptabilisent les merge requests créées par un flow qui ont été ensuite fusionnées, fermées sans fusion, ou qui sont encore ouvertes. Elles peuvent être en décalage par rapport à l'état actuel de ces merge requests ; ainsi, une merge request fusionnée récemment peut encore être comptée comme ouverte.

## Champs de tri {#sort-fields}

Triez par n'importe quel champ inclus dans vos dimensions ou métriques sélectionnées. Pour plus d'informations, consultez [le tri en mode analytique](../_index.md#sorting).

## Exemples {#examples}

- Flows par type de flow pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflows by flow type (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: flowType as "Flow"
  metrics: totalCount as "Flows", usersCount as "Users", creditsUsedSum as "Credits"
  sort: totalCount desc
  ```
  ````

- Tendance d'utilisation mensuelle des crédits :

  ````yaml
  ```glql
  title: "Monthly Duo workflow credit usage trend"
  display: columnChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(monthly) as "Month"
  metrics: creditsUsedSum as "Credits used"
  sort: created asc
  ```
  ````

- Utilisation mensuelle des crédits hors flows de chat :

  ````yaml
  ```glql
  title: "Monthly Duo workflow credits, excluding chat"
  display: columnChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d and flowType not in ("chat", "agentic_chat/v1")
  dimensions: created(monthly) as "Month", flowType as "Flow"
  metrics: creditsUsedSum as "Credits used"
  sort: created asc
  ```
  ````

- Crédits par modèle pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflow credits by model (last 30 days)"
  display: barChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: model as "Model"
  metrics: creditsUsedSum as "Credits used"
  sort: creditsUsedSum desc
  ```
  ````

- Principaux utilisateurs par crédits pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Top users by Duo workflow credits (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: user as "User"
  metrics: totalCount as "Flows", creditsUsedSum as "Credits", creditsUsedMean as "Avg credits per flow"
  sort: creditsUsedSum desc
  limit: 10
  ```
  ````

- Flows par statut pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflows by status (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: status as "Status"
  metrics: totalCount as "Flows", createdMrCountSum as "MRs created", mergedMrCountSum as "MRs merged", openMrCountSum as "MRs open"
  sort: status asc
  ```
  ````

- Rétention hebdomadaire des utilisateurs :

  ````yaml
  ```glql
  title: "Weekly Duo workflow user retention"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(weekly) as "Week"
  metrics: usersCount as "Users", returningUsersCount as "Returning", joinedUsersCount as "Joined", churnedUsersCount as "Churned"
  sort: created desc
  ```
  ````

- Utilisateurs par niveau d'activité et type de flow pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflow users by activity tier (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: userTier(thresholds=[4, 25, 100]) as "Tier", flowType as "Flow"
  metrics: totalCount as "Flows", usersCount as "Users"
  sort: userTier asc
  ```
  ````

- Nombre de flows par statut côte à côte, pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflows by outcome (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  metrics: totalCount as "All", totalCount(status="finished") as "Completed", totalCount(status=["paused", "input_required"]) as "Waiting", totalCount(status="failed") as "Failed"
  ```
  ````

- Comparaison de groupes pour les 30 derniers jours :

  ````yaml
  ```glql
  title: "Duo workflow usage by subgroup (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: group(depth=2) as "Group"
  metrics: usersCount as "Users", creditsUsedSum as "Credits"
  sort: usersCount desc
  ```
  ````

- Utilisation globale sans regroupement :

  ````yaml
  ```glql
  title: "Duo workflow usage overview (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  metrics: totalCount as "Flows", usersCount as "Users", projectsCount as "Projects", creditsUsedQuantile(0.5) as "Median credits"
  ```
  ````
