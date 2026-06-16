---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépréciations de l'API REST"
description: "Liste des champs dépréciés et des changements cassants planifiés dans l'API REST GitLab."
---

Vous devez régulièrement passer en revue les dépréciations suivantes et effectuer les modifications recommandées. Ces dépréciations signalent souvent des fonctionnalités d'API améliorées et recommandent l'utilisation de nouveaux champs ou endpoints pour les fonctionnalités.

Bien que certaines dépréciations mentionnent une API REST v5, aucun développement d'API REST v5 n'est actif. GitLab n'effectuera pas ces modifications dans l'API REST v4, et [suit la gestion sémantique de version pour l'API REST](_index.md#versioning-and-deprecations).

## Endpoints d'API `geo_nodes` {#geo_nodes-api-endpoints}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/369140).

Les [endpoints d'API `geo_nodes`](../geo_nodes.md) sont dépréciés et sont remplacés par [`geo_sites`](../geo_sites.md). Cela fait partie du changement global sur [la façon de faire référence aux déploiements Geo](../../administration/geo/glossary.md). Les nœuds sont renommés en sites dans toute l'application. La fonctionnalité des deux endpoints reste la même.

## Champ d'API `merged_by` {#merged_by-api-field}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/350534).

Le champ `merged_by` dans l'[API des merge requests](../merge_requests.md#list-merge-requests) a été déprécié en faveur du champ `merge_user` qui identifie plus correctement qui a fusionné un merge request lors d'actions (défini sur la fusion automatique, ajout au merge train) autres qu'une simple fusion.

Les utilisateurs de l'API sont encouragés à utiliser le nouveau champ `merge_user` à la place. Le champ `merged_by` sera supprimé dans la v5 de l'API REST GitLab.

## Champ d'API `merge_status` {#merge_status-api-field}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/382032).

Le champ `merge_status` dans l'[API des merge requests](../merge_requests.md#merge-status) a été déprécié en faveur du champ `detailed_merge_status` qui identifie plus correctement tous les statuts potentiels dans lesquels un merge request peut se trouver. Les utilisateurs de l'API sont encouragés à utiliser le nouveau champ `detailed_merge_status` à la place. Le champ `merge_status` sera supprimé dans la v5 de l'API REST GitLab.

### Valeur nulle pour l'attribut `private_profile` dans l'API User {#null-value-for-private_profile-attribute-in-user-api}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/387005).

Lors de la création et de la mise à jour d'utilisateurs via l'API, `null` était une valeur valide pour l'attribut `private_profile`, qui était converti en interne en valeur par défaut. Dans la v5 de l'API REST GitLab, `null` ne sera plus une valeur valide pour ce paramètre, et la réponse sera un 400 si utilisé. Après cette modification, les seules valeurs valides seront `true` et `false`.

## Endpoint d'API pour les modifications d'un seul merge request {#single-merge-request-changes-api-endpoint}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/322117).

L'endpoint pour obtenir [les modifications d'un seul merge request](../merge_requests.md#retrieve-merge-request-changes) a été déprécié en faveur de l'endpoint [liste des diffs de merge request](../merge_requests.md#list-merge-request-diffs). Les utilisateurs de l'API sont encouragés à passer au nouvel endpoint de diffs à la place.

L'endpoint `changes from a single merge request` sera supprimé dans la v5 de l'API REST GitLab.

## Endpoint d'API Managed Licenses {#managed-licenses-api-endpoint}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/397067).

L'endpoint pour obtenir toutes les licences gérées pour un projet donné a été déprécié en faveur de la fonctionnalité [politique d'approbation de licence](../../user/compliance/license_approval_policies.md).

Les utilisateurs qui souhaitent continuer à appliquer des approbations basées sur les licences détectées sont encouragés à créer une nouvelle [politique d'approbation de licence](../../user/compliance/license_approval_policies.md) à la place.

L'endpoint `managed licenses` sera supprimé dans la v5 de l'API REST GitLab.

## Champs Approvers et Approver Group dans l'API d'approbation des merge requests {#approvers-and-approver-group-fields-in-merge-request-approval-api}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/353097).

L'endpoint pour obtenir la configuration des approbations d'un projet renvoie des tableaux vides pour `approvers` et `approval_groups`. Ces champs ont été dépréciés en faveur de l'endpoint pour [lister toutes les règles d'approbation](../merge_request_approvals.md#list-all-approval-rules-for-a-merge-request) d'un merge request. Les utilisateurs de l'API sont encouragés à passer à cet endpoint à la place.

Ces champs seront supprimés de l'endpoint `get configuration` dans la v5 de l'API REST GitLab.

## Utilisation de `active` par le runner remplacée par `paused` {#runner-usage-of-active-replaced-by-paused}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).

Les occurrences de l'identifiant `active` dans les endpoints d'API GraphQL de GitLab Runner seront renommées en `paused` dans GitLab 16.0.

- Dans la v4 de l'API REST, vous pouvez utiliser la propriété `paused` à la place de `active`
- Dans la v5 de l'API REST, cette modification affectera les endpoints prenant ou renvoyant la propriété `active`, tels que :
  - `GET /runners`
  - `GET /runners/all`
  - `GET /runners/:id` / `PUT /runners/:id`
  - `PUT --form "active=false" /runners/:runner_id`
  - `GET /projects/:id/runners` / `POST /projects/:id/runners`
  - `GET /groups/:id/runners`

La release 16.0 de GitLab Runner commencera à utiliser la propriété `paused` lors de l'enregistrement des runners.

## Le statut du runner ne renverra pas `paused` {#runner-status-will-not-return-paused}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/344648).

Dans une future v5 de l'API REST, les endpoints pour GitLab Runner ne renverront pas `paused` ni `active`.

Le statut d'un runner sera uniquement lié au statut de contact du runner, tel que : `online`, `offline`, ou `not_connected`. Le statut `paused` ou `active` n'apparaîtra plus.

Pour vérifier si un runner est `paused`, les utilisateurs de l'API sont conseillés de vérifier que l'attribut booléen `paused` est `true` à la place. Pour vérifier si un runner est `active`, vérifiez que `paused` est `false`.

## Le runner ne renverra pas `ip_address` {#runner-will-not-return-ip_address}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415159).

Dans GitLab 17.0, l'[API Runners](../runners.md) renverra `""` à la place de `ip_address` pour les runners. Dans la v5 de l'API REST, le champ sera supprimé.

## Champ d'API `default_branch_protection` {#default_branch_protection-api-field}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/408315).

Le champ `default_branch_protection` est déprécié dans GitLab 17.0 pour les API suivantes :

- [API New group](../groups.md#create-a-group).
- [API Update group](../groups.md#update-group-attributes).
- [API Application Settings](../settings.md#update-application-settings)

Vous devez utiliser le champ `default_branch_protection_defaults` à la place, qui offre un contrôle plus précis sur les protections de la branche par défaut.

Le champ `default_branch_protection` sera supprimé dans la v5 de l'API REST GitLab.

## Champ d'API `require_password_to_approve` {#require_password_to_approve-api-field}

Le champ `require_password_to_approve` a été déprécié dans GitLab 16.9. Utilisez le champ `require_reauthentication_to_approve` à la place. Si vous fournissez des valeurs pour les deux champs, le champ `require_reauthentication_to_approve` est prioritaire.

Le champ `require_password_to_approve` sera supprimé dans la v5 de l'API REST GitLab.

## Configuration du pull mirroring avec l'endpoint d'API Projects {#pull-mirroring-configuration-with-the-projects-api-endpoint}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/494294).

Dans GitLab 17.6, la [configuration du pull mirroring avec l'API Projects](../project_pull_mirroring.md#update-pull-mirroring-for-a-project-deprecated) est dépréciée. Elle est remplacée par une nouvelle configuration et un nouvel endpoint, [`projects/:id/mirror/pull`](../project_pull_mirroring.md#update-project-pull-mirroring-settings).

La configuration précédente utilisant l'API Projects sera supprimée dans la v5 de l'API REST GitLab.

## Paramètre `restrict_user_defined_variables` avec l'endpoint d'API Projects {#restrict_user_defined_variables-parameter-with-the-projects-api-endpoint}

Dans GitLab 17.7, le [paramètre `restrict_user_defined_variables` dans l'API Projects](../projects.md#update-a-project) est déprécié en faveur de l'utilisation exclusive de `ci_pipeline_variables_minimum_override_role`.

Pour reproduire le même comportement de `restrict_user_defined_variables: false`, définissez `ci_pipeline_variables_minimum_override_role` sur `developer`.

## Paramètre `namespace` dans les endpoints d'API d'import de projet {#namespace-parameter-in-project-import-api-endpoints}

Changement cassant. [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/511053).

Dans GitLab 18.7, le paramètre `namespace` dans l'[API d'import et d'export de projet](../project_import_export.md) est déprécié en faveur des paramètres `namespace_id` et `namespace_path`. Le paramètre `namespace` acceptait un ID ou un chemin, ce qui entraînait une ambiguïté lorsque les chemins d'espace de nommage ne contenaient que des chiffres.

À la place, vous devez utiliser :

- `namespace_id` pour spécifier un espace de nommage par son ID numérique.
- `namespace_path` pour spécifier un espace de nommage par son chemin.

Le paramètre `namespace` sera supprimé dans la v5 de l'API REST GitLab.
