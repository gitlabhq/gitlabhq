---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Politiques d'exécution de scan"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Prise en charge des variables CI/CD personnalisées dans l'éditeur de politiques d'exécution de scan [introduite](https://gitlab.com/groups/gitlab-org/-/epics/9566) dans GitLab 16.2.
- Application des politiques d'exécution de scan sur les projets avec une configuration GitLab CI/CD existante [introduite](https://gitlab.com/groups/gitlab-org/-/epics/6880) dans GitLab 16.2 [avec un flag](../../../administration/feature_flags/_index.md) nommé `scan_execution_policy_pipelines`. Feature flag `scan_execution_policy_pipelines` supprimé dans GitLab 16.5.
- Remplacement des variables prédéfinies dans les politiques d'exécution de scan [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/440855) dans GitLab 16.10 [avec un flag](../../../administration/feature_flags/_index.md) nommé `allow_restricted_variables_at_policy_level`. Activé par défaut. Feature flag `allow_restricted_variables_at_policy_level` supprimé dans GitLab 17.5.

{{< /history >}}

Les politiques d'exécution de scan appliquent les scans de sécurité GitLab sur la base des [templates CI/CD de sécurité](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs) par défaut ou les plus récents. Vous pouvez déployer des politiques d'exécution de scan dans le cadre du pipeline ou selon une planification définie.

Les politiques d'exécution de scan appliquent des scans de sécurité sur tous les projets liés au projet de politique de sécurité. Pour les projets sans fichier `.gitlab-ci.yml`, ou les projets pour lesquels AutoDevOps est désactivé, les politiques de sécurité créent implicitement le fichier `.gitlab-ci.yml`. Le fichier `.gitlab-ci.yml` garantit que les politiques qui exécutent la détection des secrets, l'analyse statique ou d'autres scanners ne nécessitant pas de build dans le projet peuvent toujours s'exécuter et être appliquées.

Les politiques d'exécution de scan et les politiques d'exécution de pipeline peuvent toutes deux configurer des scans de sécurité GitLab sur plusieurs projets pour gérer la sécurité et la conformité. Les politiques d'exécution de scan sont plus rapides à configurer, mais ne sont pas personnalisables. Si l'un des cas suivants s'applique, utilisez plutôt les [politiques d'exécution de pipeline](pipeline_execution_policies.md) :

- Vous avez besoin de paramètres de configuration avancés.
- Vous souhaitez appliquer des jobs ou des scripts CI/CD personnalisés.
- Vous souhaitez activer des scans de sécurité tiers via un job CI/CD appliqué.

## Créer une politique d'exécution de scan {#create-a-scan-execution-policy}

Pour créer une politique d'exécution de scan, vous pouvez utiliser l'une des ressources suivantes :

