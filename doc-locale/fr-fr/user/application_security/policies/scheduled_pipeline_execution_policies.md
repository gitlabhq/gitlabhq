---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Politiques d'exécution des pipelines planifiées"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/14147) en version expérimentale dans GitLab 18.0 avec un feature flag nommé `scheduled_pipeline_execution_policy_type`, défini dans le fichier `policy.yml`.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238197) en version bêta dans GitLab 18.2.
- [Passage en disponibilité générale](https://gitlab.com/groups/gitlab-org/-/work_items/17875) dans GitLab 19.2.

{{< /history >}}

Les politiques d'exécution de pipeline imposent l'exécution de jobs CI/CD personnalisés dans les pipelines de vos projets. Avec les politiques d'exécution des pipelines planifiées, vous pouvez étendre cette mise en application. Le job CI/CD s'exécute alors à intervalles réguliers (quotidiennement, hebdomadairement ou mensuellement), et les scripts de conformité, les analyses de sécurité ou les autres jobs CI/CD personnalisés s'exécutent même en l'absence de nouveaux commits.

## Planifier vos politiques d'exécution de pipeline {#scheduling-your-pipeline-execution-policies}

Contrairement aux politiques d'exécution de pipeline classiques qui injectent ou remplacent des jobs dans des pipelines existants, les politiques planifiées créent de nouveaux pipelines qui s'exécutent indépendamment selon la planification que vous définissez. Les pipelines planifiés sont distincts du fichier `.gitlab-ci.yml` de votre projet et n'exécutent aucun des jobs CI/CD du projet.

Les cas d'utilisation courants sont les suivants :

- Appliquer des analyses de sécurité à intervalles réguliers pour respecter les exigences de conformité
- Vérifier périodiquement les configurations du projet
- Exécuter des analyses de dépendances sur des dépôts inactifs afin de détecter les vulnérabilités nouvellement découvertes
- Exécuter des scripts de reporting de conformité selon une planification

## Tester une politique d'exécution de pipeline planifiée {#test-a-scheduled-pipeline-execution-policy}

Avant d'activer une politique d'exécution de pipeline planifiée pour l'ensemble des projets, vous pouvez exécuter un test afin de vérifier le fonctionnement du pipeline et de comprendre l'incidence de la politique sur votre infrastructure. L'exécution de test lance de véritables pipelines et fournit des estimations précises de durée et de ressources.

> [!note]
> Les exécutions de test créent de véritables pipelines et consomment les minutes de calcul du projet cible.

Pour exécuter un test :

1. Dans la barre latérale gauche, sélectionnez **Sécurité** > **Politiques**.
1. Sélectionnez la politique d'exécution de pipeline planifiée que vous souhaitez tester.
1. Sélectionnez l'onglet **Exécutions de test**.
1. Si vous consultez la politique au niveau du groupe, sélectionnez un projet cible dans la liste déroulante.
1. Sélectionnez **Démarrer l'exécution de test**.

L'exécution de test crée un pipeline sur le projet sélectionné en utilisant la configuration CI/CD de la politique. Vous pouvez surveiller le statut de l'exécution de test dans l'onglet **Exécutions de test**.

Une fois l'exécution de test terminée, l'onglet **Exécutions de test** affiche le résultat, notamment la durée et les éventuels messages d'erreur.

## Configurer les politiques d'exécution des pipelines planifiées {#configure-schedule-pipeline-execution-policies}

Pour configurer une politique d'exécution de pipeline planifiée, ajoutez des champs de configuration supplémentaires à la section `pipeline_execution_schedule_policy` du fichier `.gitlab/security-policies/policy.yml` de votre projet de politique de sécurité :

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

Dans la section `schedules`, vous configurez le moment où les jobs de politique de sécurité s'exécutent automatiquement. Vous pouvez créer des planifications quotidiennes, hebdomadaires ou mensuelles avec des heures d'exécution et des fenêtres de répartition précises.

### Options de configuration des planifications {#schedules-configuration-options}

La section `schedules` prend en charge les options suivantes :

| Paramètre | Description |
|-----------|-------------|
| `type` | Type de planification : `daily`, `weekly` ou `monthly` |
| `start_time` | Heure de début de la planification au format 24 heures (HH:MM) |
| `time_window` | Fenêtre temporelle de répartition des exécutions de pipeline |
| `time_window.value` | Durée en secondes (minimum : 600, maximum : 2629746) |
| `time_window.distribution` | Méthode de répartition (actuellement, seule `random` est prise en charge) |
| `timezone` | Identifiant de fuseau horaire IANA (UTC par défaut si aucune valeur n'est spécifiée) |
| `branches` | Tableau facultatif contenant les noms des branches pour lesquelles planifier des pipelines. Si `branches` est spécifié, les pipelines s'exécutent uniquement sur les branches indiquées, et seulement si elles existent dans le projet. Si aucune branche n'est spécifiée, les pipelines s'exécutent uniquement sur la branche par défaut. Vous pouvez indiquer jusqu'à cinq noms de branches uniques par planification. |
| `days` | À utiliser uniquement avec les planifications hebdomadaires : Tableau des jours d'exécution de la planification (par exemple, `["Monday", "Friday"]`) |
| `days_of_month` | À utiliser uniquement avec les planifications mensuelles : Tableau des dates d'exécution de la planification (par exemple, `[1, 15]`, valeurs possibles de 1 à 31) |
| `snooze` | Configuration facultative de mise en veille temporaire de la planification |
| `snooze.until` | Date et heure ISO 8601 auxquelles la planification reprend après la mise en veille (format : `2025-06-13T20:20:00+00:00`) |
| `snooze.reason` | Documentation facultative indiquant pourquoi la planification est mise en veille |

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

Pour éviter de surcharger votre infrastructure CI/CD lorsque vous appliquez des politiques à plusieurs projets, les politiques d'exécution des pipelines planifiées répartissent la création des pipelines sur une fenêtre temporelle, selon des règles communes :

- Tous les pipelines sont planifiés selon la méthode `random`. Les pipelines sont répartis aléatoirement pendant la fenêtre temporelle spécifiée.
- La fenêtre temporelle minimale est de 10 minutes (600 secondes) et la fenêtre maximale est d'environ 1 mois (2 629 746 secondes).
- Pour les planifications mensuelles, si vous spécifiez des dates qui n'existent pas certains mois (comme le 31 en février), ces exécutions sont ignorées.
- Un projet de politique de sécurité peut contenir jusqu'à cinq politiques d'exécution des pipelines planifiées.
- Une politique planifiée ne peut avoir qu'une seule configuration de planification à la fois.
- Une politique planifiée peut cibler jusqu'à cinq branches. Si vous omettez `branches`, la politique s'exécute uniquement sur la branche par défaut du projet.
- Lorsque vous appliquez une politique à plusieurs projets, veillez à ce que votre fenêtre temporelle soit suffisamment large pour absorber le nombre de projets, en fonction de la capacité disponible de vos runners. Par exemple, une politique appliquée à 1 000 projets avec une fenêtre temporelle d'une heure répartit la création des pipelines uniformément pendant cette heure (environ 16 pipelines par minute). Vérifiez que vos runners peuvent prendre en charge ce rythme de création de pipelines, ou choisissez une fenêtre temporelle plus large pour éviter les files d'attente ou les retards.
- Pour les planifications mensuelles, l'intervalle entre des exécutions consécutives peut varier en raison de la distribution aléatoire pendant la fenêtre temporelle. Par exemple, une planification mensuelle peut s'exécuter 20 jours après l'exécution précédente, puis 30 jours plus tard. Cette répartition correspond au comportement attendu, car elle répartit la charge sur votre infrastructure.

## Mettre en veille les politiques d'exécution des pipelines planifiées {#snooze-scheduled-pipeline-execution-policies}

Vous pouvez mettre temporairement en veille les politiques d'exécution des pipelines planifiées à l'aide de la fonctionnalité de mise en veille. Utilisez la fonctionnalité de mise en veille pendant les fenêtres de maintenance, les jours fériés ou lorsque vous devez empêcher l'exécution des pipelines planifiés pendant une période donnée.

### Fonctionnement de la mise en veille {#how-snoozing-works}

Lorsque vous mettez en veille une politique d'exécution de pipeline planifiée :

- Aucun nouveau pipeline planifié n'est créé pendant la période de mise en veille.
- Les pipelines créés avant la mise en veille continuent de s'exécuter.
- La politique reste activée, mais elle est en veille.
- À l'expiration de la période de mise en veille, l'exécution des pipelines planifiés reprend automatiquement.

### Configurer la mise en veille {#configuring-snooze}

Pour mettre en veille une politique d'exécution de pipeline planifiée, ajoutez une section `snooze` à la configuration de la planification :

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

Le paramètre `snooze.until` indique la date et l'heure de fin de la période de mise en veille au format ISO 8601 : `YYYY-MM-DDThh:mm:ss+00:00`, où :

- `YYYY-MM-DD` : Année, mois et jour
- `T` : Séparateur entre la date et l'heure
- `hh:mm:ss` : Heures, minutes et secondes au format 24 heures
- `+00:00` : Décalage de fuseau horaire par rapport à UTC (ou Z pour UTC)

Par exemple, `2025-06-26T16:27:00+00:00` représente le 26 juin 2025 à 16 h 27 UTC.

### Supprimer une mise en veille {#removing-a-snooze}

Pour supprimer une mise en veille avant son heure d'expiration, supprimez la section `snooze` de la configuration de la politique ou définissez une date passée pour la valeur `until`.

## Contrôler l'accès aux variables CI/CD {#control-access-to-cicd-variables}

Par défaut, les jobs des politiques d'exécution de pipeline planifiées ne peuvent pas accéder aux variables CI/CD de projet ou de groupe. Cette valeur par défaut sécurisée empêche les politiques d'exposer involontairement des configurations de projet sensibles.

Pour autoriser les jobs de politique à accéder aux variables CI/CD de projet et de groupe, ajoutez l'option `variables_override` à votre configuration de politique :

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Security Scan
  description: 'Run security scans with access to project variables'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  variables_override:
    allowed: true
  schedules:
  - type: daily
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
```

### Options de configuration de `variables_override` {#variables_override-configuration-options}

| Paramètre | Description |
|-----------|-------------|
| `allowed` | Requis. Lorsque `true`, les jobs de politique peuvent accéder aux variables CI/CD de projet et de groupe. Lorsque `false`, bloque l'accès à ces variables. |
| `exceptions` | Facultatif. Un tableau de noms de variables exemptées de l'application. Lorsque `allowed: true`, les variables de cette liste sont bloquées. Lorsque `allowed: false`, les variables de cette liste sont autorisées. |
| `dotenv` | Facultatif. Contrôle si les variables d'artéfact dotenv respectent les règles de politique. Définissez sur `allow_override` pour permettre aux variables dotenv de contourner les règles de politique. Le comportement par défaut respecte les règles de politique. |

### Exemples de `variables_override` {#variables_override-examples}

Bloquer toutes les variables de projet sauf des variables spécifiques :

```yaml
variables_override:
  allowed: false
  exceptions:
    - DEPLOY_TOKEN
    - API_KEY
```

Autoriser toutes les variables de projet sauf les variables sensibles :

```yaml
variables_override:
  allowed: true
  exceptions:
    - SECRET_KEY
    - PRIVATE_TOKEN
```

## Planifier des pipelines pour des branches spécifiques {#schedule-pipelines-for-specific-branches}

Par défaut, les planifications s'exécutent uniquement sur la branche par défaut. Les politiques d'exécution des pipelines planifiées prennent en charge le filtrage par branche. Vous pouvez ainsi planifier des pipelines pour d'autres branches. Utilisez la propriété `branches` pour effectuer régulièrement des analyses ou des vérifications sur d'autres branches importantes de votre projet.

Lorsque vous configurez la propriété `branches` dans votre planification :

- Si vous ne spécifiez aucune branche, le pipeline planifié s'exécute uniquement sur la branche par défaut.
- Si vous spécifiez des branches, la politique planifie des pipelines pour chaque branche spécifiée qui existe effectivement dans le projet.
- Vous pouvez spécifier jusqu'à cinq noms de branches uniques par planification.
- Vous devez spécifier chaque nom de branche en entier. La mise en correspondance avec des caractères génériques n'est pas prise en charge.

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

Pour utiliser les politiques d'exécution des pipelines planifiées, votre projet doit satisfaire aux exigences suivantes :

- Votre fichier de configuration CI/CD est stocké dans l'un des emplacements suivants :
  - Votre projet de politique de sécurité
  - Un projet public
  - Un projet privé dont l'accès est activé (voir [Activer l'accès aux fichiers de configuration CI/CD](#enable-access-to-cicd-configuration-files))
- Votre fichier de configuration CI/CD doit inclure des règles de workflow appropriées pour les pipelines planifiés.

## Activer l'accès aux fichiers de configuration CI/CD {#enable-access-to-cicd-configuration-files}

Lorsque votre politique fait référence à des fichiers de configuration CI/CD, le Security Policy Bot doit y avoir accès. Les fichiers dans les projets publics sont accessibles par défaut. Pour les fichiers stockés dans votre projet de politique de sécurité ou dans d'autres projets privés, activez l'accès au moyen de l'une des options suivantes.

### Option 1 : Accorder l'accès aux fichiers dans le projet de politique de sécurité {#option-1-grant-access-to-files-in-the-security-policy-project}

Si vos fichiers de configuration CI/CD sont stockés dans le projet de politique de sécurité lui-même, utilisez cette option. Ce paramètre s'applique à tout utilisateur qui déclenche un pipeline dans lequel des politiques d'exécution de pipeline sont injectées.

1. Dans votre projet de politique de sécurité, dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Activez **Accorder l'accès aux configurations CI/CD pour les projets de politiques de sécurité**.
1. Sélectionnez **Enregistrer les modifications**.

### Option 2 : autoriser l'accès aux projets privés ou internes {#option-2-allow-access-to-private-or-internal-projects}

Si la valeur `include:` de votre politique fait référence à un fichier de configuration CI/CD stocké dans un projet privé ou interne autre que le projet de politique de sécurité, utilisez cette option.

1. Dans le projet privé ou interne qui stocke les fichiers CI/CD, dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Dans **Stratégies d'exécution des pipelines**, sélectionnez **Allow access to CI/CD configuration files in this project**.
1. Dans **Schémas de fichiers autorisés**, ajoutez un ou plusieurs schémas glob pour spécifier les fichiers accessibles, séparés par des virgules.
1. Facultatif. Dans **Groupe autorisé**, sélectionnez un groupe pour autoriser uniquement les utilisateurs des projets de ce groupe à accéder aux fichiers de configuration CI/CD.

   Si aucun groupe n'est spécifié, les utilisateurs de tout projet dans le groupe ancêtre racine peuvent accéder aux fichiers.
1. Sélectionnez **Enregistrer les modifications**.

Les schémas glob des fichiers autorisés doivent correspondre aux chemins spécifiés dans la valeur `include:file:`. Par exemple :

- Pour `include:file: ci/security-scan.yml`, utilisez `ci/**/*.yml` ou `ci/security-scan.yml`.
- Pour `include:file: policy-ci.yml`, utilisez `*.yml` ou `policy-ci.yml`.
- Pour plusieurs répertoires, utilisez plusieurs schémas séparés par des virgules, par exemple `ci/**/*.yml, templates/**/*.yml`.

## Utilisateur Security Policy Bot {#security-policy-bot-user}

L'utilisateur Security Policy Bot exécute les pipelines planifiés. Il s'agit d'un compte système dédié que GitLab crée automatiquement pour chaque projet auquel la politique de sécurité s'applique. Pour que l'exécution de la politique reste isolée et sécurisée, l'utilisateur bot est soumis aux restrictions de sécurité suivantes :

- L'utilisateur bot est membre de ce projet uniquement. Il ne peut pas être ajouté à des groupes ou à d'autres projets.
- L'utilisateur bot est traité comme un utilisateur externe et, par défaut, ne peut pas accéder aux projets internes.
- L'utilisateur bot peut accéder aux fichiers du projet de politique de sécurité et des projets publics.
- Le compte du bot peut accéder aux fichiers dans des projets privés ou internes uniquement si ces projets activent explicitement le paramètre **Stratégies d'exécution des pipelines** et si le chemin du fichier correspond au schéma spécifié dans le projet.

Comme l'utilisateur bot n'est pas membre des autres projets, il ne peut effectuer aucune des actions suivantes :

- Accéder aux fichiers de configuration CI/CD à partir de projets privés ou internes qui n'autorisent pas l'accès ou ne correspondent pas aux schémas de fichiers autorisés.
- Démarrer des pipelines enfants multi-projets qui ciblent des projets privés ou internes
- Accéder aux artefacts ou aux ressources des projets privés ou internes

> [!important]
Lorsque vous incluez des fichiers provenant d'un projet privé ou interne, activez le paramètre **Stratégies d'exécution des pipelines** dans ce projet et définissez des schémas de fichiers correspondants. Sans ces paramètres, l'exécution du pipeline échoue avec une erreur d'accès.

## Limites de planification {#scheduling-limits}

Tenez compte des limites suivantes lorsque vous créez des politiques d'exécution des pipelines planifiées :

- Le nombre maximal de politiques d'exécution des pipelines planifiées par projet de politique de sécurité est limité à une seule politique dotée d'une seule planification.
- La fréquence maximale des planifications est d'une exécution par jour (quotidienne).
- Si aucune branche n'est spécifiée, les politiques d'exécution des pipelines planifiées s'exécutent uniquement sur la branche par défaut.
- Vous pouvez spécifier jusqu'à cinq noms de branches uniques dans le tableau `branches`.
- Les fenêtres temporelles doivent durer au moins 10 minutes (600 secondes) pour que les pipelines soient suffisamment répartis.
- Les pipelines planifiés peuvent prendre du retard si le nombre de runners disponibles est insuffisant.

## Dépannage {#troubleshooting}

### La première exécution planifiée peut être retardée {#first-scheduled-run-may-be-delayed}

Lorsque vous créez ou mettez à jour une politique d'exécution de pipeline planifiée, un processus en arrière-plan crée l'enregistrement de planification de manière asynchrone. Si la file d'attente du processus en arrière-plan subit des retards (par exemple, en raison d'une charge système élevée), le processus en arrière-plan peut créer l'enregistrement de planification après que l'heure de la première exécution prévue soit dépassée. Dans ce cas, la première exécution se produit à la prochaine occurrence planifiée plutôt qu'immédiatement.

Par exemple, si vous créez une politique à 14 h 00 pour une exécution à 18 h 00, mais que le processus en arrière-plan ne traite la politique qu'à 19 h 00, la première exécution est planifiée pour 18 h 00 le jour suivant (ou le prochain jour applicable en fonction de votre configuration de planification).

Pour contourner ce comportement :

- Créez les politiques bien à l'avance par rapport à l'heure de la première exécution prévue.
- Utilisez la [fonctionnalité de test](#test-a-scheduled-pipeline-execution-policy) pour vérifier que la politique fonctionne correctement avant la première exécution planifiée.

### Les pipelines planifiés ne s'exécutent pas {#scheduled-pipelines-not-running}

Si vos pipelines planifiés ne s'exécutent pas comme prévu, suivez les étapes de dépannage suivantes :

1. **Vérifier l'accès aux politiques** : Vérifiez que :
   - Le fichier de configuration CI/CD se trouve dans le projet de politique de sécurité, dans un projet public ou dans un projet privé ou interne pour lequel l'accès des bots est activé et les schémas de fichiers correspondent.
   - Le paramètre **Stratégies d'exécution des pipelines** est activé dans le projet de politique de sécurité (**Paramètres** > **Généralités** > **Visibilité, fonctionnalités du projet, autorisations**).
1. **Valider la configuration CI** :
   - Vérifiez que le fichier de configuration CI/CD existe au chemin spécifié.
   - Vérifiez que la configuration est valide en exécutant un pipeline manuel.
   - Assurez-vous que la configuration inclut des règles de workflow adaptées aux pipelines planifiés.
1. **Vérifier la configuration des politiques** :
   - Assurez-vous que la politique est activée (`enabled: true`).
   - Vérifiez que la configuration de la planification respecte le format attendu et contient des valeurs valides.
   - Si vous avez spécifié des branches, vérifiez qu'elles existent dans le projet.
   - Vérifiez que le paramètre de fuseau horaire est correct, s'il est spécifié.
1. **Vérifier les logs et l'activité** :
   - Consultez les logs du pipeline CI/CD du projet de politique de sécurité pour détecter d'éventuelles erreurs.
1. **Vérifier la disponibilité des runners** :
   - Assurez-vous que les runners sont disponibles et correctement configurés.
   - Vérifiez que les runners disposent de la capacité nécessaire pour gérer les jobs planifiés.
