---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Débogage des pipelines CI/CD
description: "Validation de la configuration, avertissements, erreurs et dépannage."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab propose plusieurs outils pour faciliter le débogage de votre configuration CI/CD.

Si vous ne parvenez pas à résoudre les problèmes de pipeline, vous pouvez obtenir de l'aide auprès de :

- Le [forum de la communauté GitLab](https://forum.gitlab.com/)
- GitLab [Support](https://support.gitlab.com/)

Si vous rencontrez des problèmes avec une fonctionnalité CI/CD spécifique, consultez la section de dépannage correspondante :

- [Mise en cache](caching/_index.md#troubleshooting)
- [Jetons de job CI/CD](jobs/ci_job_token.md#troubleshooting)
- [Registre de conteneurs](../user/packages/container_registry/troubleshoot_container_registry.md)
- [Docker](docker/docker_build_troubleshooting.md)
- [Pipelines downstream](pipelines/downstream_pipelines_troubleshooting.md)
- [Environnements](environments/_index.md#troubleshooting)
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)
- [Jetons d'ID](secrets/id_token_authentication.md#troubleshooting)
- [Jobs](jobs/job_troubleshooting.md)
- [Artefacts de job](jobs/job_artifacts_troubleshooting.md)
- [Pipelines de merge request](pipelines/mr_pipeline_troubleshooting.md), [pipelines de résultats fusionnés](pipelines/merged_results_pipelines.md#troubleshooting) et [merge trains](pipelines/merge_trains.md#troubleshooting)
- [Éditeur de pipeline](pipeline_editor/_index.md#troubleshooting)
- [Variables](variables/variables_troubleshooting.md)
- [Mot-clé YAML `includes`](yaml/includes.md#troubleshooting)
- [Mot-clé YAML `script`](yaml/script_troubleshooting.md)

## Techniques de débogage {#debugging-techniques}

### Vérifier la syntaxe {#verify-syntax}

Une syntaxe incorrecte peut être une source précoce de problèmes. Le pipeline affiche un badge `yaml invalid` et ne démarre pas si des problèmes de syntaxe ou de formatage sont détectés.

#### Modifier `.gitlab-ci.yml` avec l'éditeur de pipeline {#edit-gitlab-ciyml-with-the-pipeline-editor}

L'[éditeur de pipeline](pipeline_editor/_index.md) est l'expérience d'édition recommandée (plutôt que l'éditeur de fichier unique ou le Web IDE). Il inclut :

- Des suggestions de complétion de code qui garantissent que vous n'utilisez que des mots-clés acceptés.
- La mise en évidence syntaxique automatique et la validation.
- La [visualisation de la configuration CI/CD](pipeline_editor/_index.md#visualize-ci-configuration), une représentation graphique de votre fichier `.gitlab-ci.yml`.

#### Modifier `.gitlab-ci.yml` localement {#edit-gitlab-ciyml-locally}

Si vous préférez modifier votre configuration de pipeline localement, vous pouvez utiliser le schéma GitLab CI/CD dans votre éditeur pour vérifier les problèmes de syntaxe de base. Tout [éditeur prenant en charge Schemastore](https://www.schemastore.org/) utilise le schéma GitLab CI/CD par défaut.

Si vous devez créer un lien direct vers le schéma, utilisez cette URL :

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

Pour consulter la liste complète des balises personnalisées couvertes par le schéma CI/CD, vérifiez la dernière version du schéma.

#### Vérifier la syntaxe avec l'outil CI Lint {#verify-syntax-with-ci-lint-tool}

Vous pouvez utiliser l'[outil CI Lint](yaml/lint.md) pour vérifier que la syntaxe d'un extrait de configuration CI/CD est correcte. Collez des fichiers `.gitlab-ci.yml` complets ou des configurations de job individuelles pour vérifier la syntaxe de base.

Lorsqu'un fichier `.gitlab-ci.yml` est présent dans un projet, vous pouvez également utiliser l'outil CI Lint pour [simuler la création d'un pipeline complet](yaml/lint.md#simulate-a-pipeline). Il effectue une vérification plus approfondie de la syntaxe de configuration.

### Utiliser des noms de pipeline {#use-pipeline-names}

Utilisez [`workflow:name`](yaml/_index.md#workflowname) pour attribuer des noms à tous vos types de pipeline, ce qui facilite leur identification dans la liste des pipelines. Par exemple :

```yaml
variables:
  PIPELINE_NAME: "Default pipeline name"

workflow:
  name: '$PIPELINE_NAME'
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PIPELINE_NAME: "Merge request pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule" && $PIPELINE_SCHEDULE_TYPE == "hourly_deploy"'
      variables:
        PIPELINE_NAME: "Hourly deployment pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      variables:
        PIPELINE_NAME: "Other scheduled pipeline"
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      variables:
        PIPELINE_NAME: "Default branch pipeline"
    - if: '$CI_COMMIT_BRANCH =~ /^\d{1,2}\.\d{1,2}-stable$/'
      variables:
        PIPELINE_NAME: "Stable branch pipeline"
```

### Variables CI/CD {#cicd-variables}

#### Vérifier les variables {#verify-variables}

La vérification des variables présentes dans un pipeline et de leurs valeurs est un élément clé du dépannage CI/CD. Une grande partie de la configuration de pipeline dépend des variables, et les vérifier est l'un des moyens les plus rapides de trouver la source d'un problème.

[Exportez la liste complète des variables](variables/variables_troubleshooting.md#list-all-variables) disponibles dans chaque job problématique. Vérifiez si les variables attendues sont présentes et si leurs valeurs correspondent à ce que vous attendez.

#### Utiliser des variables pour ajouter des indicateurs aux commandes CLI {#use-variables-to-add-flags-to-cli-commands}

Vous pouvez définir des variables CI/CD qui ne sont pas utilisées lors des exécutions de pipeline standard, mais qui peuvent être utilisées pour le débogage à la demande. Si vous ajoutez une variable comme dans l'exemple suivant, vous pouvez l'ajouter lors des exécutions manuelles du [pipeline](pipelines/_index.md#run-a-pipeline-manually) ou d'un [job individuel](jobs/job_control.md#run-a-manual-job) pour modifier le comportement de la commande. Par exemple :

```yaml
my-flaky-job:
  variables:
    DEBUG_VARS: ""
  script:
    - my-test-command $DEBUG_VARS /test-dirs
```

Dans cet exemple, `DEBUG_VARS` est vide par défaut dans les pipelines standard. Si vous devez déboguer le comportement du job, exécutez le pipeline manuellement et définissez `DEBUG_VARS` sur `--verbose` pour obtenir des informations supplémentaires.

### Dépendances {#dependencies}

Les problèmes liés aux dépendances constituent une autre source courante de problèmes inattendus dans les pipelines.

#### Vérifier les versions des dépendances {#verify-dependency-versions}

Pour valider que les versions correctes des dépendances sont utilisées dans les jobs, vous pouvez les afficher avant d'exécuter les commandes de script principales. Par exemple :

```yaml
job:
  before_script:
    - node --version
    - yarn --version
  script:
    - my-javascript-tests.sh
```

#### Épingler les versions {#pin-versions}

Bien que vous souhaitiez toujours utiliser la dernière version d'une dépendance ou d'une image, une mise à jour pourrait inclure des changements incompatibles de façon inattendue. Envisagez d'épingler les dépendances et les images clés pour éviter les changements inattendus. Par exemple :

```yaml
variables:
  ALPINE_VERSION: '3.18.6'

job1:
  image: alpine:$ALPINE_VERSION  # This will never change unexpectedly
  script:
    - my-test-script.sh

job2:
  image: alpine:latest  # This might suddenly change
  script:
    - my-test-script.sh
```

Vous devez tout de même vérifier régulièrement les mises à jour des dépendances et des images, car celles-ci peuvent contenir des correctifs de sécurité importants. Vous pouvez ensuite mettre à jour manuellement la version dans le cadre d'un processus qui vérifie que l'image ou la dépendance mise à jour fonctionne toujours avec votre pipeline.

### Vérifier la sortie du job {#verify-job-output}

#### Rendre la sortie verbeuse {#make-output-verbose}

Si vous utilisez `--silent` pour réduire la quantité de sortie dans un job log, cela peut rendre difficile l'identification de ce qui s'est passé dans un job. De plus, envisagez d'utiliser `--verbose` lorsque cela est possible, pour obtenir des détails supplémentaires.

```yaml
job1:
  script:
    - my-test-tool --silent         # If this fails, it might be impossible to identify the issue.
    - my-other-test-tool --verbose  # This command will likely be easier to debug.
```

#### Enregistrer les sorties et les rapports en tant qu'artefacts {#save-output-and-reports-as-artifacts}

Certains outils peuvent générer des fichiers qui ne sont nécessaires que pendant l'exécution du job, mais le contenu de ces fichiers pourrait être utilisé pour le débogage. Vous pouvez les enregistrer pour une analyse ultérieure avec [`artifacts`](yaml/_index.md#artifacts) :

```yaml
job1:
  script:
    - my-tool --json-output my-output.json
  artifacts:
    paths:
      - my-output.json
```

Les rapports configurés avec [`artifacts:reports`](yaml/artifacts_reports.md) ne sont pas disponibles en téléchargement par défaut, mais peuvent également contenir des informations utiles au débogage. Utilisez la même technique pour rendre ces rapports disponibles à l'inspection :

```yaml
job1:
  script:
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
    paths:
      - rspec.xmp
```

> [!warning]
> N'enregistrez pas de jetons, de mots de passe ou d'autres informations sensibles dans les artefacts, car ils pourraient être consultés par tout utilisateur ayant accès aux pipelines.

### Exécuter les commandes du job localement {#run-the-jobs-commands-locally}

Vous pouvez utiliser un outil comme [Rancher Desktop](https://rancherdesktop.io/) ou des alternatives similaires pour exécuter l'image de conteneur du job sur votre machine locale. Ensuite, exécutez les commandes `script` du job dans le conteneur et vérifiez le comportement.

### Dépanner un job en échec avec l'analyse de cause racine {#troubleshoot-a-failed-job-with-root-cause-analysis}

Vous pouvez utiliser GitLab Duo Root Cause Analysis dans GitLab Duo Chat pour [dépanner les jobs CI/CD en échec](../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## Problèmes de configuration de job {#job-configuration-issues}

De nombreux problèmes de pipeline courants peuvent être résolus en analysant le comportement de la configuration `rules` ou `only/except` utilisée pour [contrôler l'ajout des jobs à un pipeline](jobs/job_control.md). Vous ne devez pas utiliser ces deux configurations dans le même pipeline, car elles se comportent différemment. Il est difficile de prédire comment un pipeline s'exécute avec ce comportement mixte. `rules` est le choix privilégié pour contrôler les jobs, car `only` et `except` ne sont plus activement développés.

Si votre configuration `rules` ou `only/except` utilise des [variables prédéfinies](variables/predefined_variables.md) telles que `CI_PIPELINE_SOURCE`, `CI_MERGE_REQUEST_ID`, vous devez [les vérifier](#verify-variables) en première étape de dépannage.

### Les jobs ou les pipelines ne s'exécutent pas comme prévu {#jobs-or-pipelines-dont-run-when-expected}

Les mots-clés `rules` ou `only/except` déterminent si un job est ajouté ou non à un pipeline. Si un pipeline s'exécute, mais qu'un job n'est pas ajouté au pipeline, cela est généralement dû à des problèmes de configuration `rules` ou `only/except`.

Si un pipeline ne semble pas s'exécuter du tout, sans message d'erreur, cela peut également être dû à la configuration `rules` ou `only/except`, ou au mot-clé `workflow: rules`.

Si vous convertissez de `only/except` vers le mot-clé `rules`, vous devez vérifier attentivement les [détails de configuration de `rules`](yaml/_index.md#rules). Le comportement de `only/except` et de `rules` est différent et peut entraîner des comportements inattendus lors de la migration entre les deux.

Les [clauses `if` courantes pour `rules`](jobs/job_rules.md#common-if-clauses-with-predefined-variables) peuvent être très utiles pour des exemples de règles se comportant comme prévu.

Si un pipeline contient uniquement des jobs dans les étapes `.pre` ou `.post`, il ne s'exécute pas. Il doit y avoir au moins un autre job dans une étape différente.

### Comportement inattendu lorsque le fichier `.gitlab-ci.yml` contient une marque d'ordre d'octet (BOM) {#unexpected-behavior-when-gitlab-ciyml-file-contains-a-byte-order-mark-bom}

Une [marque d'ordre d'octet (BOM) UTF-8](https://en.wikipedia.org/wiki/Byte_order_mark) dans le fichier `.gitlab-ci.yml` ou dans d'autres fichiers de configuration inclus peut entraîner un comportement incorrect du pipeline. La marque d'ordre d'octet affecte l'analyse du fichier, entraînant l'ignorance de certaines configurations : des jobs peuvent être manquants et des variables peuvent avoir des valeurs incorrectes. Certains éditeurs de texte peuvent insérer un caractère BOM s'ils sont configurés pour le faire.

Si votre pipeline présente un comportement confus, vous pouvez vérifier la présence de caractères BOM à l'aide d'un outil capable de les afficher. L'éditeur de pipeline ne peut pas afficher les caractères, vous devez donc utiliser un outil externe. Consultez le [ticket 354026](https://gitlab.com/gitlab-org/gitlab/-/issues/354026) pour plus de détails.

### Un job avec le mot-clé `changes` s'exécute de façon inattendue {#a-job-with-the-changes-keyword-runs-unexpectedly}

Une raison courante pour laquelle un job est ajouté à un pipeline de façon inattendue est que le mot-clé `changes` est toujours évalué à vrai dans certains cas. Par exemple, `changes` est toujours vrai dans certains types de pipeline, notamment les pipelines planifiés et les pipelines pour les tags.

Le mot-clé `changes` est utilisé en combinaison avec [`only/except`](yaml/deprecated_keywords.md#onlychanges--exceptchanges) ou [`rules`](yaml/_index.md#ruleschanges). Il est recommandé de n'utiliser `changes` qu'avec des sections `if` dans une configuration `rules` ou `only/except` qui garantit que le job n'est ajouté qu'aux pipelines de branche ou aux pipelines de merge request.

### Deux pipelines s'exécutent en même temps {#two-pipelines-run-at-the-same-time}

Deux pipelines peuvent s'exécuter lors d'un push d'un commit vers une branche associée à une merge request ouverte. En général, un pipeline est un pipeline de merge request et l'autre est un pipeline de branche.

Cette situation est généralement causée par la configuration `rules`, et il existe plusieurs façons de [prévenir les pipelines en double](jobs/job_rules.md#avoid-duplicate-pipelines).

### Aucun pipeline ou le mauvais type de pipeline s'exécute {#no-pipeline-or-the-wrong-type-of-pipeline-runs}

Avant qu'un pipeline puisse s'exécuter, GitLab évalue tous les jobs de la configuration et tente de les ajouter à tous les types de pipeline disponibles. Un pipeline ne s'exécute pas si aucun job n'y est ajouté à la fin de l'évaluation.

Si un pipeline ne s'est pas exécuté, il est probable que tous les jobs avaient des configurations `rules` ou `only/except` qui les empêchaient d'être ajoutés au pipeline.

Si le mauvais type de pipeline s'est exécuté, la configuration `rules` ou `only/except` doit être vérifiée pour s'assurer que les jobs sont ajoutés au bon type de pipeline. Par exemple, si un pipeline de merge request ne s'est pas exécuté, les jobs ont peut-être été ajoutés à un pipeline de branche à la place.

Il est également possible que votre configuration [`workflow: rules`](yaml/_index.md#workflow) ait bloqué le pipeline ou autorisé le mauvais type de pipeline.

Si vous utilisez la mise en miroir pull, vous pouvez consulter l'[entrée de dépannage pour les pipelines de mise en miroir pull](../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines).

### Un pipeline comportant de nombreux jobs ne démarre pas {#pipeline-with-many-jobs-fails-to-start}

Un pipeline comportant plus de jobs que les [limites CI/CD](../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline) définies de l'instance ne démarre pas.

Pour réduire le nombre de jobs dans un seul pipeline, vous pouvez diviser votre configuration `.gitlab-ci.yml` en [pipelines parent-enfant](pipelines/pipeline_architectures.md#parent-child-pipelines) plus indépendants.

## Avertissements de pipeline {#pipeline-warnings}

Les avertissements de configuration de pipeline s'affichent lorsque vous :

- [Validez la configuration avec l'outil CI Lint](yaml/lint.md).
- [Exécutez manuellement un pipeline](pipelines/_index.md#run-a-pipeline-manually).

### Avertissement `Job may allow multiple pipelines to run for a single action` {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

Lorsque vous utilisez [`rules`](yaml/_index.md#rules) avec une clause `when` sans clause `if`, plusieurs pipelines peuvent s'exécuter. Cela se produit généralement lorsque vous faites un push d'un commit vers une branche associée à une merge request ouverte.

Pour [prévenir les pipelines en double](jobs/job_rules.md#avoid-duplicate-pipelines), utilisez [`workflow: rules`](yaml/_index.md#workflow) ou réécrivez vos règles pour contrôler quels pipelines peuvent s'exécuter.

## Erreurs de pipeline {#pipeline-errors}

### Erreur : `Identity verification is required in order to run CI jobs` {#error-identity-verification-is-required-in-order-to-run-ci-jobs}

{{< details >}}

- Édition : Gratuite
- Offre : GitLab.com

{{< /details >}}

Lorsque vous utilisez des runners hébergés par GitLab sur GitLab.com avec un abonnement gratuit et que vous voyez un message d'erreur indiquant `Identity verification is required in order to run CI jobs`, vous devez effectuer une vérification d'identité.

Cette exigence aide à prévenir l'abus des ressources de calcul gratuites. En fonction de votre score de risque, vous devrez peut-être vérifier votre adresse e-mail, votre numéro de téléphone ou ajouter un mode de paiement. Pour plus d'informations, consultez la page [vérification d'identité](../security/identity_verification.md).

Pour effectuer la validation :

1. Dans la bannière d'alerte, sélectionnez **Vérifier mon compte**.
1. Lorsque vous y êtes invité, suivez les étapes de vérification d'identité. Il se peut que vous deviez vérifier votre numéro de téléphone ou ajouter un mode de paiement.
1. Créez un nouveau commit ou déclenchez manuellement un nouveau pipeline.

Vous pouvez également :

- Passer à un abonnement payant.
- Acheter des minutes de calcul supplémentaires pour votre espace de nommage.
- Utiliser des runners de projet ou de groupe au lieu des runners hébergés par GitLab.
- Demander à votre propriétaire de groupe de configurer des runners auto-gérés.

### Message `A CI/CD pipeline must run and be successful before merge` {#a-cicd-pipeline-must-run-and-be-successful-before-merge-message}

Ce message s'affiche si le paramètre [**Les pipelines doivent réussir**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activé dans le projet et qu'aucun pipeline n'a encore été exécuté avec succès. Cela s'applique également si le pipeline n'a pas encore été créé ou si vous attendez un service CI externe.

Si vous n'utilisez pas de pipelines pour votre projet, vous devez désactiver **Les pipelines doivent réussir** afin de pouvoir accepter les merge requests.

### Message `Checking ability to merge automatically` {#checking-ability-to-merge-automatically-message}

Si votre merge request est bloquée avec un message `Checking ability to merge automatically` qui ne disparaît pas après quelques minutes, vous pouvez essayer l'une de ces solutions de contournement :

- Actualisez la page de la merge request.
- Fermez et rouvrez la merge request.
- Rebasez la merge request avec l'[action rapide `/rebase`](../user/project/quick_actions.md#rebase).
- Si vous avez déjà confirmé que la merge request est prête à être fusionnée, vous pouvez la fusionner avec l'action rapide `/merge`.

Ce problème est [résolu](https://gitlab.com/gitlab-org/gitlab/-/issues/229352) dans GitLab 15.5.

### Message `Checking pipeline status` {#checking-pipeline-status-message}

Ce message s'affiche avec une icône de statut en rotation ({{< icon name="spinner" >}}) lorsque la merge request n'a pas encore de pipeline associé au dernier commit. Cela peut être dû aux raisons suivantes :

- GitLab n'a pas encore terminé la création du pipeline.
- Vous utilisez un service CI externe et GitLab n'a pas encore reçu de réponse du service.
- Vous n'utilisez pas de pipelines CI/CD dans votre projet.
- Vous utilisez des pipelines CI/CD dans votre projet, mais votre configuration a empêché un pipeline de s'exécuter sur la branche source de votre merge request.
- Le dernier pipeline a été supprimé (il s'agit d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)).
- La branche source de la merge request se trouve sur une duplication privée.

Une fois le pipeline créé, le message se met à jour avec le statut du pipeline.

Dans certains de ces cas, le message peut rester bloqué avec l'icône en rotation sans fin si le paramètre [**Les pipelines doivent réussir**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activé. Consultez le [ticket 334281](https://gitlab.com/gitlab-org/gitlab/-/issues/334281) pour plus de détails.

### Message `Project <group/project> not found or access denied` {#project-groupproject-not-found-or-access-denied-message}

Ce message s'affiche si la configuration est ajoutée avec [`include`](yaml/_index.md#include) et que l'une ou l'autre des conditions suivantes est remplie :

- La configuration fait référence à un projet introuvable.
- L'utilisateur qui exécute le pipeline ne peut pas accéder aux projets inclus.

Pour résoudre ce problème, vérifiez que :

- Le chemin du projet est au format `my-group/my-project` et n'inclut aucun dossier dans le dépôt.
- L'utilisateur qui exécute le pipeline est un [membre des projets](../user/project/members/_index.md#add-users-to-a-project) qui contiennent les fichiers inclus. Les utilisateurs doivent également disposer de la [permission](../user/permissions.md#project-cicd) d'exécuter des jobs CI/CD dans les mêmes projets.

### Message `The parsed YAML is too big` {#the-parsed-yaml-is-too-big-message}

Ce message s'affiche lorsque la configuration YAML est trop volumineuse ou imbriquée trop profondément. Les fichiers YAML comportant un grand nombre d'inclusions et des milliers de lignes au total sont plus susceptibles d'atteindre cette limite mémoire. Par exemple, un fichier YAML de 200 ko est susceptible d'atteindre la limite mémoire par défaut.

Pour réduire la taille de la configuration, vous pouvez :

- Vérifiez la longueur de la configuration CI/CD développée dans l'onglet [Configuration complète](pipeline_editor/_index.md#view-full-configuration) de l'éditeur de pipeline. Recherchez les configurations dupliquées qui peuvent être supprimées ou simplifiées.
- Déplacez les sections `script` longues ou répétées dans des scripts autonomes du projet.
- Utilisez des [pipelines parent et enfant](pipelines/downstream_pipelines.md#parent-child-pipelines) pour déplacer une partie du travail vers des jobs dans un pipeline enfant indépendant.

Sur GitLab Self-Managed, vous pouvez [augmenter les limites de taille](../administration/cicd/limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files).

### Erreur `500` lors de la modification du fichier `.gitlab-ci.yml` {#500-error-when-editing-the-gitlab-ciyml-file}

Une boucle de fichiers de configuration inclus peut provoquer une erreur `500` lors de la modification du fichier `.gitlab-ci.yml` avec l'[éditeur web](../user/project/repository/web_editor.md).

Assurez-vous que les fichiers de configuration inclus ne créent pas de boucle de références entre eux.

### Messages `Failed to pull image` {#failed-to-pull-image-messages}

{{< history >}}

- Le paramètre **Autoriser l'accès à ce projet avec un jeton CI_JOB_TOKEN** [renommé en **Limiter l'accès à ce projet**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) dans GitLab 16.3.

{{< /history >}}

Un runner peut retourner un message `Failed to pull image` lorsqu'il tente de récupérer une image de conteneur dans un job CI/CD.

Le runner s'authentifie avec un [jeton de job CI/CD](jobs/ci_job_token.md) lors de la récupération d'une image de conteneur définie avec [`image`](yaml/_index.md#image) depuis le registre de conteneurs d'un autre projet.

Si les paramètres du jeton de job empêchent l'accès au registre de conteneurs de l'autre projet, le runner retourne un message d'erreur.

Par exemple :

- ```plaintext
  WARNING: Failed to pull image with policy "always": Error response from daemon: pull access denied for registry.example.com/path/to/project, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  ```

- ```plaintext
  WARNING: Failed to pull image with policy "": image pull failed: rpc error: code = Unknown desc = failed to pull and unpack image "registry.example.com/path/to/project/image:v1.2.3": failed to resolve reference "registry.example.com/path/to/project/image:v1.2.3": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  ```

Ces erreurs peuvent survenir si les deux conditions suivantes sont vraies simultanément :

- L'option [**Limit access to this project**](jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects) est activée dans le projet privé hébergeant l'image.
- Le job qui tente de récupérer l'image s'exécute dans un projet qui ne figure pas dans la liste d'autorisation du projet privé.

Pour résoudre ce problème, ajoutez tout projet contenant des jobs CI/CD qui récupèrent des images depuis le registre de conteneurs à la [liste d'autorisation des jetons de job](jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) du projet cible.

Ces erreurs peuvent également se produire lors de l'utilisation d'un [jeton d'accès au projet](../user/project/settings/project_access_tokens.md) pour accéder à des images dans un autre projet. Les jetons d'accès au projet sont limités à un seul projet et ne peuvent donc pas accéder aux images d'autres projets. Vous devez utiliser [un autre type de jeton](../security/tokens/_index.md) avec une portée plus large.

#### Erreurs `Failed to pull image` aléatoires ou intermittentes {#random-or-intermittent-failed-to-pull-image-errors}

Vous pouvez rencontrer des erreurs `Failed to pull image` intermittentes dans vos jobs CI/CD.

Ce problème peut survenir lorsque les utilisateurs ont des permissions différentes pour accéder aux images, combiné à la façon dont les runners mettent en cache ces images. Les utilisateurs bots sont fréquemment concernés car ils ont souvent des permissions différentes de celles des autres membres du projet.

Par exemple, les images de votre pipeline peuvent être hébergées dans un registre de conteneurs dans un projet différent. Si tous les utilisateurs peuvent accéder aux deux projets, ce n'est pas un problème. Cependant, si un utilisateur (comme un utilisateur bot) ne peut pas accéder au projet hébergeant les images, il peut obtenir des erreurs `Failed to pull image`.

L'erreur devient intermittente lorsque le runner récupère et met en cache avec succès l'image pour un utilisateur disposant de la permission d'accéder à l'image. Ce runner dispose maintenant de l'image et n'a pas besoin d'accéder à l'autre projet pour la récupérer. Tous les utilisateurs, y compris ceux sans accès à l'autre projet, peuvent exécuter des jobs CI/CD avec cette image. Cependant, si le runner n'a jamais récupéré et mis en cache l'image, les utilisateurs sans permission d'accéder au projet d'image obtiennent l'erreur `Failed to pull image`.

Pour résoudre ce problème, assurez-vous que tous les utilisateurs qui exécutent des pipelines, y compris les utilisateurs bots, peuvent accéder au projet qui héberge les images récupérées.

### Message `Something went wrong on our end` ou erreur `500` lors de l'exécution d'un pipeline {#something-went-wrong-on-our-end-message-or-500-error-when-running-a-pipeline}

Vous pouvez recevoir les erreurs de pipeline suivantes :

- Un message `Something went wrong on our end` lors d'un push ou de la création de merge requests.
- Une erreur `500` lors de l'utilisation de l'API pour déclencher un pipeline.

Ces erreurs peuvent survenir si les enregistrements des ID internes ne sont plus synchronisés après l'importation d'un projet.

Pour résoudre ce problème, consultez la [solution de contournement dans le ticket 352382](https://gitlab.com/gitlab-org/gitlab/-/issues/352382#workaround).

### Message d'erreur `config should be an array of hashes` {#config-should-be-an-array-of-hashes-error-message}

Vous pouvez voir une erreur similaire à la suivante lors de l'utilisation de plusieurs [balises `!reference`](yaml/yaml_optimization.md#reference-tags) dans un tableau :

```plaintext
This GitLab CI configuration is invalid: jobs:my_job_name:parallel:matrix config should be an array of hashes.
```

Bien que les mots-clés `script`, `rules` et `stages` prennent en charge l'utilisation de plusieurs balises de référence, les autres mots-clés attendant un tableau ne le font pas. Vous pouvez [utiliser l'imbrication pour contourner cette limitation](https://gitlab.com/gitlab-org/gitlab/-/issues/439828#note_1918858137), ou utiliser des [ancres YAML](yaml/yaml_optimization.md#anchors) à la place.

### Erreur : `jobs:<job-name> config should contain either a trigger or a needs:pipeline.` {#error-jobsjob-name-config-should-contain-either-a-trigger-or-a-needspipeline}

Cette erreur peut survenir lorsqu'un job dans votre `.gitlab-ci.yml` utilise le mot-clé `needs`, mais n'utilise pas les mots-clés `script:` ou `trigger:`.

Chaque job doit utiliser soit le mot-clé `script`, soit le mot-clé `trigger`. Ajoutez donc le mot-clé approprié à tout job n'en utilisant aucun.

### Erreur : `config contains unknown keys: <key-name>` {#error-config-contains-unknown-keys-key-name}

Vous pouvez obtenir une erreur similaire à `<keyword> config contains unknown keys: <key-name>`.

Ce message d'erreur peut être causé par plusieurs problèmes :

- Une faute de frappe dans un mot-clé, par exemple `imag` (invalide) au lieu de `image` (valide).
- Un espacement ou une indentation incorrects pour un mot-clé ou un job.

Par exemple :

```yaml
test-job:
  artifacts:
    path:        # This is a typo, it should be `paths`
      - test
    image: test  # This indentation is incorrect, it should be at the same level as `script`.
  script:
    - echo
```
