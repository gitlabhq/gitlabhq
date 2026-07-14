---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Politiques d'exécution de pipeline planifiées"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/14147) en tant que version expérimentale dans GitLab 18.0 avec un indicateur nommé `scheduled_pipeline_execution_policy_type` défini dans le fichier `policy.yml`.

{{< /history >}}

Les politiques d'exécution de pipeline appliquent des jobs CI/CD personnalisés dans les pipelines de vos projets. Avec les politiques d'exécution de pipeline planifiées, vous pouvez étendre cette application pour exécuter le job CI/CD selon une cadence régulière (quotidienne, hebdomadaire ou mensuelle), garantissant que les scripts de conformité, les analyses de sécurité ou d'autres jobs CI/CD personnalisés sont exécutés même lorsqu'il n'y a pas de nouveaux commits.

## Planification de vos politiques d'exécution de pipeline {#scheduling-your-pipeline-execution-policies}

Contrairement aux politiques d'exécution de pipeline classiques qui injectent ou remplacent des jobs dans des pipelines existants, les politiques planifiées créent de nouveaux pipelines qui s'exécutent indépendamment selon la planification que vous définissez. Les pipelines planifiés sont distincts du fichier `.gitlab-ci.yml` de votre projet et n'exécutent aucun des jobs CI/CD du projet.

Les cas d'utilisation courants comprennent :

- Appliquer des analyses de sécurité selon une cadence régulière pour répondre aux exigences de conformité.
- Vérifier périodiquement les configurations du projet.
- Exécuter des analyses de dépendances sur des dépôts inactifs pour détecter les vulnérabilités nouvellement découvertes.
- Exécuter des scripts de reporting de conformité selon une planification.

## Activer les politiques d'exécution de pipeline planifiées {#enable-scheduled-pipeline-execution-policies}

Les politiques d'exécution de pipeline planifiées sont disponibles en tant que fonctionnalité expérimentale. Pour activer cette fonctionnalité dans votre environnement, activez la version expérimentale `pipeline_execution_schedule_policy` dans la configuration de la politique de sécurité. Le fichier de configuration YAML `.gitlab/security-policies/policy.yml` est stocké dans votre projet de politique de sécurité :

```yaml
experiments:
  pipeline_execution_schedule_policy:
    enabled: true
```

> [!note]
> Cette fonctionnalité est expérimentale et peut être modifiée dans les futures versions. Vous devez la tester minutieusement dans un environnement hors production uniquement. Vous ne devez pas utiliser cette fonctionnalité dans des environnements de production, car elle peut être instable.

## Configurer les politiques d'exécution de pipeline planifiées {#configure-schedule-pipeline-execution-policies}

Pour configurer une politique d'exécution de pipeline planifiée, ajoutez des champs de configuration supplémentaires à la section `pipeline_execution_schedule_policy` du fichier `.gitlab/security-policies/policy.yml` de votre projet de politique de sécurité :

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Pipeline Execution Policy
  description: ''
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: daily
    start_time: '10:00'
    time_window:
      value: 600
      distribution: random
