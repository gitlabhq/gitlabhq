---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les limites CI/CD pour les pipelines, les jobs, les planifications et les artefacts afin de contrôler l'utilisation des ressources sur votre instance."
title: Limites CI/CD
---

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez gérer de nombreuses limites d'instance liées à la CI/CD via la [zone d'administration](../admin_area.md). Les autres limites ne peuvent être modifiées qu'en changeant la configuration de l'instance via la console Rails de GitLab.

GitLab.com peut avoir des valeurs différentes des valeurs par défaut pour GitLab Self-Managed. Consultez les [limites et paramètres CI/CD pour GitLab.com](../../user/gitlab_com/_index.md#cicd).

## Limite des variables CI/CD au niveau de l'instance {#instance-cicd-variable-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/456845) dans GitLab 17.1.

{{< /history >}}

Le nombre de [variables CI/CD](../../ci/variables/_index.md) pouvant être définies dans les paramètres de l'instance est limité. Cette limite est vérifiée chaque fois qu'une nouvelle variable est créée. Si une nouvelle variable devait faire dépasser le nombre total de variables la limite, la nouvelle variable n'est pas créée.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de variables CI/CD au niveau de l'instance pouvant être définies**. La valeur par défaut est `25`.
1. Sélectionnez **Sauvegarder les modifications**.

## Limiter la taille du fichier dotenv {#limit-dotenv-file-size}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) dans GitLab 17.1.

{{< /history >}}

Vous pouvez définir une limite sur la taille maximale d'un artefact dotenv. Cette limite est vérifiée chaque fois qu'un fichier dotenv est exporté en tant qu'artefact.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Taille maximale d'un artefact dotenv en octets**.
1. Sélectionnez **Sauvegarder les modifications**.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est 5 Ko.

## Limiter les variables dotenv {#limit-dotenv-variables}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) dans GitLab 17.1.

{{< /history >}}

Vous pouvez définir une limite sur le nombre maximum de variables à l'intérieur d'un artefact dotenv. Cette limite est vérifiée chaque fois qu'un fichier dotenv est exporté en tant qu'artefact.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de variables dans un artefact dotenv**.
1. Sélectionnez **Sauvegarder les modifications**.

Définissez la limite à `0` pour la désactiver. Par défaut, `20`.

Vous pouvez également définir cette limite en utilisant l'[API Plan limits](../../api/plan_limits.md).

## Nombre maximum de jobs dans un pipeline {#maximum-number-of-jobs-in-a-pipeline}

{{< history >}}

- Paramètre [déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/287669) de GitLab Enterprise Edition vers GitLab Community Edition dans la version 17.6.

{{< /history >}}

Vous pouvez limiter le nombre maximum de jobs dans un pipeline. Le nombre de jobs dans un pipeline est vérifié lors de la création du pipeline et lors de la création de nouveaux statuts de commit. Les pipelines comportant trop de jobs échouent avec une erreur `size_limit_exceeded`.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de jobs dans un seul pipeline**.
1. Sélectionnez **Sauvegarder les modifications**.

Définissez la limite à `0` pour la désactiver. Désactivé par défaut.

## Nombre de jobs dans les pipelines actifs {#number-of-jobs-in-active-pipelines}

Le nombre total de jobs dans les pipelines actifs peut être limité par projet. Cette limite est vérifiée chaque fois qu'un nouveau pipeline est créé. Un pipeline actif est tout pipeline dans l'un des états suivants :

- `created`
- `pending`
- `running`

Si un nouveau pipeline devait faire dépasser le nombre total de jobs la limite, le pipeline échoue avec une erreur `job_activity_limit_exceeded`.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre total de jobs dans les pipelines actuellement actifs**.
1. Sélectionnez **Sauvegarder les modifications**.

Définissez la limite à `0` pour la désactiver. Désactivé par défaut.

## Nombre d'abonnements CI/CD à un projet {#number-of-cicd-subscriptions-to-a-project}

Le nombre total d'abonnements peut être limité par projet. Cette limite est vérifiée chaque fois qu'un nouvel abonnement est créé.

Si un nouvel abonnement devait faire dépasser le nombre total d'abonnements la limite, l'abonnement est considéré comme invalide.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum d'abonnements de pipelines à un projet ou depuis un projet**.
1. Sélectionnez **Sauvegarder les modifications**.

Par défaut, il existe une limite de `2` abonnements. Définissez la limite à `0` pour la désactiver.

## Nombre de planifications de pipeline {#number-of-pipeline-schedules}

Le nombre total de planifications de pipeline peut être limité par projet. Cette limite est vérifiée chaque fois qu'une nouvelle planification de pipeline est créée. Si une nouvelle planification de pipeline devait faire dépasser le nombre total de planifications de pipeline la limite, la planification de pipeline n'est pas créée.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de planifications de pipelines**.
1. Sélectionnez **Sauvegarder les modifications**.

Par défaut, il existe une limite de `10` planifications de pipeline.

Vous pouvez également utiliser l'[API Plan Limits](../../api/plan_limits.md).

## Nombre maximum de dépendances needs {#maximum-number-of-needs-dependencies}

Vous pouvez définir un nombre maximum de dépendances needs qu'un seul job peut avoir.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de dépendances de besoins qu'un job peut avoir**
1. Sélectionnez **Sauvegarder les modifications**.

Cette limite ne peut pas être désactivée. Par défaut, `50`. Définissez à `0` pour bloquer toutes les dépendances needs.

## Nombre de runners enregistrés pour les groupes et projets {#number-of-registered-runners-for-groups-and-projects}

{{< history >}}

- Le délai d'inactivité du runner a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795) de 3 mois à 7 jours dans GitLab 17.1.

{{< /history >}}

Le nombre total de runners enregistrés est limité pour les groupes et les projets. Chaque fois qu'un nouveau runner est enregistré, GitLab vérifie ces limites par rapport aux runners créés ou actifs au cours des 7 derniers jours. L'enregistrement d'un runner échoue s'il dépasse la limite pour la portée déterminée par le jeton d'enregistrement du runner.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour l'un ou l'autre :
   - **Nombre maximal de runners créés ou actifs dans un groupe au cours des sept derniers jours**
   - **Nombre maximal de runners créés ou actifs dans un projet au cours des sept derniers jours**
1. Sélectionnez **Sauvegarder les modifications**.

Définissez la limite à `0` pour la désactiver.

## Limiter la taille de la hiérarchie de pipeline {#limit-pipeline-hierarchy-size}

Par défaut, une [hiérarchie de pipeline](../../ci/pipelines/downstream_pipelines.md) peut contenir jusqu'à 1000 pipelines downstream. Lorsque cette limite est dépassée, la création du pipeline échoue avec l'erreur `downstream pipeline tree is too large`.

> [!warning]
> Il n'est pas recommandé d'augmenter cette limite. La limite par défaut protège votre instance GitLab contre une consommation excessive de ressources, une récursion potentielle des pipelines et une surcharge de la base de données.
>
> Au lieu d'augmenter la limite, restructurez votre configuration CI/CD en divisant les grandes hiérarchies de pipelines en pipelines plus petits. Envisagez d'utiliser `needs` entre les jobs ou des étapes dépendantes dans un seul pipeline.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Nombre maximum de pipelines en aval dans l'arborescence hiérarchique d'un pipeline**.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez également utiliser l'[API Plan Limits](../../api/plan_limits.md).

## Limite de pipelines parallèles par merge train {#merge-train-parallel-pipeline-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/374188) dans GitLab 19.0.

{{< /history >}}

Par défaut, chaque [merge train](../../ci/pipelines/merge_trains.md) peut exécuter un maximum de 20 pipelines en parallèle. Lorsque cette limite est atteinte, les merge requests supplémentaires sont mises en file d'attente jusqu'à ce qu'un emplacement de pipeline soit disponible.

Pour configurer cette limite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sous **Limites CI/CD**, définissez une valeur pour **Maximum parallel pipelines per merge train**. La valeur minimale est `1`. Une valeur de `1` traite les merge requests séquentiellement sans parallélisme.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez également utiliser l'[API Plan Limits](../../api/plan_limits.md).

Vous pouvez définir une valeur différente [pour un projet spécifique](../../ci/pipelines/merge_trains.md#merge-train-parallel-pipeline-limit).

## Durée maximale d'exécution des jobs {#maximum-time-jobs-can-run}

La durée maximale par défaut d'exécution des jobs est de 60 minutes. Les jobs qui s'exécutent pendant plus de 60 minutes expirent.

Vous pouvez modifier la durée maximale d'exécution d'un job avant son expiration :

- Pour un projet dans les [paramètres CI/CD du projet](../../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) pour un projet donné. Cette limite doit être comprise entre 10 minutes et 1 mois.
- [Pour un runner](../../ci/runners/configure_runners.md#set-the-maximum-job-timeout). Cette limite doit être de 10 minutes ou plus.

Quelle que soit la configuration des limites de délai d'expiration, GitLab met fin à tout job inactif depuis 60 minutes. Un job inactif est un job qui n'a produit aucun nouveau job log ni aucune mise à jour de trace.

## Nombre de pipelines par push Git {#number-of-pipelines-per-git-push}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186134) dans GitLab 18.0.

{{< /history >}}

> [!warning]
> Il n'est pas recommandé d'augmenter cette limite. Cela peut entraîner une charge excessive sur votre instance GitLab si de nombreuses modifications sont poussées simultanément, créant potentiellement un afflux de pipelines.

Lors du push de plusieurs modifications avec un seul push Git, comme plusieurs tags ou branches, seulement quatre pipelines de tag ou de branche peuvent être déclenchés par défaut. Cette limite empêche la création accidentelle d'un grand nombre de pipelines lors de l'utilisation de `git push --all` ou `git push --mirror`.

Les [pipelines de merge request](../../ci/pipelines/merge_request_pipelines.md) sont limités. Si le push Git met à jour plusieurs merge requests en même temps, un pipeline de merge request peut se déclencher pour chaque merge request mis à jour avant d'atteindre la limite.

La valeur par défaut est `4` pour GitLab Self-Managed et GitLab.com.

Pour modifier cette limite sur votre instance GitLab Self-Managed :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Intégration et déploiement continus**.
1. Modifiez la valeur de **Limite de pipeline par poussée Git**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configuration de l'instance pour les limites CI/CD {#cicd-limits-instance-configuration}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Certaines limites CI/CD ne peuvent être modifiées qu'en éditant la configuration de l'instance.

Prérequis :

- Vous devez avoir accès à la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) pour l'instance.

### Nombre maximum de jobs de déploiement dans un pipeline {#maximum-number-of-deployment-jobs-in-a-pipeline}

Vous pouvez limiter le nombre maximum de jobs de déploiement dans un pipeline. Un déploiement est tout job avec un [`environment`](../../ci/environments/_index.md) spécifié. Le nombre de déploiements dans un pipeline est vérifié lors de la création du pipeline. Les pipelines comportant trop de déploiements échouent avec une erreur `deployments_limit_exceeded`.

Pour modifier la limite, changez la limite du plan `default` avec la commande [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) suivante :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

La limite par défaut est `500`. Définissez la limite à `0` pour la désactiver.

### Limiter le nombre de déclencheurs de pipeline {#limit-the-number-of-pipeline-triggers}

Vous pouvez définir une limite sur le nombre maximum de déclencheurs de pipeline par projet. Cette limite est vérifiée chaque fois qu'un nouveau déclencheur est créé.

Si un nouveau déclencheur devait faire dépasser le nombre total de déclencheurs de pipeline la limite, le déclencheur est considéré comme invalide.

Définissez la limite à `0` pour la désactiver. Par défaut, `25000`.

Pour définir cette limite à `100`, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

### Nombre de planifications de pipeline {#number-of-pipeline-schedules-1}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le nombre total de planifications de pipeline peut être limité par projet. Cette limite est vérifiée chaque fois qu'une nouvelle planification de pipeline est créée. Si une nouvelle planification de pipeline devait faire dépasser le nombre total de planifications de pipeline la limite, la planification de pipeline n'est pas créée.

Sur GitLab Self-Managed et GitLab Dedicated, cette limite est définie dans un plan `default` qui s'applique à tous les projets. Par défaut, il existe une limite de `10` planifications de pipeline.

Pour définir cette limite, utilisez l'[API Plan Limits](../../api/plan_limits.md).

Pour GitLab Self-Managed, vous pouvez également utiliser la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Par exemple, pour définir la limite à 100 :

```ruby
Plan.default.actual_limits.update!(ci_pipeline_schedules: 100)
```

### Limiter le nombre de pipelines créés par une planification de pipeline chaque jour {#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day}

Vous pouvez limiter le nombre de pipelines que chaque planification de pipeline individuelle peut déclencher par jour.

Les planifications qui tentent d'exécuter des pipelines plus fréquemment que la limite sont ralenties à une fréquence maximale. La fréquence est calculée en divisant 1440 (le nombre de minutes dans une journée) par la valeur limite. Par exemple, pour une fréquence maximale de :

- Une fois par minute, la limite doit être `1440`.
- Une fois par 10 minutes, la limite doit être `144`.
- Une fois par 60 minutes, la limite doit être `24`

La valeur minimale est `24`, soit un pipeline par 60 minutes. Il n'y a pas de valeur maximale.

Pour définir cette limite à `1440` sur une instance GitLab Self-Managed, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

### Limiter le nombre de règles de planification définies pour un projet de politique de sécurité {#limit-the-number-of-schedule-rules-defined-for-security-policy-project}

Vous pouvez limiter le nombre total de règles de planification par projet de politique de sécurité. Cette limite est vérifiée chaque fois que des politiques avec des règles de planification sont mises à jour. Si une nouvelle règle de planification devait faire dépasser le nombre total de règles de planification la limite, la nouvelle règle de planification n'est pas traitée.

Par défaut, GitLab ne limite pas le nombre de règles de planification pouvant être traitées.

Pour définir cette limite, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

### Limites de variables CI/CD pour les groupes et les projets {#group-and-project-cicd-variable-limits}

Le nombre de [variables CI/CD](../../ci/variables/_index.md) pouvant être définies dans les groupes et les projets est limité pour l'ensemble de l'instance. Ces limites sont vérifiées chaque fois qu'une nouvelle variable est créée. Si une nouvelle variable devait faire dépasser le nombre total de variables la limite respective, la nouvelle variable n'est pas créée.

Pour mettre à jour le plan `default` de l'une de ces limites, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

- Limite de [variable CI/CD au niveau du groupe](../../ci/variables/_index.md#for-a-group) par groupe (par défaut : `30000`) :

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- Limite de [variable CI/CD au niveau du projet](../../ci/variables/_index.md#for-a-project) par projet (par défaut : `8000`) :

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### Taille maximale de fichier par type d'artefact {#maximum-file-size-per-type-of-artifact}

{{< history >}}

- Limite `ci_max_artifact_size_annotations` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.
- Limite `ci_max_artifact_size_jacoco` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696) dans GitLab 17.3
- Limite `ci_max_artifact_size_lsif` [augmentée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684) dans GitLab 17.8.

{{< /history >}}

Les artefacts de job définis avec [`artifacts:reports`](../../ci/yaml/_index.md#artifactsreports) qui sont téléversés par le runner sont rejetés si la taille du fichier dépasse la limite de taille de fichier maximale. La limite est déterminée en comparant le [paramètre de taille maximale des artefacts](../settings/continuous_integration.md#set-maximum-artifacts-size) du projet avec la limite d'instance pour le type d'artefact donné, et en choisissant la valeur la plus petite.

Les limites sont définies en mégaoctets, donc la plus petite valeur possible qui peut être définie est `1 MB`.

Chaque type d'artefact a une limite de taille qui peut être définie. Une valeur par défaut de `0` signifie qu'il n'y a pas de limite pour ce type d'artefact spécifique, et le paramètre de taille maximale des artefacts du projet est utilisé :

| Nom de la limite d'artefact                         | Valeur par défaut |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

Par exemple, pour définir la limite `ci_max_artifact_size_junit` à 10 Mo sur GitLab Self-Managed, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### Taille maximale de fichier pour les job logs {#maximum-file-size-for-job-logs}

La limite de taille du job log dans GitLab est de 100 mégaoctets par défaut. Tout job dépassant la limite est marqué comme échoué et abandonné par le runner.

Vous pouvez modifier la limite dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Mettez à jour `ci_jobs_trace_size_limit` avec la nouvelle valeur en mégaoctets :

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab Runner dispose également d'un [paramètre `output_limit`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) qui configure la taille maximale du log dans un runner. Les jobs qui dépassent la limite du runner continuent de s'exécuter, mais le log est tronqué lorsqu'il atteint la limite.

### Nombre maximum de planifications de profil DAST actives par projet {#maximum-number-of-active-dast-profile-schedules-per-project}

Limitez le nombre de planifications de profil DAST actives par projet. Une planification de profil DAST peut être active ou inactive.

Vous pouvez modifier la limite dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Mettez à jour `dast_profile_schedules` avec la nouvelle valeur :

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### Taille maximale de l'archive des artefacts CI {#maximum-size-of-the-ci-artifacts-archive}

Ce paramètre est utilisé pour restreindre les tailles YAML pour les [pipelines enfants dynamiques](../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines).

La taille maximale par défaut de l'archive des artefacts CI est de 5 mégaoctets.

Vous pouvez modifier cette limite en utilisant la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Pour mettre à jour la taille maximale de l'archive des artefacts CI, mettez à jour `max_artifacts_content_include_size` avec la nouvelle valeur. Par exemple, pour la définir à 20 Mo :

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### Taille maximale et profondeur des fichiers YAML de configuration CI/CD {#maximum-size-and-depth-of-cicd-configuration-yaml-files}

{{< history >}}

- La valeur par défaut de `max_yaml_size_bytes` a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.

{{< /history >}}

La taille maximale par défaut d'un seul fichier YAML de configuration CI/CD est de 2 mégaoctets et la profondeur par défaut est de 100.

Vous pouvez modifier ces limites dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

- Pour mettre à jour la taille maximale du YAML, mettez à jour `max_yaml_size_bytes` avec la nouvelle valeur en mégaoctets :

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  La valeur `max_yaml_size_bytes` n'est pas directement liée à la taille du fichier YAML, mais plutôt à la mémoire allouée pour les objets concernés.

- Pour mettre à jour la profondeur maximale du YAML, mettez à jour `max_yaml_depth` avec la nouvelle valeur en nombre de lignes :

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### Taille maximale de l'ensemble de la configuration CI/CD {#maximum-size-of-the-entire-cicd-configuration}

{{< history >}}

- La valeur par défaut de `max_yaml_size_bytes` a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.
- La valeur par défaut de `ci_max_total_yaml_size_bytes` a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.

{{< /history >}}

La quantité maximale de mémoire, en octets, pouvant être allouée à la configuration complète du pipeline, avec tous les fichiers de configuration YAML inclus.

La valeur par défaut est calculée en multipliant [`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files) (par défaut 2 Mo) par [`ci_max_includes`](../../api/settings.md#available-settings) (par défaut 150) :

- Dans GitLab 17.2 et versions antérieures : 1 Mo × 150 = `157286400` octets (150 Mo).
- Dans GitLab 17.3 et versions ultérieures : 2 Mo × 150 = `314572800` octets (314,6 Mo).

Vous pouvez modifier cette limite en utilisant la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Pour mettre à jour la mémoire maximale pouvant être allouée à la configuration CI/CD, mettez à jour `ci_max_total_yaml_size_bytes` avec la nouvelle valeur. Par exemple, pour la définir à 20 Mo :

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### Limiter les annotations de job CI/CD {#limit-cicd-job-annotations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.

{{< /history >}}

Vous pouvez définir une limite sur le nombre maximum d'[annotations](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations) par job CI/CD.

Définissez la limite à `0` pour la désactiver. Par défaut, `20`.

Pour définir cette limite à `100` sur votre instance, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### Limiter la taille des fichiers d'annotations de job CI/CD {#limit-cicd-job-annotations-file-size}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.

{{< /history >}}

Vous pouvez définir une limite sur la taille maximale d'une [annotation](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations) de job CI/CD.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est 80 Ko.

Pour définir cette limite à 100 Ko, exécutez la commande suivante dans la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### Taille maximale de partition de base de données pour les tables CI/CD {#maximum-database-partition-size-for-cicd-tables}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131) dans GitLab 18.0.
- [Supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314) dans GitLab 18.11.

{{< /history >}}

La quantité maximale d'espace disque, en octets, pouvant être utilisée par une partition d'une table partitionnée, avant que de nouvelles partitions ne soient créées automatiquement. La valeur par défaut est 100 Go.

Vous pouvez modifier cette limite en utilisant la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_partitions_size_limit` avec la nouvelle valeur. Par exemple, pour la définir à 20 Go :

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### Fenêtre temporelle maximale pour les partitions CI/CD {#maximum-time-window-for-cicd-partitions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314) dans GitLab 18.10.

{{< /history >}}

La fenêtre temporelle, en secondes, avant que de nouvelles partitions CI ne soient créées et que le système bascule vers le prochain ensemble de partitions. Doit être compris entre 1 mois et 6 mois. La valeur par défaut est 1 mois (2592000 secondes).

Vous pouvez modifier cette limite en utilisant la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_partitions_in_seconds_limit` avec la nouvelle valeur. Par exemple, pour la définir à 3 mois :

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### Période de rétention maximale pour le nettoyage automatique des pipelines {#maximum-retention-period-for-automatic-pipeline-cleanup}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191) dans GitLab 18.0.

{{< /history >}}

Configure la limite supérieure pour le [nettoyage automatique des pipelines](../../ci/pipelines/settings.md#automatic-pipeline-cleanup). La valeur par défaut est 1 an.

Vous pouvez modifier cette limite en utilisant la [console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_delete_pipelines_in_seconds_limit_human_readable` avec la nouvelle valeur. Par exemple, pour la définir à 3 ans :

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```
