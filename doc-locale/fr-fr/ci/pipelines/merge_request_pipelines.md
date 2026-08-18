---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment utiliser les pipelines de merge request dans GitLab CI/CD pour tester les modifications efficacement, exécuter des jobs ciblés et améliorer la qualité du code avant la fusion."
title: Pipelines de merge request
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez configurer votre pipeline pour qu'il s'exécute chaque fois que vous apportez des modifications à la branche source dans un merge request. Ce type de pipeline est appelé pipeline de merge request.

Ces pipelines s'exécutent lorsque vous :

- Créez un nouveau merge request depuis une branche source comportant un ou plusieurs commits.
- Poussez un nouveau commit vers la branche source pour un merge request.
- Accédez à l'onglet **Pipelines** dans un merge request et sélectionnez **Exécuter le pipeline**.

Les pipelines de merge request :

- S'exécutent uniquement sur le contenu de la branche source et ignorent le contenu de la branche cible.
- Affichent un label `merge request` dans les listes de pipelines.

Pour exécuter un pipeline qui teste le résultat de la fusion des branches source et cible, utilisez les [pipelines de résultats fusionnés](merged_results_pipelines.md).

## Prérequis {#prerequisites}

Pour utiliser les pipelines de merge request :

- Le fichier `.gitlab-ci.yml` de votre projet doit inclure des règles de job ou des règles de workflow correspondant à `CI_PIPELINE_SOURCE == "merge_request_event"`.
- Vous devez avoir le rôle Developer, Maintainer ou Owner pour le projet source afin d'exécuter un pipeline de merge request.
- Votre dépôt doit être un dépôt GitLab, et non un [dépôt externe](../ci_cd_for_external_repos/_index.md).

## Configurer les pipelines de merge request {#configure-merge-request-pipelines}

Pour configurer les pipelines de merge request, vous devez configurer les jobs dans votre fichier `.gitlab-ci.yml` pour qu'ils s'exécutent lorsque `CI_PIPELINE_SOURCE` est égal à `merge_request_event`.

> [!note]
> Les règles définies dans `include:` (par exemple, avec `include:component`) ne satisfont pas à cette exigence. Vous devez définir des `rules:` ou `workflow: rules` correspondants directement dans `.gitlab-ci.yml`.

Vous pouvez configurer des jobs individuels avec `rules`, ou utiliser `workflow: rules` pour contrôler l'ensemble du pipeline.

### Configurer des jobs individuels {#configure-individual-jobs}