```

### Schéma de configuration de la planification {#schedule-configuration-schema}

La section `schedules` vous permet de configurer quand les jobs de politique de sécurité s'exécutent automatiquement. Vous pouvez créer des planifications quotidiennes, hebdomadaires ou mensuelles avec des heures d'exécution spécifiques et des fenêtres de distribution.

### Options de configuration des planifications {#schedules-configuration-options}

La section `schedules` prend en charge les options suivantes :

| Paramètre | Description |
|-----------|-------------|
| `type` | Type de planification : `daily`, `weekly` ou `monthly` |
| `start_time` | Heure de démarrage de la planification au format 24 heures (HH:MM) |
| `time_window` | Fenêtre temporelle dans laquelle distribuer les exécutions de pipeline |
| `time_window.value` | Durée en secondes (minimum : 600, maximum : 2629746) |
| `time_window.distribution` | Méthode de distribution (actuellement, seule `random` est prise en charge) |
| `timezone` | Identifiant de fuseau horaire IANA (par défaut UTC si non spécifié) |
| `branches` | Tableau optionnel contenant les noms des branches sur lesquelles planifier les pipelines. Si `branches` est spécifié, les pipelines s'exécutent uniquement sur les branches spécifiées et seulement si elles existent dans le projet. Si non spécifié, les pipelines s'exécutent uniquement sur la branche par défaut. Vous pouvez fournir un maximum de cinq noms de branches uniques par planification. |
| `days` | À utiliser uniquement avec les planifications hebdomadaires : Tableau des jours où la planification s'exécute (par exemple, `["Monday", "Friday"]`) |
| `days_of_month` | À utiliser uniquement avec les planifications mensuelles : Tableau des dates où la planification s'exécute (par exemple, `[1, 15]`, peut inclure des valeurs de 1 à 31) |
| `snooze` | Configuration optionnelle pour mettre temporairement en pause la planification |
| `snooze.until` | Date et heure ISO8601 à laquelle la planification reprend après la mise en veille (format : `2025-06-13T20:20:00+00:00`) |
| `snooze.reason` | Documentation optionnelle expliquant pourquoi la planification est mise en veille |

### Exemples de planification {#schedule-examples}

Utilisez des planifications quotidiennes, hebdomadaires ou mensuelles.

#### Exemple de planification quotidienne {#daily-schedule-example}

```yaml
schedules:
  - type: daily
    start_time: "01:00"
    time_window:
      value: 3600  # 1 hour window
      distribution: random
    timezone: "America/New_York"
    branches:
      - main
      - develop
      - staging
```

#### Exemple de planification hebdomadaire {#weekly-schedule-example}

```yaml
schedules:
  - type: weekly
    days:
      - Monday
      - Wednesday
      - Friday
    start_time: "04:30"
    time_window:
      value: 7200  # 2 hour window
      distribution: random
    timezone: "Europe/Berlin"
```

#### Exemple de planification mensuelle {#monthly-schedule-example}

```yaml
schedules:
  - type: monthly
    days_of_month:
      - 1
      - 15
    start_time: "02:15"
    time_window:
      value: 14400  # 4 hour window
      distribution: random
    timezone: "Asia/Tokyo"
```

### Distribution de la fenêtre temporelle {#time-window-distribution}

Pour éviter de surcharger votre infrastructure CI/CD lors de l'application de politiques à plusieurs projets, les politiques d'exécution de pipeline planifiées distribuent la création des pipelines sur une fenêtre temporelle selon certaines règles communes :

- Tous les pipelines sont planifiés de manière `random`. Les pipelines sont distribués de façon aléatoire pendant la fenêtre temporelle spécifiée.
- La fenêtre temporelle minimale est de 10 minutes (600 secondes) et le maximum est d'environ 1 mois (2 629 746 secondes).
- Pour les planifications mensuelles, si vous spécifiez des dates qui n'existent pas dans certains mois (comme le 31 pour février), ces exécutions sont ignorées.
- Un projet de politique de sécurité peut contenir jusqu'à cinq politiques d'exécution de pipeline planifiées.
- Une politique planifiée ne peut avoir qu'une seule configuration de planification à la fois.
- Une politique planifiée peut cibler jusqu'à cinq branches. Si vous omettez `branches`, la politique s'exécute uniquement sur la branche par défaut du projet.
- Lorsque vous appliquez une politique à plusieurs projets, assurez-vous que votre fenêtre temporelle est suffisamment large pour prendre en compte le nombre de projets, en fonction de la capacité disponible de vos runners. Par exemple, une politique appliquée à 1 000 projets avec une fenêtre temporelle d'une heure distribue la création des pipelines de façon uniforme tout au long de cette heure (environ 16 pipelines par minute). Vérifiez que vos runners peuvent gérer ce taux de création de pipelines ou choisissez une fenêtre temporelle plus large pour éviter les files d'attente ou les délais.
- Pour les planifications mensuelles, l'intervalle entre des exécutions consécutives peut varier en raison de la distribution aléatoire pendant la fenêtre temporelle. Par exemple, une planification mensuelle peut s'exécuter 20 jours après l'exécution précédente, puis 30 jours plus tard. Cette distribution est le comportement attendu, car elle permet de répartir la charge sur votre infrastructure.

## Mettre en veille les politiques d'exécution de pipeline planifiées {#snooze-scheduled-pipeline-execution-policies}

Vous pouvez temporairement mettre en pause les politiques d'exécution de pipeline planifiées à l'aide de la fonctionnalité de mise en veille. Utilisez la fonctionnalité de mise en veille pendant les fenêtres de maintenance, les jours fériés, ou lorsque vous devez empêcher l'exécution des pipelines planifiés pendant une période spécifique.

### Fonctionnement de la mise en veille {#how-snoozing-works}

Lorsque vous mettez en veille une politique d'exécution de pipeline planifiée :

- Aucun nouveau pipeline planifié n'est créé pendant la période de mise en veille.
- Les pipelines créés avant la mise en veille continuent de s'exécuter.
- La politique reste activée mais dans un état de mise en veille.
- Après l'expiration de la période de mise en veille, l'exécution des pipelines planifiés reprend automatiquement.

### Configuration de la mise en veille {#configuring-snooze}

Pour mettre en veille une politique d'exécution de pipeline planifiée, ajoutez une section `snooze` à la configuration de la planification :

```yaml
pipeline_execution_schedule_policy:
- name: Weekly Security Scan
  description: 'Run security scans every week'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    timezone: UTC
    days:
      - Monday
    snooze:
      until: "2025-06-26T16:27:00+00:00"  # ISO8601 format
      reason: "Critical production deployment"
