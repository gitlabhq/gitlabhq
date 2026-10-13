---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes de sécurité des applications
description: "Comment résoudre les problèmes liés aux fonctionnalités de sécurité des applications GitLab, y compris comment obtenir une journalisation plus détaillée."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez les fonctionnalités de sécurité des applications, vous pouvez rencontrer les problèmes suivants.

## Niveau de journalisation {#logging-level}

Le niveau de détail des journaux générés par les analyseurs GitLab est déterminé par la variable d'environnement `SECURE_LOG_LEVEL`. Les messages correspondant à ce niveau de journalisation ou à un niveau supérieur sont générés en sortie.

Du niveau de gravité le plus élevé au plus bas, les niveaux de journalisation sont :

- `fatal`
- `error`
- `warn`
- `info` (par défaut)
- `debug`

### Activer la journalisation au niveau débogage {#turn-on-debug-level-logging}

> [!warning]
> La journalisation de débogage peut constituer un risque de sécurité sérieux. La sortie peut contenir le contenu des variables d'environnement et d'autres secrets disponibles pour le job. La sortie est téléversée sur le serveur GitLab et est visible dans les job logs.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour activer la journalisation au niveau débogage, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

Cela indique à tous les analyseurs GitLab qu'ils doivent produire tous les messages en sortie. Pour plus de détails, voir [niveau de journalisation](#logging-level).

