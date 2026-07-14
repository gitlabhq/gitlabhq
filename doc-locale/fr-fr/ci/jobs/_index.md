---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jobs CI/CD
description: "Configuration, règles, mise en cache, artefacts et journaux."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les jobs CI/CD sont les éléments fondamentaux d'un [pipeline CI/CD GitLab](../pipelines/_index.md). Les jobs sont configurés dans le fichier `.gitlab-ci.yml` avec une liste de commandes à exécuter pour accomplir des tâches telles que la compilation, les tests ou le déploiement de code.

Jobs :

- S'exécutent sur un [runner](../runners/_index.md), par exemple dans un conteneur Docker.
- S'exécutent indépendamment des autres jobs.
- Disposent d'un [job log](job_logs.md) contenant le journal d'exécution complet du job.

Les jobs sont définis avec des [mots-clés YAML](../yaml/_index.md) qui définissent tous les aspects de l'exécution du job, notamment les mots-clés qui :

- Contrôlent [comment](job_control.md) et [quand](job_rules.md) les jobs s'exécutent.
- Regroupent les jobs dans des collections appelées [étapes](../yaml/_index.md#stages). Les étapes s'exécutent en séquence, tandis que tous les jobs d'une étape peuvent s'exécuter en parallèle.
- Définissent des [variables CI/CD](../variables/_index.md) pour une configuration flexible.
- Définissent des [caches](../caching/_index.md) pour accélérer l'exécution des jobs.
- Enregistrent des fichiers en tant qu'[artefacts](job_artifacts.md) pouvant être utilisés par d'autres jobs.

## Ajouter un job à un pipeline {#add-a-job-to-a-pipeline}

Pour ajouter un job à un pipeline, ajoutez-le dans votre fichier `.gitlab-ci.yml`. Le job doit :

- Être défini au niveau supérieur de la configuration YAML.
- Avoir un [nom de job](#job-names) unique.
- Avoir soit une section [`script`](../yaml/_index.md#script) définissant les commandes à exécuter, soit une section [`trigger`](../yaml/_index.md#trigger) pour déclencher un [pipeline downstream](../pipelines/downstream_pipelines.md).

Par exemple :

```yaml
my-ruby-job:
  script:
    - bundle install
    - bundle exec my_ruby_command

my-shell-script-job:
  script:
    - my_shell_script.sh
```

### Noms de jobs {#job-names}

Vous ne pouvez pas utiliser ces mots-clés comme noms de jobs :

- `image`
- `services`
- `stages`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`
- `pages:deploy` configuré pour une étape `deploy`

De plus, ces noms sont valides lorsqu'ils sont entre guillemets, mais ne sont pas recommandés car ils peuvent rendre la configuration du pipeline peu claire :

- `"true":`
- `"false":`
- `"nil":`

Les noms de jobs doivent comporter 255 caractères ou moins.

Utilisez des noms uniques pour vos jobs. Si plusieurs jobs portent le même nom dans un fichier, un seul est ajouté au pipeline et il est difficile de prédire lequel sera choisi. Si le même nom de job est utilisé dans un ou plusieurs fichiers inclus, [les paramètres sont fusionnés](../yaml/includes.md#override-included-configuration-values).

### Masquer un job {#hide-a-job}

Pour désactiver temporairement un job sans le supprimer du fichier de configuration, ajoutez un point (`.`) au début du nom du job. Les jobs masqués n'ont pas besoin de contenir les mots-clés `script` ou `trigger`, mais doivent contenir une configuration YAML valide.

Par exemple :

```yaml
.hidden_job:
  script:
    - run test
```

Les jobs masqués ne sont pas traités par GitLab CI/CD, mais ils peuvent être utilisés comme modèles pour une configuration réutilisable avec :

- Le [mot-clé `extends`](../yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- [Ancres YAML](../yaml/yaml_optimization.md#anchors).

## Définir des valeurs par défaut pour les mots-clés de jobs {#set-default-values-for-job-keywords}

Vous pouvez utiliser le mot-clé `default` pour définir des mots-clés et des valeurs de job par défaut, qui sont utilisés par défaut par tous les jobs d'un pipeline.

Par exemple :

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

rspec-job:
  script: bundle exec rspec
```

Lorsque le pipeline s'exécute, le job utilise les mots-clés par défaut :

```yaml
rspec-job:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World
  script: bundle exec rspec
```

### Contrôler l'héritage des mots-clés et des variables par défaut {#control-the-inheritance-of-default-keywords-and-variables}

Vous pouvez contrôler l'héritage de :

- [Mots-clés par défaut](../yaml/_index.md#default) avec [`inherit:default`](../yaml/_index.md#inheritdefault).
- [Variables par défaut](../yaml/_index.md#default) avec [`inherit:variables`](../yaml/_index.md#inheritvariables).

Par exemple :

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

variables:
  DOMAIN: example.com
  WEBHOOK_URL: https://my-webhook.example.com

rubocop:
  inherit:
    default: false
    variables: false
  script: bundle exec rubocop

rspec:
  inherit:
    default: [image]
    variables: [WEBHOOK_URL]
  script: bundle exec rspec

capybara:
  inherit:
    variables: false
  script: bundle exec capybara

karma:
  inherit:
    default: true
    variables: [DOMAIN]
  script: karma
```

Dans cet exemple :

- `rubocop` :
  - hérite : Rien.
- `rspec` :
  - hérite : la valeur par défaut de `image` et de la variable `WEBHOOK_URL`.
  - n'hérite pas : la valeur par défaut de `before_script` et de la variable `DOMAIN`.
- `capybara` :
  - hérite : les valeurs par défaut de `before_script` et de `image`.
  - n'hérite pas : les variables `DOMAIN` et `WEBHOOK_URL`.
- `karma` :
  - hérite : les valeurs par défaut de `image` et de `before_script`, et la variable `DOMAIN`.
  - n'hérite pas : la variable `WEBHOOK_URL`.

## Afficher les jobs dans un pipeline {#view-jobs-in-a-pipeline}

Lorsque vous accédez à un pipeline, vous pouvez voir les jobs associés à ce pipeline.

L'ordre des jobs dans un pipeline dépend du type de graphe de pipeline.

- Pour les [graphes de pipeline complets](../pipelines/_index.md#pipeline-details), les jobs sont triés par ordre alphabétique par nom.
- Pour les [mini-graphes de pipeline](../pipelines/_index.md#pipeline-mini-graphs), les jobs sont triés par gravité de statut, les jobs en échec apparaissant en premier, puis par ordre alphabétique par nom.

La sélection d'un job individuel affiche son [job log](job_logs.md) et vous permet de :

- Annuler le job.
- Relancer le job s'il a échoué.
- Réexécuter le job s'il a réussi.
- Effacer le job log.

### Afficher les jobs d'un projet {#view-project-jobs}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Filtre par nom de job [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/387547) en tant que [version expérimentale](../../policy/development_stages_support.md) sur GitLab.com et GitLab Self-Managed dans GitLab 17.3 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `populate_and_use_build_names_table` pour l'API et `fe_search_build_by_name` pour l'interface utilisateur. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/512149) dans GitLab 18.5. Les feature flags `populate_and_use_build_names_table` et `fe_search_build_by_name` ont été supprimés.
- Filtre par type de job [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/555434) dans GitLab 18.3.

{{< /history >}}

Pour afficher les jobs exécutés dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Jobs**.

Vous pouvez filtrer la liste par statut de job, source, nom et type.

> [!note]
> Le filtre par nom renvoie les jobs créés au cours des 30 derniers jours. Cette période de rétention s'applique au filtrage via l'interface utilisateur et via l'API.

Par défaut, le filtre affiche uniquement les jobs de build. Pour afficher les jobs déclencheurs, effacez le filtre, puis sélectionnez **Type** > **Déclencheur**.

> [!note]
> Le filtre **Type** est disponible uniquement pour les jobs de projet. Il n'est pas disponible dans la zone **Admin**.

### Statuts de jobs disponibles {#available-job-statuses}

Les jobs CI/CD peuvent avoir les statuts suivants :

- `canceled` : Le job a été annulé manuellement ou abandonné automatiquement.
- `canceling` : Le job est en cours d'annulation, mais `after_script` est en cours d'exécution.
- `created` : Le job a été créé mais n'a pas encore été traité.
- `failed` : L'exécution du job a échoué.
- `manual` : Le job nécessite une action manuelle pour démarrer.
- `pending` : Le job est en file d'attente en attente d'un runner.
- `preparing` : Le runner prépare l'environnement d'exécution.
- `running` : Le job s'exécute sur un runner.
- `scheduled` : Le job a été planifié mais l'exécution n'a pas encore commencé.
- `skipped` : Le job a été ignoré en raison de conditions ou de dépendances.
- `success` : Le job s'est terminé avec succès.
- `waiting_for_callback` : Le job attend un rappel d'un service externe.
- `waiting_for_resource` : Le job attend que des ressources deviennent disponibles.

### Afficher la source d'un job {#view-the-source-of-a-job}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181159) de la source de job dans GitLab 17.9 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `populate_and_use_build_source_table`. Activé par défaut.
- [Disponible en version générale](https://gitlab.com/groups/gitlab-org/-/epics/11796) sur GitLab.com, GitLab Self-Managed et GitLab Dedicated dans GitLab 17.11.

{{< /history >}}

Les jobs GitLab CI/CD incluent un attribut source qui indique l'action qui a déclenché le job. Utilisez cet attribut pour suivre comment un job a été initié ou pour filtrer les exécutions de jobs en fonction de sources spécifiques.

#### Sources de jobs disponibles {#available-job-sources}

L'attribut source peut avoir les valeurs suivantes :

- `api` : Job initié par un appel REST à l'API Jobs.
- `chat` : Job initié par une commande de chat via GitLab ChatOps.
- `container_registry_push` : Job initié par un push vers le registre de conteneurs.
- `duo_workflow` : Job initié par GitLab Duo Agent Platform.
- `external` : Job initié par un événement dans un dépôt externe intégré à GitLab. Cela n'inclut pas les événements de pull request.
- `external_pull_request_event` : Job initié par un événement de pull request dans un dépôt externe.
- `merge_request_event` : Job initié par un événement de merge request.
- `ondemand_dast_scan` : Job initié par un scan DAST à la demande.
- `ondemand_dast_validation` : Job initié par une validation DAST à la demande.
- `parent_pipeline` : Job initié par un pipeline parent
- `pipeline` : Job initié par un utilisateur exécutant manuellement un pipeline.
- `pipeline_execution_policy` : Job initié par une politique d'exécution de pipeline.
- `pipeline_execution_policy_schedule` : Job initié par une politique d'exécution de pipeline planifiée.
- `push` : Job initié par un push de code.
- `scan_execution_policy` : Job initié par une politique d'exécution de scan.
- `schedule` : Job initié par un pipeline planifié.
- `security_orchestration_policy` : Job initié par une politique d'exécution de scan planifiée.
- `trigger` : Job initié par un autre job ou pipeline.
- `unknown` : Job initié par une source inconnue.
- `web` : Job initié par un utilisateur depuis l'interface utilisateur de GitLab.
- `webide` : Job initié par un utilisateur depuis le Web IDE.

### Regrouper des jobs similaires dans les vues de pipeline {#group-similar-jobs-together-in-pipeline-views}

Si vous avez de nombreux jobs similaires, votre [graphe de pipeline](../pipelines/_index.md#pipeline-details) devient long et difficile à lire.

Vous pouvez regrouper automatiquement des jobs similaires. Si les noms de jobs sont formatés d'une certaine manière, ils sont réduits en un seul groupe dans les graphes de pipeline classiques (pas les mini-graphes).

Vous pouvez identifier qu'un pipeline contient des jobs groupés lorsque vous voyez un nombre à côté d'un nom de job au lieu des boutons de relance ou d'annulation. Le nombre indique la quantité de jobs groupés. En les survolant, vous pouvez voir si tous les jobs ont réussi ou si l'un d'eux a échoué. Sélectionnez pour les développer.

![Graphe de pipeline affichant plusieurs étapes et jobs, dont trois groupes de jobs groupés.](img/pipeline_grouped_jobs_v17_9.png)

Pour créer un groupe de jobs, dans le fichier `.gitlab-ci.yml`, séparez chaque nom de job par un nombre et l'un des éléments suivants :

- Une barre oblique avant ou arrière (`/` ou `\`), par exemple, `slash-test 1/3`, `slash-test 2/3`, `slash-test 3/3`.
- Un deux-points (`:`), par exemple, `colon-test 1:3`, `colon-test 2:3`, `colon-test 3:3`.
- Un espace, par exemple `space-test 0 3`, `space-test 1 3`, `space-test 2 3`.

Vous pouvez utiliser ces symboles de manière interchangeable.

Dans l'exemple suivant, ces trois jobs sont dans un groupe nommé `build ruby` :

```yaml
build ruby 1/3:
  stage: build
  script:
    - echo "ruby1"

build ruby 2/3:
  stage: build
  script:
    - echo "ruby2"

build ruby 3/3:
  stage: build
  script:
    - echo "ruby3"
```

Le graphe de pipeline affiche un groupe nommé `build ruby` avec trois jobs.

Les jobs sont ordonnés en comparant les nombres de gauche à droite. En général, vous souhaitez que le premier nombre soit l'index et le second le total.

## Relancer des jobs {#retry-jobs}

Vous pouvez relancer un job après son exécution, quel que soit son état final (échec, succès ou annulé).

Lorsque vous relancez un job :

- Une nouvelle instance de job est créée avec un nouvel identifiant de job.
- Le job s'exécute avec les mêmes paramètres et variables que le job d'origine.
- Si le job produit des artefacts, de nouveaux artefacts sont créés et stockés.
- Le nouveau job est associé à l'utilisateur qui a initié la relance, et non à l'utilisateur qui a créé le pipeline d'origine.
- Tous les jobs suivants qui avaient été précédemment ignorés sont réattribués à l'utilisateur qui a initié la relance.

Lorsque vous relancez un [job déclencheur](../yaml/_index.md#trigger) qui déclenche un pipeline downstream :

- Le job déclencheur génère un nouveau pipeline downstream.
- Le pipeline downstream est également associé à l'utilisateur qui a initié la relance.
- Le pipeline downstream s'exécute avec la configuration qui existe au moment de la relance, qui peut être différente de l'exécution d'origine.

### Relancer un job {#retry-a-job}

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.
- Le job ne doit pas être [archivé](../../administration/settings/continuous_integration.md#archive-pipelines).

Pour relancer un job depuis une merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Depuis votre merge request, effectuez l'une des opérations suivantes :
   - Dans le widget de pipeline, à côté du job que vous souhaitez relancer, sélectionnez **Réexécuter** ({{< icon name="retry" >}}).
   - Sélectionnez l'onglet **Pipelines**, à côté du job que vous souhaitez relancer, sélectionnez **Réexécuter** ({{< icon name="retry" >}}).

Pour relancer un job depuis le job log :

1. Accédez à la page du job log.
1. Dans le coin supérieur droit, sélectionnez **Réexécuter** ({{< icon name="retry" >}}).

Pour relancer un job depuis un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Trouvez le pipeline contenant le job que vous souhaitez relancer.
1. Depuis le graphe de pipeline, à côté du job que vous souhaitez relancer, sélectionnez **Réexécuter** ({{< icon name="retry" >}}).

### Relancer tous les jobs en échec ou annulés dans un pipeline {#retry-all-failed-or-canceled-jobs-in-a-pipeline}

Si un pipeline contient plusieurs jobs en échec ou annulés, vous pouvez tous les relancer en même temps :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Effectuez l'une des opérations suivantes :
   - Sélectionnez **Version** > **Pipelines**.
   - Accédez à une merge request et sélectionnez l'onglet **Pipelines**.
1. Pour le pipeline contenant des jobs en échec ou annulés, sélectionnez **Relancer tous les jobs en échec ou annulés** ({{< icon name="retry" >}}).

## Annuler des jobs {#cancel-jobs}

Vous pouvez annuler un job CI/CD qui n'est pas encore terminé. Lorsque vous annulez un job, ce qui se passe ensuite dépend de son état :

- Pour les jobs qui n'ont pas encore commencé à s'exécuter, le job est annulé immédiatement.
- Pour les jobs en cours d'exécution :
  1. Le job est marqué comme `canceling`.
  1. La commande en cours d'exécution est autorisée à se terminer. Le reste des commandes dans les sections [`before_script`](../yaml/_index.md#before_script) ou [`script`](../yaml/_index.md#script) du job est ignoré.
  1. Si le job dispose d'une section `after_script`, celle-ci démarre toujours et s'exécute jusqu'à la fin.
  1. Le job est marqué comme `canceled`.

Si vous devez annuler un job immédiatement sans attendre `after_script`, utilisez [l'annulation forcée](#force-cancel-a-job).

### Annuler un job {#cancel-a-job}

Prérequis :

- Vous devez disposer du rôle Développeur, Mainteneur ou Propriétaire pour le projet, ou du [rôle minimum requis pour annuler un pipeline ou un job](../pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs).

Pour annuler un job depuis une merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Depuis votre merge request, effectuez l'une des opérations suivantes :
   - Dans le widget de pipeline, à côté du job que vous souhaitez annuler, sélectionnez **Annuler** ({{< icon name="cancel" >}}).
   - Sélectionnez l'onglet **Pipelines**, à côté du job que vous souhaitez annuler, sélectionnez **Annuler** ({{< icon name="cancel" >}}).

Pour annuler un job depuis le job log :

1. Accédez à la page du job log.
1. Dans le coin supérieur droit, sélectionnez **Annuler** ({{< icon name="cancel" >}}).

Pour annuler un job depuis un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Trouvez le pipeline contenant le job que vous souhaitez annuler.
1. Depuis le graphe de pipeline, à côté du job que vous souhaitez annuler, sélectionnez **Annuler** ({{< icon name="cancel" >}}).

### Annuler tous les jobs en cours dans un pipeline {#cancel-all-running-jobs-in-a-pipeline}

Vous pouvez annuler tous les jobs d'un pipeline en cours d'exécution en une seule fois.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Effectuez l'une des opérations suivantes :
   - Sélectionnez **Version** > **Pipelines**.
   - Accédez à une merge request et sélectionnez l'onglet **Pipelines**.
1. Pour le pipeline que vous souhaitez annuler, sélectionnez **Annuler le pipeline en cours d'exécution** ({{< icon name="cancel" >}}).

### Forcer l'annulation d'un job {#force-cancel-a-job}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/467107) en tant que [version expérimentale](../../policy/development_stages_support.md) dans GitLab 17.10 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `force_cancel_build`. Désactivé par défaut.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/519313) dans GitLab 17.11. Le feature flag `force_cancel_build` a été supprimé.

{{< /history >}}

Si vous ne souhaitez pas attendre la fin de `after_script` ou si un job ne répond pas, vous pouvez forcer son annulation. L'annulation forcée fait passer immédiatement un job de l'état `canceling` à `canceled`.

Lorsque vous forcez l'annulation d'un job, le [token de job](ci_job_token.md) est immédiatement révoqué. Si le runner est encore en train d'exécuter le job, il perd l'accès à GitLab. Le runner abandonne le job sans attendre la fin de `after_script`.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Le job doit être dans l'état `canceling`, ce qui nécessite :
  - GitLab 17.0 ou version ultérieure.
  - GitLab Runner 16.10 ou version ultérieure.

Pour forcer l'annulation d'un job :

1. Accédez à la page du job log.
1. Dans le coin supérieur droit, sélectionnez **Forcer l'annulation**.

## Dépanner un job en échec {#troubleshoot-a-failed-job}

Lorsqu'un pipeline échoue ou est autorisé à échouer, il existe plusieurs endroits où vous pouvez trouver la raison :

- Dans le [graphe de pipeline](../pipelines/_index.md#pipeline-details), dans la vue détaillée du pipeline.
- Dans les widgets de pipeline, dans les pages de merge request et de commit.
- Dans les vues de job, dans les vues globale et détaillée d'un job.

À chaque endroit, si vous survolez le job en échec, vous pouvez voir la raison de son échec.

![Graphe de pipeline affichant un job en échec et la raison de l'échec.](img/job_failure_reason_v17_9.png)

Vous pouvez également voir la raison de l'échec sur la page de détail du job.

### Avec l'analyse des causes profondes {#with-root-cause-analysis}

Vous pouvez utiliser GitLab Duo Root Cause Analysis dans GitLab Duo Chat pour [dépanner les jobs CI/CD en échec](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## Jobs de déploiement {#deployment-jobs}

Les jobs de déploiement sont des jobs CI/CD qui utilisent des [environnements](../environments/_index.md). Un job de déploiement est tout job qui utilise le mot-clé `environment` et l'[environnement `start` `action`](../yaml/_index.md#environmentaction). Les jobs de déploiement n'ont pas besoin d'être dans l'étape `deploy`. Le job `deploy me` suivant est un exemple de job de déploiement. `action: start` est le comportement par défaut et est défini ici pour plus de clarté, mais vous pouvez l'omettre :

```yaml
deploy me:
  script:
    - deploy-to-cats.sh
  environment:
    name: production
    url: https://cats.example.com
    action: start
```

Le comportement des jobs de déploiement peut être contrôlé avec les paramètres de [sécurité des déploiements](../environments/deployment_safety.md), comme [la prévention des jobs de déploiement obsolètes](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) et [la garantie qu'un seul job de déploiement s'exécute à la fois](../environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time).