```

Le paramètre `snooze.until` spécifie quand la période de mise en veille se termine en utilisant le format ISO8601 : `YYYY-MM-DDThh:mm:ss+00:00` où :

- `YYYY-MM-DD` : Année, mois et jour
- `T` : Séparateur entre la date et l'heure
- `hh:mm:ss` : Heures, minutes et secondes au format 24 heures
- `+00:00` : Décalage de fuseau horaire par rapport à UTC (ou Z pour UTC)

Par exemple, `2025-06-26T16:27:00+00:00` représente le 26 juin 2025 à 16 h 27 UTC.

### Suppression d'une mise en veille {#removing-a-snooze}

Pour supprimer une mise en veille avant son expiration, supprimez la section `snooze` de la configuration de la politique ou définissez une date dans le passé pour la valeur `until`.

## Planifier des pipelines pour des branches spécifiques {#schedule-pipelines-for-specific-branches}

Par défaut, les planifications s'exécutent uniquement sur la branche par défaut. Les politiques d'exécution de pipeline planifiées prennent en charge le filtrage par branche, ce qui vous permet de planifier des pipelines pour des branches supplémentaires. Utilisez la propriété `branches` pour effectuer des analyses ou des vérifications régulières sur d'autres branches importantes de votre projet.

Lorsque vous configurez la propriété `branches` dans votre planification :

- Si vous ne spécifiez aucune branche, le pipeline planifié s'exécute uniquement sur la branche par défaut.
- Si vous spécifiez des branches, la politique planifie des pipelines pour chaque branche spécifiée qui existe réellement dans le projet.
- Vous pouvez spécifier un maximum de cinq noms de branches uniques par planification.
- Vous devez spécifier chaque nom de branche en entier. Les correspondances avec des caractères génériques ne sont pas prises en charge.

### Exemple de filtrage par branche {#branch-filtering-example}

```yaml
pipeline_execution_schedule_policy:
- name: Scan Multiple Branches
  description: 'Run security scans on main, staging and develop branches'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    days:
      - Monday
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    branches:
      - main
      - staging
      - develop
      - feature/new-authentication