- <i class="fa-youtube-play" aria-hidden="true"></i> Pour une vidéo de présentation, voir [How to set up Security Scan Policies in GitLab](https://youtu.be/ZBcqGmEwORA?si=aeT4EXtmHjosgjBY).
- <i class="fa-youtube-play" aria-hidden="true"></i> En savoir plus sur [l'application des politiques d'exécution de scan sur les projets sans configuration GitLab CI/CD](https://www.youtube.com/watch?v=sUfwQQ4-qHs).
- Pour les instructions sur la création de politiques d'exécution de scan, voir [tutoriel : configurer une politique d'exécution de scan](../../../tutorials/scan_execution_policy/_index.md)

## Restrictions {#restrictions}

- Vous pouvez attribuer un maximum de cinq règles à chaque politique.
- Vous pouvez attribuer un maximum de cinq politiques d'exécution de scan à chaque projet de politique de sécurité.
- Les fichiers YAML locaux du projet ne peuvent pas remplacer les politiques d'exécution de scan. Les politiques d'exécution de scan ont la priorité sur toutes les configurations définies pour un pipeline, même si vous utilisez le même nom de job dans la configuration CI/CD de votre projet.
- Les politiques planifiées (`type: schedule`) s'exécutent uniquement selon leur `cadence` planifié. La mise à jour d'une politique ne déclenche pas un scan immédiat.
- Les mises à jour de politique que vous effectuez directement dans les fichiers de configuration YAML (avec un commit ou un push plutôt que dans l'éditeur de politique) peuvent prendre jusqu'à 10 minutes pour se propager dans le système. (Voir le [ticket 512615](https://gitlab.com/gitlab-org/gitlab/-/issues/512615) pour les modifications proposées à cette limitation.)

## Étapes des jobs {#job-stages}

Les scans DAST s'exécutent toujours dans l'étape `dast`. Si l'étape `dast` n'existe pas, GitLab injecte une étape `dast` à la fin du pipeline.

Les jobs de politique pour tous les autres scans s'exécutent dans l'étape `test` du pipeline. Si vous supprimez l'étape `test` du pipeline par défaut, les jobs s'exécutent dans l'étape `scan-policies` à la place, selon ces règles :

- Si l'étape `scan-policies` n'existe pas encore, GitLab injecte l'étape dans le pipeline CI/CD au moment de l'évaluation.
- Si l'étape `build` existe, GitLab injecte `scan-policies` immédiatement après l'étape `build`.
- Si l'étape `build` n'existe pas, GitLab injecte `scan-policies` au début du pipeline.

Pour éviter les conflits de noms de jobs, un trait d'union et un numéro sont ajoutés au nom du job. Chaque numéro est une valeur unique pour chaque action de politique. Par exemple, `secret-detection` devient `secret-detection-1`.

## Éditeur de politiques d'exécution de scan {#scan-execution-policy-editor}

{{< history >}}

- `Merge Request Security Template` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `flexible_scan_execution`. Désactivé par défaut.
  - [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.3.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.4. Le feature flag `flexible_scan_execution` a été supprimé.

{{< /history >}}

Utilisez l'éditeur de politiques d'exécution de scan pour créer ou modifier une politique d'exécution de scan.

Prérequis :

- Par défaut, seuls les propriétaires de groupes, sous-groupes ou projets disposent des [permissions](../../permissions.md#project-application-security) requises pour créer ou attribuer un projet de politique de sécurité. Vous pouvez également créer un rôle personnalisé avec la permission de [gérer les liens de politique de sécurité](../../custom_roles/abilities.md#security-policy-management).

Lorsque vous créez vos premières politiques d'exécution de scan, choisissez parmi ces modèles pour les cas d'utilisation courants :

- Sécurité des merge requests
  - Cas d'utilisation : Vous souhaitez que les scans de sécurité s'exécutent uniquement lors de la création de merge requests, pas à chaque commit.
  - Quand l'utiliser : Pour les projets utilisant des pipelines de merge request qui nécessitent l'exécution de scans de sécurité sur des branches source ciblant les branches par défaut ou protégées.
  - Idéal pour : L'alignement avec les politiques d'approbation des merge requests et la réduction des coûts d'infrastructure en évitant les scans sur chaque branche.
  - Sources du pipeline : Principalement les pipelines de merge request.
- Scans programmés
  - Cas d'utilisation : Vous souhaitez que les scans de sécurité s'exécutent automatiquement selon une planification (quotidienne ou hebdomadaire, par exemple), indépendamment des modifications de code.
  - Quand l'utiliser : Pour les scans de sécurité selon une cadence régulière, indépendamment de l'activité de développement.
  - Idéal pour : Les exigences de conformité, la surveillance de sécurité de base ou les projets avec des commits peu fréquents.
  - Sources du pipeline : Pipelines planifiés.
- Sécurité des releases
  - Cas d'utilisation : Vous souhaitez que les scans de sécurité s'exécutent sur toutes les modifications apportées à votre branche `main` ou de release.
  - Quand l'utiliser : Pour les projets nécessitant un scan complet avant les releases, ou sur les branches protégées.
  - Idéal pour : Les workflows conditionnés aux releases, les déploiements en production ou les environnements à haute sécurité.
  - Sources du pipeline : Pipelines push vers les branches protégées, pipelines de release.

Si les modèles disponibles ne répondent pas à vos besoins, ou si vous avez besoin de politiques d'exécution de scan plus personnalisées, vous pouvez :

- Sélectionner l'option **Personnalisé** et créer votre propre politique d'exécution de scan avec des exigences personnalisées.
- Accéder à des options plus personnalisables pour l'application des scans de sécurité et de la CI en utilisant les [politiques d'exécution de pipeline](pipeline_execution_policies.md).

Une fois votre politique complète, enregistrez-la en sélectionnant **Configurer avec une requête de fusion** en bas de l'éditeur. Vous êtes redirigé vers la merge request sur le projet de politique de sécurité configuré du projet. Si aucun projet de politique de sécurité n'est lié à votre projet, GitLab en crée un automatiquement. Vous pouvez supprimer des politiques existantes depuis l'interface de l'éditeur en sélectionnant **Supprimer une politique** en bas de l'éditeur. Cette action crée une merge request pour supprimer la politique de votre fichier `policy.yml`.

La plupart des modifications de politique prennent effet dès que la merge request est fusionnée. Toute modification commitée directement sur la branche par défaut plutôt que via une merge request peut nécessiter jusqu'à 10 minutes avant que les modifications de politique prennent effet.

![Mode règle de l'éditeur de politiques d'exécution de scan](img/scan_execution_policy_rule_mode_v17_5.png)

> [!note]
> Pour les politiques d'exécution DAST, la manière dont vous appliquez les profils de site et de scanner dans l'éditeur en mode règle dépend de l'endroit où la politique est définie :
>
> - Pour les politiques dans les projets, dans l'éditeur en mode règle, choisissez parmi une liste de profils déjà définis dans le projet.
> - Pour les politiques dans les groupes, vous devez saisir les noms des profils à utiliser. Pour éviter les erreurs de pipeline, des profils avec des noms correspondants doivent exister dans tous les projets du groupe.

## Schéma des politiques d'exécution de scan {#scan-execution-policies-schema}

Une configuration YAML avec des politiques d'exécution de scan consiste en un tableau d'objets correspondant au schéma de politique d'exécution de scan. Les objets sont imbriqués sous la clé `scan_execution_policy`. Vous pouvez configurer un maximum de cinq politiques sous la clé `scan_execution_policy`. Toutes les autres politiques configurées après les cinq premières ne sont pas appliquées.

Lorsque vous enregistrez une nouvelle politique, GitLab valide le contenu de la politique par rapport à [ce schéma JSON](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json). Si vous n'êtes pas familier avec les [schémas JSON](https://json-schema.org/), les sections et tableaux suivants constituent une alternative.

| Champ | Type | Obligatoire | Valeurs possibles | Description |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | `array` de politique d'exécution de scan | true |  | Liste des politiques d'exécution de scan (maximum 5) |

## Schéma de politique d'exécution de scan {#scan-execution-policy-schema}

{{< history >}}

- Limite d'actions par politique [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/472213) dans GitLab 17.4 [avec des flags](../../../administration/feature_flags/_index.md) nommés `scan_execution_policy_action_limit` (pour les projets) et `scan_execution_policy_action_limit_group` (pour les groupes). Désactivé par défaut.
- Limite d'actions par politique [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/535605) dans GitLab 18.0. Feature flags `scan_execution_policy_action_limit` (pour les projets) et `scan_execution_policy_action_limit_group` (pour les groupes) supprimés.

{{< /history >}}

| Champ          | Type                                         | Obligatoire | Description |
|----------------|----------------------------------------------|----------|-------------|
| `name`         | `string`                                     | true     | Nom de la politique. Maximum 255 caractères. |
| `description`  | `string`                                     | false    | Description de la politique. |
| `enabled`      | `boolean`                                    | true     | Flag pour activer (`true`) ou désactiver (`false`) la politique. |
| `rules`        | `array` de règles                             | true     | Liste des règles que la politique applique. |
| `actions`      | `array` d'actions                           | true     | Liste des actions que la politique applique. Limité à un maximum de 10 dans GitLab 18.0 et versions ultérieures. |
| `policy_scope` | `object` de [`policy_scope`](_index.md#configure-the-policy-scope) | false    | Définit la portée de la politique en fonction des projets, groupes ou labels de framework de conformité que vous spécifiez. |
| `skip_ci`      | `object` de [`skip_ci`](#skip_ci-type) | false | Définit si les utilisateurs peuvent appliquer la directive `skip-ci`. |
| `no_pipeline`  | `object` de [`no_pipeline`](#no_pipeline-type) | false | Définit si les utilisateurs peuvent appliquer la directive `no_pipeline`. |

### Type `skip_ci` {#skip_ci-type}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/482952) dans GitLab 17.9.

{{< /history >}}

Les politiques d'exécution de scan offrent un contrôle sur les utilisateurs autorisés à utiliser la directive `[skip ci]`. Vous pouvez spécifier certains utilisateurs ou comptes de service autorisés à utiliser `[skip ci]` tout en garantissant que les vérifications critiques de sécurité et de conformité sont effectuées.

Utilisez le mot-clé `skip_ci` pour spécifier si les utilisateurs sont autorisés à appliquer la directive `skip_ci` pour ignorer les pipelines. Lorsque le mot-clé n'est pas spécifié, la directive `skip_ci` est ignorée, empêchant tous les utilisateurs de contourner les politiques d'exécution de pipeline.

| Champ                   | Type     | Valeurs possibles          | Description |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`, `false` | Flag pour autoriser (`true`) ou empêcher (`false`) l'utilisation de la directive `skip-ci` pour les pipelines avec des politiques d'exécution de pipeline appliquées. |
| `allowlist`             | `object` | `users` | Spécifiez les utilisateurs toujours autorisés à utiliser la directive `skip-ci`, indépendamment du flag `allowed`. Utilisez `users:` suivi d'un tableau d'objets avec des clés `id` représentant les identifiants des utilisateurs. |

> [!note]
> Les politiques d'exécution de scan ayant le type de règle `schedule` ignorent toujours l'option `skip_ci`. Les scans planifiés s'exécutent aux heures configurées, indépendamment du fait que `[skip ci]` (ou l'une de ses variantes) apparaisse dans le dernier message de commit. Cela garantit que les scans de sécurité s'effectuent selon un calendrier prévisible, même lorsque les pipelines CI/CD sont ignorés.

### Type `no_pipeline` {#no_pipeline-type}

Les politiques d'exécution de scan offrent un contrôle sur les utilisateurs autorisés à utiliser la directive `[no_pipeline]`. Vous pouvez spécifier certains utilisateurs ou comptes de service autorisés à utiliser `[no_pipeline]` tout en garantissant que les vérifications critiques de sécurité et de conformité sont effectuées.

Utilisez le mot-clé `no_pipeline` pour spécifier si les utilisateurs sont autorisés à appliquer la directive `no_pipeline` pour ne pas créer de pipeline lors d'un push. Lorsque le mot-clé n'est pas spécifié, la directive `no_pipeline` est ignorée, empêchant tous les utilisateurs de contourner les politiques d'exécution de pipeline.

| Champ                   | Type     | Valeurs possibles          | Description |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`, `false` | Flag pour autoriser (`true`) ou empêcher (`false`) l'utilisation de la directive `no_pipeline` pour les pipelines avec des politiques d'exécution de pipeline appliquées. |
| `allowlist`             | `object` | `users` | Spécifiez les utilisateurs toujours autorisés à utiliser la directive `no_pipeline`, indépendamment du flag `allowed`. Utilisez `users:` suivi d'un tableau d'objets avec des clés `id` représentant les identifiants des utilisateurs. |

> [!note]
> Les politiques d'exécution de scan ayant le type de règle `schedule` ignorent toujours l'option `no_pipeline`. Les scans planifiés s'exécutent aux heures configurées, indépendamment du fait que `[no_pipeline]` (ou l'une de ses variantes) apparaisse dans le dernier message de commit. Cela garantit que les scans de sécurité s'effectuent selon un calendrier prévisible, même lorsque les pipelines CI/CD ne sont pas créés.

## Type de règle `pipeline` {#pipeline-rule-type}

{{< history >}}

- Le champ `branch_type` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) dans GitLab 16.1 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_type`.
  - Généralement disponible dans GitLab 16.2. Le feature flag `security_policies_branch_type` a été supprimé.
- Le champ `branch_exceptions` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) dans GitLab 16.3 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_exceptions`.
  - Généralement disponible dans GitLab 16.5. Le feature flag `security_policies_branch_exceptions` a été supprimé.
- Le champ `pipeline_sources` et les options `branch_type` `target_default` et `target_protected` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `flexible_scan_execution`.
  - [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.3.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) dans GitLab 18.4. Le feature flag `flexible_scan_execution` a été supprimé.

{{< /history >}}

Cette règle applique les actions définies chaque fois que le pipeline s'exécute pour une branche sélectionnée.

| Champ | Type | Obligatoire | Valeurs possibles | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `pipeline` | Type de la règle. |
| `branches` <sup>1</sup> | `array` de `string` | true si le champ `branch_type` n'existe pas | `*` ou le nom de la branche | La branche à laquelle s'applique la politique donnée (prend en charge les caractères génériques). Pour la compatibilité avec les politiques d'approbation des merge requests, vous devez cibler toutes les branches pour inclure les scans dans la branche de fonctionnalité et la branche par défaut |
| `branch_type` <sup>1</sup> | `string` | true si le champ `branches` n'existe pas | `default`, `protected`, `all`, `target_default` <sup>2</sup>, ou `target_protected` <sup>2</sup> | Les types de branches auxquels s'applique la politique donnée. |
| `branch_exceptions` | `array` de `string` | false |  Noms des branches | Branches à exclure de cette règle. |
| `pipeline_sources` <sup>2</sup> | `array` de `string` | false | `api`, `chat`, `external`, `external_pull_request_event`, `merge_request_event` <sup>3</sup>, `pipeline`, `push` <sup>3</sup>, `schedule`, `trigger`, `unknown`, `web` | La source du pipeline qui détermine le moment où le job d'exécution de scan se déclenche. Consultez la [documentation](../../../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable) pour plus d'informations. |

1. Vous devez spécifier soit `branches` soit `branch_type`, mais pas les deux.
1. Certaines options ne sont disponibles qu'avec le feature flag `flexible_scan_execution` activé. Consultez l'historique pour plus de détails.
1. Lorsque les options `target_default` ou `target_protected` de `branch_type` sont spécifiées, le champ `pipeline_sources` ne prend en charge que les champs `merge_request_event` et `push`.

## Type de règle `schedule` {#schedule-rule-type}

{{< history >}}

- Nouveau champ `branch_type` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) dans GitLab 16.1 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_type`.
  - Généralement disponible dans GitLab 16.2. Feature flag supprimé.
- Nouveau champ `branch_exceptions` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) dans GitLab 16.3 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_exceptions`.
  - Généralement disponible dans GitLab 16.5. Feature flag supprimé.
- Nouveau worker `scan_execution_pipeline_worker` pour les scans planifiés afin de créer des pipelines :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147691) dans GitLab 16.11 [avec un flag](../../../administration/feature_flags/_index.md).
  - [Activé](https://gitlab.com/gitlab-org/gitlab/-/issues/451890) sur GitLab.com dans GitLab 17.5.
  - [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/451890) dans GitLab 17.6. Le feature flag `scan_execution_pipeline_worker` a été supprimé.
- Nouveau paramètre d'application `security_policy_scheduled_scans_max_concurrency` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152855) dans GitLab 17.1. La limite de concurrence s'applique lorsque `scan_execution_pipeline_worker` et `scan_execution_pipeline_concurrency_control` sont tous les deux activés.
  - [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178892) d'un nouveau paramètre d'application `security_policy_scheduled_scans_max_concurrency` dans GitLab 17.11.
- Limite de concurrence pour les jobs planifiés d'exécution de scan :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158636) dans GitLab 17.3 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `scan_execution_pipeline_concurrency_control`.
  - [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/463802) dans GitLab 17.9. Le feature flag `scan_execution_pipeline_concurrency_control` a été supprimé.

{{< /history >}}

> [!warning]
> Dans GitLab 16.1 et versions antérieures, vous ne devez pas utiliser le [transfert direct](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer) avec des politiques d'exécution de scan planifiées. Si vous devez utiliser le transfert direct, mettez d'abord à niveau vers GitLab 16.2 et assurez-vous que les bots de politique de sécurité sont activés dans les projets que vous appliquez.

Utilisez le type de règle `schedule` pour exécuter des scanners de sécurité selon une planification.

Un pipeline planifié :

- Exécute uniquement les scanners définis dans la politique, et non les jobs définis dans le fichier `.gitlab-ci.yml` du projet.
- S'exécute selon la planification définie dans le champ `cadence`.
- S'exécute sous un compte utilisateur `security_policy_bot` dans le projet, avec le rôle Invité et les permissions pour créer des pipelines et lire le contenu du dépôt depuis un job CI/CD. Ce compte est créé lorsque la politique est liée à un groupe ou à un projet.
- Sur GitLab.com, seules les 10 premières règles `schedule` d'une politique d'exécution de scan sont appliquées. Les règles dépassant la limite n'ont aucun effet.

| Champ      | Type | Obligatoire | Valeurs possibles | Description |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | true | `schedule` | Type de la règle. |
| `branches` <sup>1</sup> | `array` de `string` | true si le champ `branch_type` ou `agents` n'existe pas | `*` ou le nom de la branche | La branche à laquelle s'applique la politique donnée (prend en charge les caractères génériques). |
| `branch_type` <sup>1</sup> | `string` | true si le champ `branches` ou `agents` n'existe pas | `default`, `protected` ou `all` | Les types de branches auxquels s'applique la politique donnée. |
| `branch_exceptions` | `array` de `string` | false |  Noms des branches | Branches à exclure de cette règle. |
| `cadence`  | `string` | true | Expression cron avec des options limitées. Par exemple, `0 0 * * *` crée une planification pour s'exécuter chaque jour à minuit (00 h 00). | Chaîne séparée par des espaces contenant cinq champs représentant l'heure planifiée. |
| `timezone` | `string` | false | Identifiant de fuseau horaire (par exemple, `America/New_York`) | Fuseau horaire à appliquer à la cadence. La valeur doit être un identifiant de base de données de fuseaux horaires IANA. |
| `time_window` | `object` | false |  | Paramètres de distribution et de durée pour les scans de sécurité planifiés. |
| `agents` <sup>1</sup>   | `object` | true si le champ `branch_type` ou `branches` n'existe pas  |  | Le nom des [agents GitLab pour Kubernetes](../../clusters/agent/_index.md) où [le scan de conteneurs opérationnel](../../clusters/agent/vulnerabilities.md) s'exécute. La clé d'objet est le nom de l'agent Kubernetes configuré pour votre projet dans GitLab. |

1. Vous devez spécifier uniquement l'un des suivants : `branches`, `branch_type` ou `agents`.

### Cadence {#cadence}

Utilisez le champ `cadence` pour planifier le moment où vous souhaitez que les actions de la politique s'exécutent. Le champ `cadence` utilise la [syntaxe cron](../../../topics/cron/_index.md), mais avec certaines restrictions :

- Seuls les types de syntaxe cron suivants sont pris en charge :
  - Une cadence quotidienne d'une fois par heure à une heure spécifiée, par exemple : `0 18 * * *`
  - Une cadence hebdomadaire d'une fois par semaine un jour spécifié et à une heure spécifiée, par exemple : `0 13 * * 0`
- L'utilisation de la virgule (,), des traits d'union (-) ou des opérateurs de pas (/) n'est pas prise en charge pour les minutes et les heures. Tout pipeline planifié utilisant ces caractères est ignoré.

Tenez compte des points suivants lors du choix d'une valeur pour le champ `cadence` :

- La synchronisation est basée sur UTC pour GitLab.com et GitLab Dedicated, et sur l'heure système de l'hôte GitLab pour GitLab Self-Managed. Lors du test de nouvelles politiques, les pipelines peuvent sembler s'exécuter à des horaires incorrects car ils sont planifiés dans le fuseau horaire de votre serveur et non dans votre fuseau horaire local.
- Un pipeline planifié ne démarre pas tant que les ressources nécessaires à sa création ne sont pas disponibles. En d'autres termes, le pipeline peut ne pas démarrer précisément à l'heure spécifiée dans la politique.

Lors de l'utilisation du type de règle `schedule` avec le champ `agents` :

- L'agent GitLab pour Kubernetes vérifie toutes les 30 secondes s'il existe une politique applicable. Lorsque l'agent trouve une politique, les scans s'exécutent selon la `cadence` définie.
- L'expression cron est évaluée en utilisant l'heure système du pod de l'agent Kubernetes.

Lors de l'utilisation du type de règle `schedule` avec le champ `branches` :

- Le worker cron s'exécute à des intervalles de 15 minutes et démarre tous les pipelines dont l'exécution était planifiée au cours des 15 minutes précédentes. Par conséquent, les pipelines planifiés peuvent s'exécuter avec un décalage pouvant atteindre 15 minutes.
- Si une politique est appliquée sur un grand nombre de projets ou de branches, la politique est traitée par lots et peut prendre un certain temps pour créer tous les pipelines.

![Diagramme montrant comment les scans de sécurité planifiés sont traités et exécutés avec des délais potentiels.](img/scheduled_scan_execution_policies_diagram_v18_04.png)

### Schéma `agent` {#agent-schema}

Utilisez ce schéma pour définir les objets `agents` dans le [type de règle `schedule`](#schedule-rule-type).

| Champ        | Type                | Obligatoire | Description |
|--------------|---------------------|----------|-------------|
| `namespaces` | `array` de `string` | true | L'espace de nommage qui est scanné. Si vide, tous les espaces de nommage sont scannés. |

#### Exemple `agent` {#agent-example}

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

Les clés d'une règle de planification sont :

- `cadence` (obligatoire) : une [expression Cron](../../../topics/cron/_index.md) indiquant quand les scans s'exécutent.
- `agents:<agent-name>` (obligatoire) : Le nom de l'agent à utiliser pour le scan.
- `agents:<agent-name>:namespaces` (facultatif) : Les espaces de nommage Kubernetes à scanner. Si omis, tous les espaces de nommage sont scannés.

### Schéma `time_window` {#time_window-schema}

Définissez la distribution des scans planifiés dans le temps avec l'objet `time_window` dans le [type de règle `schedule`](#schedule-rule-type). Vous pouvez configurer `time_window` uniquement en mode YAML de l'éditeur de politique.

| Champ          | Type      | Obligatoire | Description                                                                                                                                                                          |
|----------------|-----------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `distribution` | `string`  | true     | Modèle de distribution pour les scans planifiés. Ne prend en charge que `random`, où les scans sont distribués aléatoirement dans l'intervalle défini par la clé `value` de `time_window`. |
| `value`        | `integer` | true     | La fenêtre temporelle en secondes pendant laquelle les scans planifiés doivent s'exécuter. Saisissez une valeur comprise entre 3600 (1 heure) et 2629746 (environ 30 jours).                                               |

#### Exemple `time_window` {#time_window-example}

```yaml
- name: Enforce container scanning with a time window of 1 hour
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    time_window:
      value: 3600
      distribution: random
  actions:
  - scan: container_scanning
```

### Optimiser les pipelines planifiés pour les projets à grande échelle {#optimize-scheduled-pipelines-for-projects-at-scale}

Lorsqu'une politique applique des pipelines planifiés sur plusieurs projets et branches, les pipelines s'exécutent simultanément. La première exécution d'un pipeline planifié dans chaque projet crée un utilisateur bot de sécurité chargé d'exécuter les planifications pour ce projet.

Pour optimiser les performances des projets à grande échelle :

- Déployez progressivement les politiques d'exécution de scan planifiées, en commençant par un sous-ensemble de projets. Vous pouvez exploiter les portées de politique de sécurité pour cibler des groupes, des projets ou des projets contenant un label de framework de conformité donné.
- Vous pouvez configurer la politique pour exécuter les planifications sur des runners avec un `tag` spécifié. Envisagez de configurer un runner dédié dans chaque projet pour gérer les planifications appliquées par une politique afin de réduire l'impact sur les autres runners.
- Testez votre implémentation dans un environnement de staging ou inférieur avant de déployer en production. Surveillez les performances et ajustez votre plan de déploiement en fonction des résultats.

### Configuration de la durée maximale de planification pour les politiques d'exécution de scan planifiées {#configuring-the-maximum-scheduling-timespan-for-scheduled-scan-execution-policies}

Les politiques d'exécution de scan planifiées prennent en charge la planification mensuelle en utilisant le champ `cadence` avec des expressions cron. Vous pouvez configurer `time_window` jusqu'à 2629746 secondes (environ 30 jours) pour distribuer aléatoirement les scans sur cette période.

Par exemple, pour planifier des scans mensuels avec une fenêtre de distribution de 30 jours :

```yaml
rules:
  - type: schedule
    cadence: '0 0 1 * *'  # Run on the first day of each month
    time_window:
      value: 2592000  # 30 days in seconds
      distribution: random
```

#### Comprendre les scans planifiés lors des interruptions d'instance {#understanding-scheduled-scans-during-instance-downtimes}

Les scans planifiés conservent la trace de leur prochaine heure d'exécution. Après un scan réussi, le système met à jour la date à laquelle le prochain scan doit s'exécuter. Si l'instance GitLab est indisponible pendant une heure de scan planifiée (en raison d'une maintenance, d'une panne ou d'un redémarrage), le système identifie les scans qui auraient dû déjà s'exécuter mais ne l'ont pas fait, et crée des pipelines lorsque l'instance redevient disponible.

#### Suppression de projets avec des scans planifiés {#deleting-projects-with-scheduled-scans}

Lorsque vous supprimez un projet, tous les scans planifiés associés sont également supprimés. Aucun pipeline ne s'exécute pour les projets supprimés.

#### Annulation d'un scan planifié en cours d'exécution {#canceling-a-running-scheduled-scan}

Pour annuler un scan planifié, vous disposez de deux options :

- Annuler des pipelines individuels : Si vous disposez des permissions nécessaires pour annuler des jobs dans le projet, vous pouvez annuler les pipelines en cours directement depuis la vue des pipelines.
- **Désactiver la politique** : Définissez `enabled: false` dans l'éditeur de politique pour désactiver la politique d'exécution de scan. Les scans déjà en cours d'exécution ou dont l'exécution est planifiée dans les 15 prochaines minutes (environ) peuvent tout de même s'exécuter.

#### Recommandations pour les déploiements à grande échelle {#recommendations-for-large-scale-deployments}

Lorsque vous déployez des politiques d'exécution de scan planifiées sur de nombreux projets, tenez compte des recommandations suivantes :

- Utiliser des déploiements progressifs : Commencez par un petit sous-ensemble de projets et ajoutez progressivement davantage de projets. Utilisez les [labels de framework de conformité](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project) pour restreindre les politiques à des groupes de projets spécifiques.
- Configurer `time_window` : Définissez toujours le paramètre `time_window` dans vos politiques planifiées. Sans cela, tous les pipelines sont planifiés au même moment, ce qui peut entraîner des problèmes de performances et une contention des ressources.
- Tester en staging : Validez votre configuration de politique dans un environnement de staging ou inférieur avant de déployer en production. Surveillez les performances et ajustez en fonction des résultats.
- Tenir compte de la capacité des runners : L'impact sur les runners dépend de votre configuration de politique, de la disponibilité des runners et du déploiement de l'instance GitLab. Configurez les politiques pour utiliser des runners avec des tags spécifiques afin de distribuer la charge.

Pour plus d'informations sur l'optimisation des scans planifiés, voir [optimiser les pipelines planifiés pour les projets à grande échelle](#optimize-scheduled-pipelines-for-projects-at-scale).

### Contrôle de la concurrence {#concurrency-control}

GitLab applique le contrôle de la concurrence lorsque vous définissez la propriété `time_window`.

Le contrôle de la concurrence distribue les pipelines planifiés selon les [paramètres `time_window`](#time_window-schema) définis dans la politique.

## Type d'action `scan` {#scan-action-type}

{{< history >}}

- Priorité des variables des politiques d'exécution de scan :
  - [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/424028) dans GitLab 16.7 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_variables_precedence`. Activé par défaut.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/435727) dans GitLab 16.8. Le feature flag `security_policies_variables_precedence` a été supprimé.
- Sélection des templates de sécurité pour une action donnée :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/415427) pour les projets dans GitLab 17.1 [avec le feature flag](../../../administration/feature_flags/_index.md) nommé `scan_execution_policies_with_latest_templates`. Désactivé par défaut.
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/468981) pour les groupes dans GitLab 17.2 [avec le feature flag](../../../administration/feature_flags/_index.md) nommé `scan_execution_policies_with_latest_templates_group`. Désactivé par défaut.
  - Activé sur [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/461474) et [GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468981) dans GitLab 17.2.
  - Généralement disponible dans GitLab 17.3. Les feature flags `scan_execution_policies_with_latest_templates` et `scan_execution_policies_with_latest_templates_group` ont été supprimés.
- Prise en charge du template `v2` pour `dependency_scanning` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/523986) dans GitLab 18.4.
- Le template par défaut pour `dependency_scanning` [modifié](https://gitlab.com/gitlab-org/gitlab/-/work_items/598744) en `v2` pour les nouvelles politiques dans GitLab 19.1.

{{< /history >}}

Cette action exécute le `scan` sélectionné avec des paramètres supplémentaires lorsque les conditions d'au moins une règle dans la politique définie sont remplies.

| Champ | Type | Valeurs possibles | Description |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`, `sast_iac`, `dast`, `secret_detection`, `container_scanning`, `dependency_scanning` | Type de l'action. |
| `site_profile` | `string` | Nom du [profil de site DAST](../dast/profiles.md#site-profile) sélectionné. | Le profil de site DAST pour exécuter le scan DAST. Ce champ ne doit être défini que si le type `scan` est `dast`. |
| `scanner_profile` | `string` ou `null` | Nom du [profil de scanner DAST](../dast/profiles.md#scanner-profile) sélectionné. | Le profil de scanner DAST pour exécuter le scan DAST. Ce champ ne doit être défini que si le type `scan` est `dast`.|
| `variables` | `object` | | Un ensemble de variables CI/CD, fourni sous la forme d'un tableau de paires `key: value`, à appliquer et à appliquer pour le scan sélectionné. La `key` est le nom de la variable, sa `value` étant fournie sous forme de chaîne. Ce paramètre prend en charge toute variable que le job GitLab CI/CD prend en charge pour le scan spécifié. |
| `tags` | `array` de `string` | | Une liste de tags de runner pour la politique. Les jobs de politique sont exécutés par un runner avec les tags spécifiés. |
| `template` | `string` | `default`, `latest` ou une version spécifique au scanner | Version du template CI/CD à appliquer. `default` utilise le template stable. `latest` utilise le template expérimental, qui peut inclure des modifications incompatibles — il ne s'agit pas de la version recommandée la plus récente. Certains scanners prennent également en charge des templates versionnés représentant la configuration recommandée. Le template `latest` ne prend en charge que `pipeline_sources` lié aux merge requests. Pour les versions disponibles par scanner, voir [Versions des templates de scanner](#scanner-template-versions). |
| `scan_settings` | `object` | | Un ensemble de paramètres de scan, fourni sous la forme d'un tableau de paires `key: value`, à appliquer et à appliquer pour le scan sélectionné. La `key` est le nom du paramètre, sa `value` étant fournie sous forme de booléen ou de chaîne. Ce paramètre prend en charge les paramètres définis dans les [paramètres de scan](#scan-settings). |

> [!note]
> Si des pipelines de merge request sont activés pour votre projet, vous devez définir la variable CI/CD `AST_ENABLE_MR_PIPELINES` à `"true"` dans votre politique pour chaque scan appliqué. Pour plus d'informations sur l'utilisation des outils de scan de sécurité avec les pipelines de merge request, consultez la [documentation sur le scan de sécurité](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

### Versions des templates de scanner {#scanner-template-versions}

Le champ `template` accepte `default` et `latest` pour tous les types de scanners. Certains scanners prennent en charge des templates versionnés supplémentaires. La valeur par défaut recommandée varie selon le scanner — consultez la documentation du scanner avant de définir ce champ.

| Scanner | Templates pris en charge | Documentation |
|---------|---------------------|---------------|
| `sast` | `default`, `latest` | [Templates SAST stables vs. les plus récents](../sast/_index.md#stable-vs-latest-sast-templates) |
| `sast_iac` | `default`, `latest` | [Éditions de templates](../detect/security_configuration.md#template-editions) |
| `secret_detection` | `default`, `latest` | [Éditions de templates](../detect/security_configuration.md#template-editions) |
| `container_scanning` | `default`, `latest` | [Éditions de templates](../detect/security_configuration.md#template-editions) |
| `dependency_scanning` | `default`, `latest`, `v2` | [Analyse des dépendances à l'aide de SBOM](../dependency_scanning/dependency_scanning_sbom/_index.md) |

### Comportement des scanners {#scanner-behavior}

Certains scanners se comportent différemment dans une action `scan` par rapport à un scan de pipeline CI/CD ordinaire :

- Test statique de sécurité des applications (SAST) : S'exécute uniquement si le dépôt contient des [fichiers pris en charge par SAST](../sast/_index.md#supported-languages-and-frameworks).
- Détection des secrets :
  - Seules les règles de l'ensemble de règles par défaut sont prises en charge par défaut.
  - Pour personnaliser une configuration d'ensemble de règles, vous pouvez :
    - Modifier l'ensemble de règles par défaut. Utilisez une politique d'exécution de scan pour spécifier la variable CI/CD `SECRET_DETECTION_RULESET_GIT_REFERENCE`. Par défaut, cela pointe vers un [fichier de configuration distant](../secret_detection/pipeline/configure.md#with-a-remote-ruleset) qui ne remplace ou ne désactive que les règles de l'ensemble de règles par défaut. L'utilisation de cette seule variable ne prend pas en charge l'extension ou le remplacement de l'ensemble de règles de règles par défaut.
    - [Étendre](../secret_detection/pipeline/configure.md#extend-the-default-ruleset) ou [remplacer](../secret_detection/pipeline/configure.md#replace-the-default-ruleset) l'ensemble de règles par défaut. Utilisez la politique d'exécution de scan pour spécifier la variable CI/CD `SECRET_DETECTION_RULESET_GIT_REFERENCE` et un fichier de configuration distant utilisant [un passthrough Git](../secret_detection/pipeline/custom_rulesets_schema.md#passthrough-types) pour étendre ou remplacer l'ensemble de règles par défaut. Pour un guide détaillé, consultez [Comment configurer une configuration centralisée de détection des secrets dans un pipeline](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy).
  - Pour les politiques d'exécution de scan `scheduled`, la détection des secrets s'exécute par défaut en premier en mode `historic` (`SECRET_DETECTION_HISTORIC_SCAN` = `true`). Tous les scans planifiés suivants s'exécutent en mode par défaut avec `SECRET_DETECTION_LOG_OPTIONS` défini sur la plage de commits entre la dernière exécution et le SHA actuel. Vous pouvez remplacer ce comportement en spécifiant des variables CI/CD dans la politique d'exécution de scan. Pour plus d'informations, voir [Détection des secrets dans un pipeline avec historique complet](../secret_detection/pipeline/_index.md#run-a-historic-scan).
  - Pour les politiques d'exécution de scan `triggered`, la détection des secrets fonctionne exactement comme un scan ordinaire [configuré manuellement dans le `.gitlab-ci.yml`](../secret_detection/pipeline/_index.md#edit-the-gitlab-ciyml-file-manually).
- Scan de conteneurs : Un scan configuré pour le type de règle `pipeline` ignore l'agent défini dans l'objet `agents`. L'objet `agents` n'est pris en compte que pour les types de règle `schedule`. Un agent dont le nom est fourni dans l'objet `agents` doit être créé et configuré pour le projet.

### Profils DAST {#dast-profiles}

Les exigences suivantes s'appliquent lors de l'application du test dynamique de sécurité des applications (DAST) :

- Pour chaque projet dans la portée de la politique, le [profil de site](../dast/profiles.md#site-profile) et le [profil de scanner](../dast/profiles.md#scanner-profile) spécifiés doivent exister. S'ils ne sont pas disponibles, la politique n'est pas appliquée et un job avec un message d'erreur est créé à la place.
- Lorsqu'un profil de site DAST ou un profil de scanner est nommé dans une politique d'exécution de scan activée, le profil ne peut pas être modifié ou supprimé. Pour modifier ou supprimer le profil, vous devez d'abord définir la politique sur **Désactivé** dans l'éditeur de politique ou définir `enabled: false` en mode YAML.
- Lors de la configuration de politiques avec un scan DAST planifié, l'auteur du commit dans le dépôt du projet de politique de sécurité doit avoir accès aux profils de scanner et de site. Sinon, le scan n'est pas planifié avec succès.

### Paramètres de scan {#scan-settings}

Les paramètres suivants sont pris en charge par le paramètre `scan_settings` :

| Paramètre | Type | Obligatoire | Valeurs possibles | Valeur par défaut | Description |
|-------|------|----------|-----------------|-------------|-----------|
| `ignore_default_before_after_script` | `boolean` | false | `true`, `false` | `false` | Indique si les définitions `before_script` et `after_script` par défaut dans la configuration du pipeline doivent être exclues du job de scan. |

## Variables CI/CD {#cicd-variables}

> [!warning]
> Ne stockez pas d'informations sensibles ou d'identifiants dans des variables, car ils sont stockés dans le cadre de la configuration de politique en texte clair dans un dépôt Git.

Les variables définies dans une politique d'exécution de scan suivent la [priorité des variables CI/CD](../../../ci/variables/_index.md#cicd-variable-precedence) standard.

Des valeurs préconfigurées sont utilisées pour les variables CI/CD suivantes dans tout projet sur lequel une politique d'exécution de scan est appliquée. Seules les politiques peuvent remplacer ces valeurs. Les variables CI/CD de groupe ou de projet ne peuvent pas remplacer ces variables :

```plaintext
DS_EXCLUDED_PATHS: spec, test, tests, tmp
SAST_EXCLUDED_PATHS: spec, test, tests, tmp
SECRET_DETECTION_EXCLUDED_PATHS: ''
SECRET_DETECTION_HISTORIC_SCAN: false
SAST_EXCLUDED_ANALYZERS: ''
DEFAULT_SAST_EXCLUDED_PATHS: spec, test, tests, tmp
DS_EXCLUDED_ANALYZERS: ''
SECURE_ENABLE_LOCAL_CONFIGURATION: true
```

Dans GitLab 16.9 et versions antérieures :

- Si les variables CI/CD avec le suffixe `_EXCLUDED_PATHS` étaient déclarées dans une politique, leurs valeurs pouvaient être remplacées par les variables CI/CD d'un groupe ou d'un projet.
- Si les variables CI/CD avec le suffixe `_EXCLUDED_ANALYZERS` étaient déclarées dans une politique, leurs valeurs étaient ignorées, indépendamment de l'endroit où elles étaient définies : politique, groupe ou projet.

## Schéma de portée de politique {#policy-scope-schema}

Pour personnaliser l'application des politiques, vous pouvez définir la portée d'une politique afin d'inclure ou d'exclure des projets, groupes ou labels de framework de conformité spécifiques. Pour plus de détails, voir [Portée](_index.md#configure-the-policy-scope).

> [!note]
> Définir un champ `policy_scope` sur une collection vide (par exemple, `including: []`) est traité de la même manière que l'omission du champ, de sorte que la politique s'applique à tous les projets pour cette dimension de portée. Pour désactiver entièrement une politique, utilisez `enabled: false`. Pour plus de détails, voir [Collections vides dans `policy_scope`](_index.md#empty-collections-in-policy_scope).

## Propagation des mises à jour de politique {#policy-update-propagation}

Lorsque vous mettez à jour une politique, les modifications se propagent différemment selon la méthode de mise à jour :

- Avec une merge request sur le [projet de politique de sécurité](../_index.md) : Les modifications prennent effet immédiatement après la fusion de la merge request.
- Commits directs vers `.gitlab/security-policies/policy.yml` : Les modifications peuvent prendre jusqu'à 10 minutes pour prendre effet.

### Comportement de déclenchement {#triggering-behavior}

Les mises à jour des politiques basées sur un pipeline (`type: pipeline`) ne déclenchent pas de pipelines immédiats et n'affectent pas les pipelines déjà en cours. Les modifications de politique s'appliquent aux futures exécutions de pipeline.

Vous ne pouvez pas déclencher manuellement les règles d'une politique planifiée en dehors de leur cadence planifiée.

## Exemple de projet de politique de sécurité {#example-security-policy-project}

Vous pouvez utiliser cet exemple dans un fichier `.gitlab/security-policies/policy.yml` stocké dans un [projet de politique de sécurité](enforcement/security_policy_projects.md) :

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every release pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST and secret detection scans every 10 minutes
  description: This policy enforces DAST and secret detection scans to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: "*/10 * * * *"
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
  - scan: secret_detection
    scan_settings:
      ignore_default_before_after_script: true
- name: Enforce secret detection and container scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
    variables:
      SAST_EXCLUDED_ANALYZERS: brakeman
  - scan: container_scanning
```

Dans cet exemple :

- Pour chaque pipeline exécuté sur des branches correspondant au caractère générique `release/*` (par exemple, la branche `release/v1.2.1`)
  - Les scans DAST s'exécutent avec `Scanner Profile A` et `Site Profile B`.
- Les scans DAST et de détection des secrets s'exécutent toutes les 10 minutes. Le scan DAST s'exécute avec `Scanner Profile C` et `Site Profile D`.
- Les scans de détection des secrets, de scan de conteneurs et SAST s'exécutent pour chaque pipeline exécuté sur la branche `main`. Le scan SAST s'exécute avec la variable `SAST_EXCLUDED_ANALYZER` définie sur `"brakeman"`.

## Exemple pour l'éditeur de politiques d'exécution de scan {#example-for-scan-execution-policy-editor}

Vous pouvez utiliser cet exemple en mode YAML de l'[éditeur de politiques d'exécution de scan](#scan-execution-policy-editor). Il correspond à un seul objet de l'exemple précédent.

```yaml
name: Enforce secret detection and container scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## Éviter les scans en double {#avoiding-duplicate-scans}

Les politiques d'exécution de scan peuvent amener le même type de scanner à s'exécuter plus d'une fois si vous incluez des jobs de scan dans le fichier `.gitlab-ci.yml` de votre projet.

Les scans en double s'exécutent intentionnellement, car les scanners peuvent s'exécuter plusieurs fois avec des variables et des paramètres différents. Par exemple, vous pourriez exécuter un scan SAST avec des variables différentes de celles appliquées par vos politiques. Dans ce scénario, deux jobs SAST s'exécutent dans le pipeline :

- Un avec des variables personnalisées.
- Un avec les variables appliquées par la politique.

Pour éviter les scans en double, vous pouvez soit supprimer l'un des scans du fichier `.gitlab-ci.yml` du projet, soit ignorer les jobs locaux à l'aide de variables. L'omission de jobs n'empêche pas les jobs de sécurité définis par les politiques d'exécution de scan de s'exécuter.

Pour ignorer les jobs de scan à l'aide de variables, vous pouvez utiliser :

- `SAST_DISABLED: "true"` pour ignorer les jobs SAST.
- `DAST_DISABLED: "true"` pour ignorer les jobs DAST.
- `CONTAINER_SCANNING_DISABLED: "true"` pour ignorer les jobs de scan de conteneurs.
- `SECRET_DETECTION_DISABLED: "true"` pour ignorer les jobs de détection des secrets.
- `DEPENDENCY_SCANNING_DISABLED: "true"` pour ignorer les jobs d'analyse des dépendances.

Pour un aperçu de toutes les variables pouvant ignorer des jobs, voir la [documentation sur les variables CI/CD](../../../topics/autodevops/cicd_variables.md#job-skipping-variables)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des politiques d'exécution de scan, vous pouvez rencontrer les problèmes suivants.

### Les pipelines de la politique d'exécution de scan ne sont pas créés {#scan-execution-policy-pipelines-are-not-created}

Si une politique d'exécution de scan ne crée pas de pipeline défini dans `type: pipeline` comme prévu, il se peut que vous ayez [`workflow:rules`](../../../ci/yaml/workflow.md) dans le fichier `.gitlab-ci.yml` du projet qui empêche la politique de créer le pipeline.

Les politiques d'exécution de scan avec des règles `type: pipeline` s'appuient sur la configuration CI/CD fusionnée pour créer des pipelines. Si le `workflow:rules` du projet filtre entièrement le pipeline, la politique d'exécution de scan ne peut pas créer de pipelines.

Par exemple, la configuration `workflow:rules` suivante empêche la création de tous les pipelines :

```yaml
# .gitlab-ci.yml
workflow:
  rules:
  - if: $CI_PIPELINE_SOURCE == "push"
    when: never
```

Résolution :

Pour résoudre ce problème, vous pouvez utiliser l'une des options suivantes :

- Modifiez le `workflow:rules` dans le fichier `.gitlab-ci.yml` de votre projet pour autoriser les politiques d'exécution de scan à créer des pipelines. Vous pouvez utiliser la variable `$CI_PIPELINE_SOURCE` pour identifier les pipelines déclenchés par des politiques :

  ```yaml
  workflow:
    rules:
    - if: $CI_PIPELINE_SOURCE == "security_orchestration_policy"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
  ```

- Utilisez des règles `type: schedule` plutôt que des règles `type: pipeline`. Les politiques d'exécution de scan planifiées ne sont pas affectées par `workflow:rules` et créent des pipelines selon leur planification définie.
- Utilisez les [politiques d'exécution de pipeline](pipeline_execution_policies.md) pour plus de contrôle sur le moment et la manière dont les scans de sécurité sont exécutés dans vos pipelines CI/CD.
