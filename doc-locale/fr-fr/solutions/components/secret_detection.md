---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Configurez la détection des secrets GitLab avec des ensembles de règles personnalisés centralisés pour détecter automatiquement les données PII et les mots de passe en clair dans tous les projets d'un groupe principal."
title: Détection des secrets
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Prise en main {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique en ligne de composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

### Prérequis {#prerequisites}

- Édition GitLab Ultimate
- Accès administrateur à votre instance ou groupe GitLab
- [Détection des secrets](../../user/application_security/secret_detection/_index.md) activée pour vos projets

## Configurer des règles personnalisées de détection des secrets {#configure-secret-detection-custom-rules}

Ce guide vous aide à mettre en œuvre une politique de détection des secrets au niveau global. Cette solution étend les règles de détection des secrets par défaut pour inclure la détection des éléments de données PII tels que le numéro de sécurité sociale et les mots de passe en clair. L'extension de règle est considérée comme l'ensemble de règles distant.

### Configurer l'ensemble de règles personnalisé {#configure-custom-ruleset}

Vous pouvez configurer un ensemble de règles personnalisé en suivant les étapes ci-dessous

1. Créez un groupe principal `Secret Detection`
1. Depuis votre composant téléchargé, copiez le projet `Secret Detection Custom Ruleset` dans votre groupe principal `Secret Detection` nouvellement créé.

Cet ensemble de règles personnalisé étend les règles pré-construites de GitLab. L'extension peut détecter et signaler des secrets, notamment :

- Éléments de données PII : numéro de sécurité sociale
- Mots de passe en clair.

#### Fichier d'ensemble de règles personnalisé {#custom-ruleset-file}

L'ensemble de règles personnalisé est défini dans `.gitlab/secret-detection-ruleset.toml` Les règles peuvent être définies à l'aide de `regex`

#### Détection des éléments de données PII {#pii-data-element-detection}

Les règles étendues pour la détection des éléments de données PII

```toml
[[rules]]
id = "ssn"
description = "Social Security Number"
regex = "[0-9]{3}-[0-9]{2}-[0-9]{4}"
tags = ["ssn", "social-security-number"]
keywords = ["ssn"]
```

#### Mot de passe en clair {#password-in-plain-text}

Les règles étendues pour les mots de passe en clair

```toml
[[rules]]
id = "password-secret"
description = "Detect secrets starting with Password or PASSWORD"
regex = "(?i)Password[:=]\\s*['\"]?[^'\"]+['\"]?"
tags = ["password", "secret"]
keywords = ["password", "PASSWORD"]
```

### Accéder à l'ensemble de règles personnalisé défini {#access-defined-custom-ruleset}

Pour accéder à l'ensemble de règles personnalisé, vous devez créer un jeton d'accès de groupe qui génère un utilisateur bot. L'utilisateur bot peut être utilisé pour authentifier et accéder à l'ensemble de règles personnalisé par tout projet qui exécute la détection des secrets avec la politique globale.

Pour configurer l'accès et l'authentification, suivez ces étapes :

1. Créez un jeton de groupe : dans le groupe `Secret Detection`, créez un jeton d'accès de groupe `Secret Detection Group Token` sous l'option de menu `Settings`, attribuez au jeton le rôle `reporter` avec l'accès `read_repository`

![Security Dashboard](img/secret_detection_group_token_v17_9.png)

1. Créez une variable de groupe : copiez la valeur du jeton et conservez-la en lieu sûr. Ajoutez une variable de groupe sous l'option de menu `Settings` appelée `SECRET_DETECTION_GROUP_TOKEN` comme clé avec la valeur du jeton.
1. Obtenez l'utilisateur bot du jeton de groupe : dans le même groupe, accédez à l'option de menu `manage` pour sélectionner `member` et recherchez l'utilisateur bot correspondant pour le jeton d'accès de groupe `Secrete Detection Group Token`, copiez la valeur représentant l'utilisateur bot pour le groupe au format `@group_[group_id]_bot_[random_number]`

![Bot du jeton de groupe de détection des secrets](img/secret_detection_group_token_bot_v17_9.png)

## Guide d'implémentation {#implementation-guide}

Ce guide décrit les étapes de configuration de la politique pour exécuter la détection des secrets pour tous les projets à l'aide d'un ensemble de règles personnalisé centralisé.

### Configurer la politique de détection des secrets {#configure-secret-detection-policy}

Pour exécuter la détection des secrets automatiquement dans le pipeline en tant que politique globale appliquée, configurez la politique au niveau le plus élevé (dans ce cas, pour le groupe principal). Pour créer la nouvelle politique de détection des secrets :

1. Créez la politique : dans le même groupe `Secret Detection`, accédez à la page **Sécurisation** > **Politiques** de ce groupe.
1. Sélectionnez **Nouvelle politique**.
1. Sélectionnez **Politique d'exécution d'analyses**.
1. Configurez la politique : donnez à la politique le nom `Secret Detection Policy`, saisissez une description et sélectionnez le scan `Secret Detection`
1. Définissez la **Portée de la stratégie** en sélectionnant soit « Tous les projets de ce groupe » (et définissez éventuellement des exceptions) soit « Projets spécifiques » (et sélectionnez les projets dans la liste déroulante).
1. Dans la section **Actions**, la détection des secrets est affichée par défaut.
1. Dans la section **Conditions**, vous pouvez éventuellement remplacer « Déclencheurs : » par « Planifications : » si vous souhaitez exécuter le scan selon un calendrier plutôt qu'à chaque commit.
1. Configurez l'accès à l'ensemble de règles personnalisé : ajoutez des variables CI avec la valeur de l'utilisateur bot, la variable de groupe et l'URL du projet d'ensemble de règles personnalisé.

   L'ensemble de règles personnalisé est hébergé dans un projet différent et considéré comme l'ensemble de règles distant ; la variable `SECRET_DETECTION_RULESET_GIT_REFERENCE` doit donc être utilisée.

   ```yaml
   variables:
     SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@[custom ruleset project URL]"
     SECRET_DETECTION_HISTORIC_SCAN: "true"
   ```

La configuration de l'interface est affichée sur cet écran : ![Security Dashboard](img/secret_detection_policy_v17_9.png) Pour des informations détaillées sur cette variable CI, consultez [ce document pour plus de détails](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset).

1. Cliquez sur **Créer une stratégie**.

### Configuration complète de la politique {#complete-policy-configuration}

Après la création de la politique, voici, à titre de référence, la configuration complète de la politique :

```yaml
---
scan_execution_policy:
- name: Scan execution for secret detection with custom rules
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branches:
    - "*"
  actions:
  - scan: secret_detection
    variables:
      SECRET_DETECTION_RULESET_GIT_REFERENCE: "@group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@gitlab.com/example_group/secret-detection/secret-detection-custom-ruleset"
      SECRET_DETECTION_HISTORIC_SCAN: 'true'
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy: []
```

## Fonctionnement {#how-it-works}

Une fois la politique en cours d'exécution, tous les projets associés à la politique globale auront le job `secret detect` qui s'exécutera automatiquement dans le pipeline en tant que job `secret_detection_0`. ![Security Dashboard](img/secret_detection_job_v17_9.png)

Les secrets seront détectés et mis en évidence. S'il existe une merge request, les nouveaux secrets nets seront affichés dans l'onglet **Rapports**. Si c'est la branche par défaut qui est fusionnée, ils seront affichés dans le rapport de vulnérabilité de sécurité comme suit : ![Résultats des vulnérabilités liées aux mots de passe détectés par la détection des secrets](img/secret_detection_pwd_vuln_v17_9.png)

Voici un exemple de mot de passe en clair : ![Résultats de la détection des mots de passe par la détection des secrets](img/secret_detection_pwd_v17_9.png)

## Dépannage {#troubleshooting}

### Politique non appliquée {#policy-not-applying}

Assurez-vous que le projet de politique de sécurité que vous avez modifié est correctement lié à votre groupe. Consultez [Lier à un projet de politique de sécurité](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project) pour en savoir plus.