Utilisez le mot-clé [`rules`](../yaml/_index.md#rules) pour configurer des jobs individuels à exécuter dans les pipelines de merge request. Par exemple :

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Vous pouvez également contrôler le moment où les jobs s'exécutent en fonction des modifications de fichiers :

```yaml
test:
  script:
    - echo "This job always runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

lint:
  script:
    - echo "This job runs only when JavaScript files change"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "*.js"
```

### Configurer l'ensemble du pipeline {#configure-the-entire-pipeline}

Utilisez le mot-clé [`workflow: rules`](../yaml/_index.md#workflowrules) pour configurer tous les jobs d'un pipeline à exécuter dans les pipelines de merge request. Par exemple :

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

job1:
  script:
    - echo "This job runs in merge request pipelines"
```

Pour plus d'exemples sur `workflow`, consultez :

- [Basculer entre les pipelines de branche et les pipelines de merge request](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)
- [Git Flow avec les pipelines de merge request](../yaml/workflow.md#git-flow-with-merge-request-pipelines)

Pour [utiliser les outils d'analyse de sécurité avec les pipelines de merge request](../../user/application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines), utilisez la variable CI/CD `AST_ENABLE_MR_PIPELINES` ou l'édition de template `latest`.

## Exécuter un pipeline de merge request avec des entrées personnalisées {#run-a-merge-request-pipeline-with-custom-inputs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/547861) dans GitLab 18.11.

{{< /history >}}

Si votre fichier `.gitlab-ci.yml` définit des [entrées de pipeline](../inputs/_index.md), vous pouvez personnaliser les valeurs d'entrée lorsque vous exécutez manuellement un nouveau pipeline de merge request. Vous pouvez également définir des [variables CI/CD](../variables/_index.md) dans le même formulaire.

Prérequis :

- Votre fichier `.gitlab-ci.yml` doit être [configuré pour les pipelines de merge request](#configure-merge-request-pipelines).
- Votre fichier `.gitlab-ci.yml` doit également définir une section `spec: inputs`.
- Vous devez avoir au minimum le rôle Developer pour le projet source.

Pour exécuter un pipeline de merge request avec des entrées personnalisées :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Sélectionnez **Code** > **Requêtes de fusion** et ouvrez votre merge request.
1. Sélectionnez l'onglet **Pipelines**.
1. Sélectionnez la liste déroulante **Exécuter le pipeline** ({{< icon name="chevron-down" >}}) et choisissez **Exécuter le pipeline avec les valeurs modifiées**.
1. Le nouveau formulaire de pipeline s'ouvre et est pré-rempli avec la branche source du merge request. Modifiez les valeurs d'entrée et définissez les variables CI/CD nécessaires.
1. Sélectionnez **Exécuter le pipeline**.

## Utilisation avec des projets dupliqués {#use-with-forked-projects}

Les contributeurs externes qui travaillent dans des duplications ne peuvent pas créer de pipelines dans le projet parent.

Un merge request issu d'une duplication soumis au projet parent déclenche un pipeline qui :

- Est créé et s'exécute dans le projet de duplication (source), et non dans le projet parent (cible).
- Utilise la configuration CI/CD, les ressources et les variables CI/CD du projet de duplication.

Les pipelines des duplications s'affichent avec le badge **bifurcation** dans le projet parent.

### Exécuter des pipelines dans le projet parent {#run-pipelines-in-the-parent-project}

Les membres du projet parent peuvent déclencher un pipeline de merge request pour un merge request soumis depuis un projet dupliqué. Ce pipeline :

- Est créé et s'exécute dans le projet parent (cible), et non dans le projet de duplication (source).
- Utilise la configuration CI/CD présente dans la branche du projet de duplication.
- Utilise les paramètres CI/CD, les ressources et les variables CI/CD du projet parent.
- Utilise les autorisations du membre du projet parent qui déclenche le pipeline.

Exécutez des pipelines dans les MR du projet dupliqué pour vous assurer que le pipeline post-fusion réussit dans le projet parent. De plus, si vous ne faites pas confiance au runner du projet dupliqué, l'exécution du pipeline dans le projet parent utilise les runners de confiance du projet parent.

> [!warning]
> Les merge requests issus de duplications peuvent contenir du code malveillant qui tente de voler des secrets dans le projet parent lors de l'exécution du pipeline, même avant la fusion. En tant que relecteur, vérifiez soigneusement les modifications du merge request avant de déclencher le pipeline. Sauf si vous déclenchez le pipeline via l'API ou l'[action rapide `/rebase`](../../user/project/quick_actions.md#rebase), GitLab affiche un avertissement que vous devez accepter avant l'exécution du pipeline. Dans le cas contraire, **no warning displays**.

Prérequis :

- Le fichier `.gitlab-ci.yml` du projet parent doit être configuré pour [exécuter des jobs dans les pipelines de merge request](#prerequisites).
- Vous devez être membre du projet parent avec les [autorisations pour exécuter des pipelines CI/CD](../../user/permissions.md#project-cicd). Des autorisations supplémentaires peuvent être nécessaires si la branche est protégée.
- Le projet dupliqué doit être [visible](../../user/public_access.md) par l'utilisateur qui exécute le pipeline. Dans le cas contraire, l'onglet **Pipelines** ne s'affiche pas dans le merge request.

Pour utiliser l'interface utilisateur afin d'exécuter un pipeline dans le projet parent pour un merge request issu d'un projet dupliqué :

1. Dans le merge request, accédez à l'onglet **Pipelines**.
1. Sélectionnez **Exécuter le pipeline**. Vous devez lire et accepter l'avertissement, sinon le pipeline ne s'exécutera pas.

### Empêcher les pipelines issus de projets dupliqués {#prevent-pipelines-from-fork-projects}

Pour empêcher les utilisateurs d'exécuter de nouveaux pipelines pour des projets dupliqués dans le projet parent, utilisez [l'API des projets](../../api/projects.md#update-a-project) pour désactiver le paramètre `ci_allow_fork_pipelines_to_run_in_parent_project`.

> [!warning]
> Les pipelines créés avant la désactivation du paramètre ne sont pas concernés et continuent de s'exécuter. Si vous réexécutez un job dans un pipeline plus ancien, le job utilise le même contexte que lors de la création initiale du pipeline.

## Variables prédéfinies disponibles {#available-predefined-variables}

Lorsque vous utilisez des pipelines de merge request, vous pouvez utiliser :

- Toutes les [variables prédéfinies](../variables/predefined_variables.md) disponibles dans les pipelines de branche.
- Les [variables prédéfinies supplémentaires](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) disponibles uniquement pour les jobs dans les pipelines de merge request.

## Contrôler l'accès aux variables protégées et aux runners protégés {#control-access-to-protected-variables-and-runners}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188008) dans GitLab 18.1

{{< /history >}}

Vous pouvez contrôler l'accès aux [variables CI/CD protégées](../variables/_index.md#protect-a-cicd-variable) et aux [runners protégés](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information) depuis les pipelines de merge request.

Les pipelines de merge request ne peuvent accéder à ces ressources protégées que lorsque :

- Les branches source et cible sont toutes deux [protégées](../../user/project/repository/branches/protected.md).
- L'utilisateur déclenchant le pipeline dispose d'un accès push/merge vers la branche cible.
- Les branches source et cible appartiennent toutes deux au même projet.

Les pipelines de merge request issus de dépôts dupliqués ne peuvent pas accéder à ces ressources protégées.

Prérequis :

- Avoir le rôle Maintainer ou Owner dans le projet.

Pour contrôler l'accès aux variables protégées et aux runners protégés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sous **Accéder aux ressources protégées dans les pipelines de requêtes de fusion**, cochez ou décochez la case **Autoriser les pipelines de requêtes de fusion à accéder aux variables et runners protégés**.
