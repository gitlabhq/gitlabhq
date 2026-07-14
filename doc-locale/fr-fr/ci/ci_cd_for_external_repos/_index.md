---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD pour les dépôts externes
description: "Utilisez GitLab CI/CD avec GitHub, Bitbucket et d'autres dépôts externes."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD peut être utilisé avec [GitHub](github_integration.md), [Bitbucket Cloud](bitbucket_integration.md) ou tout autre serveur Git. Certains [problèmes connus](#known-issues) existent.

Au lieu de migrer l'intégralité de votre projet vers GitLab, vous pouvez connecter votre dépôt externe pour bénéficier des avantages de GitLab CI/CD.

La connexion d'un dépôt externe configure la [mise en miroir du dépôt](../../user/project/repository/mirror/_index.md) et crée un projet léger avec les tickets, les merge requests, le wiki et les extraits de code désactivés. Ces fonctionnalités [peuvent être réactivées ultérieurement](../../user/project/settings/_index.md#configure-project-features-and-permissions).

## Se connecter à un dépôt externe {#connect-to-an-external-repository}

Pour vous connecter à un dépôt externe :

1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
1. Sélectionnez **Exécuter CI/CD pour un dépôt externe**.
1. Sélectionnez **GitHub** ou **Dépôt par URL**.
1. Remplissez les champs.

Si l'option **Exécuter CI/CD pour un dépôt externe** n'est pas disponible :

- L'instance GitLab ne dispose peut-être d'aucune source d'importation configurée. Demandez à un administrateur de vérifier la [configuration des sources d'importation](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).
- La [mise en miroir de projet](../../user/project/repository/mirror/_index.md) est peut-être désactivée. Si elle est désactivée, seuls les administrateurs peuvent utiliser l'option **Exécuter CI/CD pour un dépôt externe**. Demandez à un administrateur de vérifier la [configuration de la mise en miroir de projet](../../administration/settings/visibility_and_access_controls.md#enable-project-mirroring).

## Pipelines pour les pull requests externes {#pipelines-for-external-pull-requests}

Lorsque vous utilisez GitLab CI/CD avec un [dépôt externe sur GitHub](github_integration.md), il est possible d'exécuter un pipeline dans le contexte d'une pull request.

Lorsque vous poussez des modifications vers une branche distante dans GitHub, GitLab CI/CD peut exécuter un pipeline pour la branche. Cependant, lorsque vous ouvrez ou mettez à jour une pull request pour cette branche, vous pouvez souhaiter :

- Exécuter des jobs supplémentaires.
- Ne pas exécuter certains jobs spécifiques.

Par exemple :

```yaml
always-run:
  script: echo 'this should always run'

on-pull-requests:
  script: echo 'this should run on pull requests'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"

except-pull-requests:
  script: echo 'This should not run for pull requests, but runs in other cases.'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"
      when: never
    - when: on_success
```

### Exécution de pipeline pour les pull requests externes {#pipeline-execution-for-external-pull-requests}

Lorsqu'un dépôt est importé depuis GitHub, GitLab s'abonne aux webhooks pour les événements `push` et `pull_request`. Dès qu'un événement `pull_request` est reçu, les données de la pull request sont stockées et conservées comme référence. Si la pull request vient d'être créée, GitLab crée immédiatement un pipeline pour la pull request externe.

Si des modifications sont poussées vers la branche référencée par la pull request et que celle-ci est toujours ouverte, un pipeline pour la pull request externe est créé.

GitLab CI/CD crée 2 pipelines dans ce cas. Un pour le push de branche et un pour la pull request externe.

Une fois la pull request fermée, aucun pipeline n'est créé pour la pull request externe, même si de nouvelles modifications sont poussées vers la même branche.

### Variables prédéfinies supplémentaires {#additional-predefined-variables}

En utilisant des pipelines pour les pull requests externes, GitLab expose des [variables prédéfinies](../variables/predefined_variables.md) supplémentaires aux jobs du pipeline.

Les noms de variables sont préfixés par `CI_EXTERNAL_PULL_REQUEST_`.

### Problèmes connus {#known-issues}

Cette fonctionnalité ne prend pas en charge :

- La [méthode de connexion manuelle](github_integration.md#connect-manually) requise pour GitHub Enterprise. Si l'intégration est connectée manuellement, les pull requests externes [ne déclenchent pas de pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/323336#note_884820753).
- Les pull requests provenant de dépôts dupliqués. [Les pull requests provenant de dépôts dupliqués sont ignorées](https://gitlab.com/gitlab-org/gitlab/-/issues/5667).

Étant donné que GitLab crée deux pipelines, si des modifications sont poussées vers une branche distante référençant une pull request ouverte, les deux contribuent au statut de la pull request via l'intégration GitHub. Si vous souhaitez exécuter des pipelines exclusivement sur les pull requests externes et non sur les branches, vous pouvez ajouter `except: [branches]` aux spécifications du job. [En savoir plus](https://gitlab.com/gitlab-org/gitlab/-/issues/24089#workaround).

## Dépannage {#troubleshooting}

- [La mise en miroir pull ne déclenche pas de pipelines](../../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines).
- [Corriger les échecs critiques lors de la mise en miroir](../../user/project/repository/mirror/pull.md#fix-hard-failures-when-mirroring).