```

Dans cet exemple, si toutes les branches spécifiées existent dans le projet, la politique crée quatre pipelines distincts (un pour chaque branche).

## Prérequis {#prerequisites}

Pour utiliser les politiques d'exécution de pipeline planifiées, votre projet doit répondre aux exigences suivantes :

- Votre fichier de configuration CI/CD est stocké dans l'un des emplacements suivants :
  - Votre projet de politique de sécurité
  - Un projet public
  - Un projet privé avec l'accès activé (voir [Activer l'accès aux fichiers de configuration CI/CD](#enable-access-to-cicd-configuration-files))
- Votre fichier de configuration CI/CD doit inclure des règles de workflow appropriées pour les pipelines planifiés.

## Activer l'accès aux fichiers de configuration CI/CD {#enable-access-to-cicd-configuration-files}

Lorsque votre politique référence des fichiers de configuration CI/CD, le Security Policy Bot doit y avoir accès. Les fichiers dans les projets publics sont accessibles par défaut. Pour les fichiers dans votre projet de politique de sécurité ou dans d'autres projets privés, activez l'accès en utilisant l'une des options suivantes.

### Option 1 : Accorder l'accès aux fichiers dans le projet de politique de sécurité {#option-1-grant-access-to-files-in-the-security-policy-project}

Si vos fichiers de configuration CI/CD sont stockés dans le projet de politique de sécurité lui-même, utilisez cette option. Ce paramètre s'applique à tout utilisateur qui déclenche un pipeline avec des politiques d'exécution de pipeline injectées.

1. Dans votre projet de politique de sécurité, dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Activez **Accorder l'accès aux configurations CI/CD pour les projets de politiques de sécurité**.
1. Sélectionnez **Sauvegarder les modifications**.

### Option 2 : Autoriser le Security Policy Bot à accéder aux projets privés {#option-2-allow-security-policy-bot-access-to-private-projects}

Si la valeur `include:` de votre politique référence un fichier de configuration CI/CD stocké dans un projet privé autre que le projet de politique de sécurité, utilisez cette option. Ce paramètre s'applique uniquement aux utilisateurs du Security Policy Bot et peut être activé sur n'importe quel projet.

1. Activez la version expérimentale `pipeline_execution_policy_bot_access` dans votre projet de politique de sécurité. Dans le fichier `.gitlab/security-policies/policy.yml`, ajoutez les lignes suivantes :

   ```yaml
   experiments:
     pipeline_execution_policy_bot_access:
       enabled: true
   ```

   > [!note]
   > Votre projet privé ou l'un de ses groupes parents doit être lié à ce projet de politique de sécurité. S'il n'est pas déjà lié, vous devez [lier le projet de politique de sécurité](enforcement/security_policy_projects.md#link-to-a-security-policy-project).

1. Dans le projet privé qui stocke les fichiers CI/CD, dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Dans **Accès des bots chargés de la politique de sécurité**, sélectionnez **Autoriser les bots chargés de la politique de sécurité à accéder aux fichiers de configuration CI/CD de ce projet**.
1. Dans **Schémas de fichiers autorisés**, ajoutez un ou plusieurs schémas glob pour spécifier les fichiers auxquels les bots peuvent accéder, séparés par des virgules.
1. Sélectionnez **Sauvegarder les modifications**.

Les schémas glob pour les fichiers autorisés doivent correspondre aux chemins spécifiés dans la valeur `include:file:`. Par exemple :

- Pour `include:file: ci/security-scan.yml`, utilisez `ci/**/*.yml` ou `ci/security-scan.yml`.
- Pour `include:file: policy-ci.yml`, utilisez `*.yml` ou `policy-ci.yml`.
- Pour plusieurs répertoires, utilisez plusieurs schémas séparés par des virgules, par exemple `ci/**/*.yml, templates/**/*.yml`.

## Utilisateur Security Policy Bot {#security-policy-bot-user}

Les pipelines planifiés sont exécutés par l'utilisateur Security Policy Bot, un compte système dédié que GitLab crée automatiquement pour chaque projet auquel la politique de sécurité s'applique. Pour garantir que l'exécution de la politique reste isolée et sécurisée, l'utilisateur bot présente les restrictions de sécurité suivantes :

- L'utilisateur bot est membre uniquement de ce projet spécifique. Il ne peut pas être ajouté à des groupes ou à d'autres projets.
- L'utilisateur bot peut accéder aux fichiers dans le projet de politique de sécurité et dans les projets publics.
- L'utilisateur bot peut accéder aux fichiers dans les projets privés uniquement si ces projets activent explicitement **Accès des bots chargés de la politique de sécurité** et si le chemin du fichier correspond au schéma spécifié dans le projet.

Étant donné que l'utilisateur bot n'est pas membre d'autres projets, il ne peut effectuer aucune des actions suivantes :

- Accéder aux fichiers de configuration CI/CD provenant de projets privés qui n'autorisent pas l'accès au bot ou ne correspondent pas aux schémas de fichiers autorisés.
- Démarrer des pipelines enfants multi-projets ciblant des projets privés.
- Accéder aux artefacts ou aux ressources provenant de projets privés.

> [!important]
Lorsque vous incluez des fichiers provenant d'un projet privé, activez **Accès des bots chargés de la politique de sécurité** dans ce projet privé et définissez des schémas de fichiers correspondants. Sans ces paramètres, l'exécution du pipeline échoue avec une erreur d'accès.

## Limites de planification {#scheduling-limits}

Cette fonctionnalité est expérimentale et peut être modifiée dans les futures versions. Prenez également connaissance des limites suivantes lors de la création de politiques d'exécution de pipeline planifiées :

- Le nombre maximum de politiques d'exécution de pipeline planifiées par projet de politique de sécurité est limité à une politique avec une planification.
- La fréquence maximale des planifications est d'une fois par jour (quotidienne).
- Si aucune branche n'est spécifiée, les politiques d'exécution de pipeline planifiées s'exécutent uniquement sur la branche par défaut.
- Vous pouvez spécifier jusqu'à cinq noms de branches uniques dans le tableau `branches`.
- Les fenêtres temporelles doivent être d'au moins 10 minutes (600 secondes) pour garantir une distribution suffisante des pipelines.
- Les pipelines planifiés peuvent être retardés si le nombre de runners disponibles est insuffisant.

## Dépannage {#troubleshooting}

Si vos pipelines planifiés ne s'exécutent pas comme prévu, suivez ces étapes de dépannage :

1. **Vérifier le feature flag en phase expérimentale** : Assurez-vous que l'indicateur `pipeline_execution_schedule_policy: enabled: true` est défini dans la section `experiments` de votre fichier `policy.yml`.
1. **Vérifier l'accès aux politiques** : Vérifiez que :
   - Le fichier de configuration CI/CD se trouve dans le projet de politique de sécurité, dans un projet public, ou dans un projet privé avec l'accès bot activé et des schémas de fichiers correspondants.
   - Le paramètre **Stratégies d'exécution des pipelines** est activé dans le projet de politique de sécurité (**Paramètres** > **Général** > **Visibilité, fonctionnalités du projet, autorisations**).
1. **Valider la configuration CI** :
   - Vérifiez que le fichier de configuration CI/CD existe au chemin spécifié.
   - Vérifiez que la configuration est valide en exécutant un pipeline manuel.
   - Assurez-vous que la configuration inclut des règles de workflow appropriées pour les pipelines planifiés.
1. **Vérifier la configuration des politiques** :
   - Assurez-vous que la politique est activée (`enabled: true`).
   - Vérifiez que la configuration de la planification a le format correct et des valeurs valides.
   - Si vous avez spécifié des branches, vérifiez qu'elles existent dans le projet.
   - Vérifiez que le paramètre de fuseau horaire est correct (si spécifié).
1. **Vérifier les logs et l'activité** :
   - Consultez les journaux de pipeline CI/CD du projet de politique de sécurité pour détecter d'éventuelles erreurs.
1. **Vérifier la disponibilité des runners** :
   - Assurez-vous que les runners sont disponibles et configurés correctement.
   - Vérifiez que les runners ont la capacité de gérer les jobs planifiés.