<!--
The below subsection(`### Secure job failing with exit code 1`) documentation URL is referred
in the [`/gitlab-org/security-products/analyzers/command`](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/command.go#L19)
repository. If this section/subsection changes, ensure to update the corresponding URL in the mentioned
repository.
-->

## Échec d'un job Secure avec le code de sortie 1 {#secure-job-failing-with-exit-code-1}

Si un job Secure échoue et que la raison n'est pas claire :

1. Activez la [journalisation au niveau débogage](#turn-on-debug-level-logging).
1. Exécutez le job.
1. Examinez la sortie du job.
1. Supprimez le niveau de journalisation `debug` pour revenir à la valeur par défaut `info`.

## Rapports de sécurité obsolètes {#outdated-security-reports}

Lorsqu'un rapport de sécurité généré pour une merge request devient obsolète, la merge request affiche un message d'avertissement dans le rapport d'analyse de sécurité et vous invite à prendre une mesure appropriée.

Cela peut se produire dans deux scénarios :

- Votre [branche source est en retard par rapport à la branche cible](#source-branch-is-behind-the-target-branch).
- Le [rapport de sécurité de la branche cible est obsolète](#target-branch-security-report-is-out-of-date).

### La branche source est en retard par rapport à la branche cible {#source-branch-is-behind-the-target-branch}

Un rapport de sécurité peut être obsolète lorsque le commit ancêtre commun le plus récent entre la branche cible et la branche source n'est pas le commit le plus récent sur la branche cible.

Pour résoudre ce problème, effectuez un rebase ou une fusion pour intégrer les modifications de la branche cible.

### Le rapport de sécurité de la branche cible est obsolète {#target-branch-security-report-is-out-of-date}

Cela peut se produire pour de nombreuses raisons, notamment des jobs ayant échoué ou de nouveaux avis de sécurité. Lorsque la merge request indique qu'un rapport de sécurité est obsolète, vous devez exécuter un nouveau pipeline sur la branche cible. Sélectionnez **new pipeline** pour exécuter un nouveau pipeline.

## Obtention de messages d'avertissement `… report.json: no matching files` {#getting-warning-messages--reportjson-no-matching-files}

> [!warning]
> La journalisation de débogage peut constituer un risque de sécurité sérieux. La sortie peut contenir le contenu des variables d'environnement et d'autres secrets disponibles pour le job. La sortie est téléversée sur le serveur GitLab et est visible dans les job logs.

Ce message est souvent suivi de l'[erreur `No files to upload`](../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload), et précédé d'autres erreurs ou avertissements indiquant pourquoi le rapport JSON n'a pas été généré. Vérifiez l'intégralité du job log pour trouver de tels messages. Si vous ne trouvez pas ces messages, relancez le job ayant échoué après avoir défini `SECURE_LOG_LEVEL: "debug"` en tant que [variable CI/CD personnalisée](../../ci/variables/_index.md#for-a-project). Cela fournit des informations supplémentaires pour approfondir l'investigation.

## Obtention du message d'erreur `sast job: config key may not be used with 'rules': only/except` {#getting-error-message-sast-job-config-key-may-not-be-used-with-rules-onlyexcept}

Lors de l'[inclusion](../../ci/yaml/_index.md#includetemplate) d'un modèle `.gitlab-ci.yml` tel que [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml), l'erreur suivante peut se produire selon votre configuration GitLab CI/CD :

```plaintext
Unable to run pipeline

    jobs:sast config key may not be used with `rules`: only/except
```

Cette erreur apparaît lorsque la configuration `rules` du job inclus a été [remplacée](sast/_index.md#override-sast-jobs) par [la syntaxe dépréciée `only` ou `except`.](../../ci/yaml/deprecated_keywords.md#only--except) Pour résoudre ce problème, vous devez soit :

- [Migrer votre syntaxe `only/except` vers `rules`](#transitioning-your-onlyexcept-syntax-to-rules).
- (Temporairement) [Épingler vos modèles aux versions dépréciées](#pin-your-templates-to-the-deprecated-versions)

Pour plus d'informations, voir [Remplacement des jobs SAST](sast/_index.md#override-sast-jobs).

### Migration de votre syntaxe `only/except` vers `rules` {#transitioning-your-onlyexcept-syntax-to-rules}

Lors du remplacement du modèle pour contrôler l'exécution des jobs, les instances précédentes de [`only` ou `except`](../../ci/yaml/deprecated_keywords.md#only--except) ne sont plus compatibles et doivent être migrées vers [la syntaxe `rules`](../../ci/yaml/_index.md#rules).

Si votre remplacement vise à limiter les jobs pour qu'ils s'exécutent uniquement sur `main`, la syntaxe précédente ressemblerait à ceci :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  only:
    refs:
      - main
      - merge_requests
```

Pour migrer la configuration précédente vers la nouvelle syntaxe `rules`, le remplacement serait rédigé comme suit :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_ID
```

Si votre remplacement vise à limiter les jobs pour qu'ils s'exécutent uniquement sur les branches, et non sur les tags, cela ressemblerait à ceci :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  except:
    - tags
```

Pour migrer vers la nouvelle syntaxe `rules`, le remplacement serait réécrit comme suit :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_TAG == null
```

Pour plus d'informations, consultez [`rules`](../../ci/yaml/_index.md#rules).

### Épingler vos modèles aux versions dépréciées {#pin-your-templates-to-the-deprecated-versions}

Pour bénéficier du support le plus récent, migrez vers [`rules`](../../ci/yaml/_index.md#rules).

Si vous ne pouvez pas mettre à jour immédiatement votre configuration CI/CD, il existe plusieurs solutions de contournement impliquant d'épingler les versions précédentes des modèles, par exemple :

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

En outre, un projet dédié contenant les modèles hérités versionnés est disponible. Celui-ci peut être utilisé pour des configurations hors ligne ou pour toute personne souhaitant utiliser [Auto DevOps](../../topics/autodevops/_index.md).

Les instructions sont disponibles dans le [projet de modèles hérités](https://gitlab.com/gitlab-org/auto-devops-v12-10).

### Des vulnérabilités sont détectées, mais le job réussit. Comment faire échouer un pipeline à la place ? {#vulnerabilities-are-found-but-the-job-succeeds-how-can-you-have-a-pipeline-fail-instead}

Dans ces circonstances, la réussite du job est le comportement par défaut. Le statut du job indique la réussite ou l'échec de l'analyseur lui-même. Les résultats de l'analyseur sont affichés dans les [job logs](../../ci/jobs/job_logs.md#expand-and-collapse-job-log-sections), les [rapports de merge request](../project/merge_requests/reports.md) ou le [tableau de bord de sécurité](security_dashboard/_index.md).

## Erreur : job `is used for configuration only, and its script should not be executed` {#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed}

Les modèles `Security/Dependency-Scanning.gitlab-ci.yml` et `Security/SAST.gitlab-ci.yml` impliquent que si vous activez les jobs `sast` ou `dependency_scanning` en définissant l'attribut `rules`, ils échouent avec l'erreur `(job) is used for configuration only, and its script should not be executed`.

Les stances `sast` ou `dependency_scanning` peuvent être utilisées pour apporter des modifications à l'ensemble du SAST ou de l'analyse des dépendances, comme la modification de `variables` ou du `stage`, mais elles ne peuvent pas être utilisées pour définir des `rules` partagées.

Il [existe un ticket ouvert pour améliorer l'extensibilité](https://gitlab.com/gitlab-org/gitlab/-/issues/218444). Vous pouvez voter pour ce ticket afin d'aider à la priorisation, et [les contributions sont les bienvenues](https://about.gitlab.com/community/contribute/).

## Rapport de vulnérabilités vide, pages de liste des dépendances {#empty-vulnerability-report-dependency-list-pages}

Si le pipeline comporte des étapes manuelles avec un job ayant l'option `allow_failure: false`, et que ce job n'est pas terminé, GitLab ne peut pas alimenter les pages répertoriées avec les données des rapports de sécurité. Dans ce cas, [le rapport de vulnérabilités](vulnerability_report/_index.md) et [la liste des dépendances](dependency_list/_index.md) sont vides. Ces pages de sécurité peuvent être alimentées en exécutant les jobs depuis l'étape manuelle du pipeline.

Il [existe un ticket ouvert pour gérer ce scénario](https://gitlab.com/gitlab-org/gitlab/-/issues/346843). Vous pouvez voter pour ce ticket afin d'aider à la priorisation, et [les contributions sont les bienvenues](https://about.gitlab.com/community/contribute/).
