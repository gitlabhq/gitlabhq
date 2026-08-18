---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pipelines CI/CD
description: "Configuration, automatisation, étapes, planifications et efficacité."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les pipelines CI/CD sont le composant fondamental de GitLab CI/CD. Les pipelines sont configurés dans un fichier `.gitlab-ci.yml` à l'aide de [mots-clés YAML](../yaml/_index.md).

Les pipelines peuvent s'exécuter automatiquement pour des événements spécifiques, comme lors d'un push vers une branche, de la création d'une merge request, ou selon une planification. Si nécessaire, vous pouvez également exécuter des pipelines manuellement.

Les pipelines sont composés de :

- [Mots-clés YAML globaux](../yaml/_index.md#global-keywords) qui contrôlent le comportement général des pipelines du projet.
- [Jobs](../jobs/_index.md) qui exécutent des commandes pour accomplir une tâche. Par exemple, un job peut compiler, tester ou déployer du code. Les jobs s'exécutent indépendamment les uns des autres et sont exécutés par des [runners](../runners/_index.md).
- Les étapes, qui définissent comment regrouper les jobs ensemble. Les étapes s'exécutent en séquence, tandis que les jobs d'une étape s'exécutent en parallèle. Par exemple, une étape précoce peut contenir des jobs qui effectuent du linting et compilent le code, tandis que des étapes ultérieures peuvent contenir des jobs qui testent et déploient le code. Si tous les jobs d'une étape réussissent, le pipeline passe à l'étape suivante. Si un job d'une étape échoue, l'étape suivante n'est (généralement) pas exécutée et le pipeline se termine prématurément.

Un pipeline simple peut se composer de trois étapes, exécutées dans l'ordre suivant :

- Une étape `build`, avec un job appelé `compile` qui compile le code du projet.
- Une étape `test`, avec deux jobs appelés `test1` et `test2` qui exécutent divers tests sur le code. Ces tests ne s'exécuteraient que si le job `compile` s'est terminé avec succès.
- Une étape `deploy`, avec un job appelé `deploy-to-production`. Ce job ne s'exécuterait que si les deux jobs de l'étape `test` ont démarré et se sont terminés avec succès.

Pour commencer avec votre premier pipeline, consultez [Créer et exécuter votre premier pipeline GitLab CI/CD](../quick_start/_index.md).

## Types de pipelines {#types-of-pipelines}

Les pipelines peuvent être configurés de nombreuses façons différentes :

- [Les pipelines de base](pipeline_architectures.md#basic-pipelines) exécutent tout dans chaque étape simultanément, puis passent à l'étape suivante.
- [Les pipelines utilisant le mot-clé `needs`](../yaml/needs.md) s'exécutent en fonction des dépendances entre les jobs et peuvent s'exécuter plus rapidement que les pipelines de base.
- [Les pipelines de merge request](merge_request_pipelines.md) s'exécutent uniquement pour les merge requests (plutôt que pour chaque commit).
- [Les pipelines de résultats fusionnés](merged_results_pipelines.md) sont des pipelines de merge request qui agissent comme si les modifications de la branche source avaient déjà été fusionnées dans la branche cible.
- [Les merge trains](merge_trains.md) utilisent des pipelines de résultats fusionnés pour mettre en file d'attente les fusions l'une après l'autre.
- [Les pipelines de charge de travail](pipeline_types.md#workload-pipeline) s'exécutent sur des références Git éphémères pour une exécution de pipeline à la demande sans créer de branches temporaires.
- [Les pipelines parent-enfant](downstream_pipelines.md#parent-child-pipelines) décomposent des pipelines complexes en un pipeline parent qui peut déclencher plusieurs sous-pipelines enfants, qui s'exécutent tous dans le même projet et avec le même SHA. Cette architecture de pipeline est couramment utilisée pour les mono-dépôts.
- [Les pipelines multi-projets](downstream_pipelines.md#multi-project-pipelines) combinent des pipelines de différents projets.

## Configurer un pipeline {#configure-a-pipeline}

Les pipelines et leurs jobs et étapes composants sont définis avec des [mots-clés YAML](../yaml/_index.md) dans le fichier de configuration du pipeline CI/CD de chaque projet. Lors de la modification de la configuration CI/CD dans GitLab, vous devez utiliser l'[éditeur de pipeline](../pipeline_editor/_index.md).

Vous pouvez également configurer des aspects spécifiques de vos pipelines via l'interface utilisateur GitLab :

- [Paramètres du pipeline](settings.md) pour chaque projet.
- [Planifications de pipeline](schedules.md).
- [Variables CI/CD personnalisées](../variables/_index.md#for-a-project).

Si vous utilisez VS Code pour modifier votre configuration GitLab CI/CD, l'[extension GitLab pour VS Code](../../editor_extensions/visual_studio_code/_index.md) vous aide à [valider votre configuration](../../editor_extensions/visual_studio_code/cicd.md#test-gitlab-cicd-configuration) et à [visualiser le statut de votre pipeline](../../editor_extensions/visual_studio_code/cicd.md#monitor-and-manage-pipelines).

### Exécuter un pipeline manuellement {#run-a-pipeline-manually}

{{< history >}}

- Le nom **Exécuter le pipeline** a été [renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/482718) en **Nouveau pipeline** dans GitLab 17.7.
- L'option **Entrées** a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) dans GitLab 17.11 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_inputs_for_pipelines`. Activé par défaut.
- L'option **Entrées** est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) dans GitLab 18.1. L'indicateur de fonctionnalité `ci_inputs_for_pipelines` a été supprimé.

{{< /history >}}

Les pipelines peuvent être exécutés manuellement, avec des [variables](../variables/_index.md) prédéfinies ou spécifiées manuellement.

Vous pouvez le faire si les résultats d'un pipeline (par exemple, une compilation de code) sont requis en dehors du fonctionnement standard du pipeline.

Pour exécuter un pipeline manuellement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez **Nouveau pipeline**.
1. Dans le champ **Exécuter pour une étiquette ou un nom de branche**, sélectionnez la branche ou l'étiquette pour laquelle exécuter le pipeline.
1. facultatif. Saisissez l'une des valeurs suivantes :
   - [Entrées](../inputs/_index.md) requises pour l'exécution du pipeline. Les valeurs par défaut des entrées sont préremplies, mais peuvent être modifiées. Les valeurs d'entrée doivent respecter le type attendu.
   - [Variables CI/CD](../variables/_index.md). Vous pouvez configurer des variables pour que leurs [valeurs soient préremplies dans le formulaire](#prefill-variables-in-manual-pipelines). L'utilisation des entrées pour contrôler le comportement du pipeline offre une sécurité et une flexibilité améliorées par rapport aux variables CI/CD.
1. Sélectionnez **Nouveau pipeline**.

Le pipeline exécute désormais les jobs tels qu'ils sont configurés.

#### Afficher les variables de pipeline manuelles {#view-manual-pipeline-variables}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/323097) dans GitLab 17.2 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_show_manual_variables_in_pipeline`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/505440) dans GitLab 18.4 avec un paramètre de projet. L'indicateur de fonctionnalité `ci_show_manual_variables_in_pipeline` a été supprimé.

{{< /history >}}

Vous pouvez voir toutes les variables spécifiées lors de l'exécution manuelle du pipeline.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le projet.

Le rôle requis dépend de ce que vous souhaitez faire :

| Action | Rôle minimum |
|--------|-------------|
| Afficher les noms des variables | Invité |
| Afficher les valeurs des variables | Développeur |
| Configurer le paramètre de visibilité | Propriétaire |

> [!warning]
> Lorsque vous activez ce paramètre, les utilisateurs disposant du rôle Développeur peuvent consulter les valeurs de variables susceptibles de contenir des informations sensibles issues de n'importe quelle exécution manuelle de pipeline. Pour les données sensibles telles que les identifiants ou les jetons, utilisez des [variables protégées](../variables/_index.md#protect-a-cicd-variable) ou la [gestion des secrets externe](../secrets/_index.md) plutôt que des variables de pipeline manuel.

Pour afficher les variables de pipeline manuel :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Sélectionnez **Afficher les variables de pipeline**.
1. Accédez à **Version** > **Pipelines** et sélectionnez un pipeline exécuté manuellement.
1. Sélectionnez l'onglet **Variables manuelles**.

Les valeurs des variables sont masquées par défaut. Si vous disposez du rôle Développeur, Mainteneur ou Propriétaire, vous pouvez sélectionner l'icône en forme d'œil pour afficher les valeurs.

#### Préremplir les variables dans les pipelines manuels {#prefill-variables-in-manual-pipelines}

{{< history >}}

- Le rendu Markdown sur la page **Exécuter le pipeline** a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/441474) dans GitLab 17.11.

{{< /history >}}

Vous pouvez utiliser les mots-clés [`description` et `value`](../yaml/_index.md#variablesdescription) pour [définir des variables au niveau du pipeline (globales)](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file) qui sont préremplies lors de l'exécution manuelle d'un pipeline. Utilisez la description pour expliquer des informations telles que l'utilisation de la variable et les valeurs acceptables. Vous pouvez utiliser Markdown dans la description.

Les variables au niveau du job ne peuvent pas être préremplies.

Dans les pipelines déclenchés manuellement, la page **Nouveau pipeline** affiche toutes les variables au niveau du pipeline qui ont une `description` définie dans le fichier `.gitlab-ci.yml`. La description s'affiche sous la variable.

Vous pouvez modifier la valeur préremplie, ce qui [remplace la valeur](../variables/_index.md#use-pipeline-variables) pour cette seule exécution de pipeline. Toutes les variables remplacées par ce processus sont [développées](../variables/_index.md#allow-cicd-variable-expansion) et non [masquées](../variables/_index.md#mask-a-cicd-variable). Si vous ne définissez pas de `value` pour la variable dans le fichier de configuration, le nom de la variable reste affiché, mais le champ de valeur est vide.

Par exemple :

```yaml
variables:
  DEPLOY_CREDENTIALS:
    description: "The deployment credentials."
  DEPLOY_ENVIRONMENT:
    description: "Select the deployment target. Valid options are: 'canary', 'staging', 'production', or a stable branch of your choice."
    value: "canary"
```

Dans cet exemple :

- `DEPLOY_CREDENTIALS` est répertorié sur la page **Nouveau pipeline**, mais sans valeur définie. L'utilisateur est censé définir la valeur à chaque exécution manuelle du pipeline.
- `DEPLOY_ENVIRONMENT` est prérempli sur la page **Nouveau pipeline** avec `canary` comme valeur par défaut, et le message explique les autres options.

> [!note]
> En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/382857), les projets qui utilisent des [pipelines de conformité](../../user/compliance/compliance_pipelines.md) peuvent avoir des variables préremplies qui n'apparaissent pas lors de l'exécution manuelle d'un pipeline. Pour contourner ce problème, [modifiez la configuration du pipeline de conformité](../../user/compliance/compliance_pipelines.md#prefilled-variables-are-not-shown).

#### Configurer une liste de valeurs de variables préremplies sélectionnables {#configure-a-list-of-selectable-prefilled-variable-values}

Vous pouvez définir un tableau de valeurs de variables CI/CD parmi lesquelles l'utilisateur peut choisir lors de l'exécution manuelle d'un pipeline. Ces valeurs figurent dans une liste déroulante sur la page **Nouveau pipeline**. Ajoutez la liste des options de valeurs à `options` et définissez la valeur par défaut avec `value`. La chaîne dans `value` doit également être incluse dans la liste `options`.

Par exemple :

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

### Exécuter un pipeline à l'aide d'une chaîne de requête URL {#run-a-pipeline-by-using-a-url-query-string}

Vous pouvez utiliser une chaîne de requête pour préremplir la page **Nouveau pipeline**. Par exemple, la chaîne de requête `.../pipelines/new?ref=my_branch&var[foo]=bar&file_var[file_foo]=file_bar` préremplie la page **Nouveau pipeline** avec :

- Champ **Run for** : `my_branch`.
- Section **Variables** :
  - Variable :
    - Clé : `foo`
    - Valeur : `bar`
  - Fichier :
    - Clé : `file_foo`
    - Valeur : `file_bar`

Le format de l'URL `pipelines/new` est :

```plaintext
.../pipelines/new?ref=<branch>&var[<variable_key>]=<value>&file_var[<file_key>]=<value>
```

Les paramètres suivants sont pris en charge :

- `ref` : spécifier la branche pour remplir le champ **Run for**.
- `var` : spécifier une variable `Variable`.
- `file_var` : spécifier une variable `File`.

Pour chaque `var` ou `file_var`, une clé et une valeur sont requises.

### Ajouter une interaction manuelle à votre pipeline {#add-manual-interaction-to-your-pipeline}

[Les jobs manuels](../jobs/job_control.md#create-a-job-that-must-be-run-manually) vous permettent d'exiger une interaction manuelle avant de poursuivre l'exécution du pipeline.

Vous pouvez le faire directement depuis le graphe de pipeline. Sélectionnez **Exécution** ({{< icon name="play" >}}) pour exécuter ce job particulier.

Par exemple, votre pipeline peut démarrer automatiquement, mais nécessiter une action manuelle pour [déployer en production](../environments/deployments.md#configure-manual-deployments). Dans l'exemple suivant, l'étape `production` comporte un job avec une action manuelle :

![Graphe de pipeline affichant quatre étapes : build, test, canary et production. Les trois premières étapes affichent des jobs terminés avec des coches vertes, tandis que l'étape production affiche un job de déploiement en attente.](img/manual_job_v17_9.png)

#### Démarrer tous les jobs manuels d'une étape {#start-all-manual-jobs-in-a-stage}

Si une étape ne contient que des jobs manuels, vous pouvez démarrer tous les jobs en même temps en sélectionnant **Exécuter tout manuellement** ({{< icon name="play" >}}) au-dessus de l'étape. Si l'étape contient des jobs non manuels, l'option n'est pas affichée.

### Ignorer un pipeline {#skip-a-pipeline}

Pour pousser un commit sans déclencher un pipeline, ajoutez `[ci skip]` ou `[skip ci]`, avec n'importe quelle casse, dans votre message de commit.

Vous pouvez aussi, avec Git 2.10 ou une version ultérieure, utiliser l'[option Git push](../../topics/git/commit.md#push-options-for-gitlab-cicd) `ci.skip`. L'option push `ci.skip` n'ignore pas les pipelines de merge request.

Lorsque vous ignorez un pipeline :

- Un pipeline vide, sans jobs ni étapes, est tout de même créé dans GitLab. Le pipeline apparaît dans l'interface utilisateur et peut être renvoyé dans les réponses API.
- Le statut du pipeline est **Passé** dans l'interface utilisateur, et `skipped` dans l'API.

> [!note]
> Les politiques d'exécution de pipeline et les politiques d'exécution de scan peuvent restreindre ou désactiver la directive `[skip ci]`. Pour plus d'informations, consultez la page suivante :
>
> - Le [type `skip_ci`](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type) dans les politiques d'exécution de pipeline.
> - Le [type `skip_ci`](../../user/application_security/policies/scan_execution_policies.md#skip_ci-type) dans les politiques d'exécution de scan.

### Supprimer un pipeline {#delete-a-pipeline}

Les utilisateurs disposant du rôle Propriétaire pour un projet peuvent supprimer un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez l'ID du pipeline (par exemple `#123456789`) ou l'icône de statut du pipeline (par exemple **Réussi**) du pipeline à supprimer.
1. En haut à droite de la page de détails du pipeline, sélectionnez **Supprimer**.

La suppression d'un pipeline ne supprime pas automatiquement ses [pipelines enfants](downstream_pipelines.md#parent-child-pipelines). Consultez le [ticket 39503](https://gitlab.com/gitlab-org/gitlab/-/issues/39503) pour plus de détails.

> [!warning]
> La suppression d'un pipeline expire tous les caches du pipeline et supprime tous les objets directement associés, tels que les jobs, les logs, les artefacts et les déclencheurs. **This action cannot be undone**.

### Sécurité du pipeline sur les branches protégées {#pipeline-security-on-protected-branches}

Un modèle de sécurité strict est appliqué lorsque des pipelines sont exécutés sur des [branches protégées](../../user/project/repository/branches/protected.md).

Les actions suivantes sont autorisées sur les branches protégées si l'utilisateur est [autorisé à fusionner ou à pousser](../../user/project/repository/branches/protected.md) vers cette branche spécifique :

- Exécuter des pipelines manuels (via l'[interface Web](#run-a-pipeline-manually) ou l'[API des pipelines](#pipelines-api)).
- Exécuter des pipelines planifiés.
- Exécuter des pipelines à l'aide de jetons de déclenchement.
- Exécuter un scan DAST à la demande.
- Exécuter des jobs manuels sur des pipelines existants.
- Réessayer ou annuler des jobs existants (via l'interface Web ou l'API des pipelines).

Les **Variables** marquées comme **protégées** sont accessibles aux jobs qui s'exécutent dans les pipelines des branches protégées. N'accordez aux utilisateurs le droit de fusionner vers des branches protégées que s'ils ont l'autorisation d'accéder à des informations sensibles telles que les identifiants de déploiement et les jetons.

Les **Runners** marqués comme **protégées** peuvent exécuter des jobs uniquement sur des branches protégées, empêchant l'exécution de code non fiable sur le runner protégé et évitant l'accès involontaire aux clés de déploiement et autres identifiants. Pour s'assurer que les jobs destinés à être exécutés sur des runners protégés n'utilisent pas de runners standard, ils doivent être [étiquetés](../yaml/_index.md#tags) en conséquence.

Consultez le fonctionnement de l'accès aux variables et aux runners protégés dans le [contexte des pipelines de merge request](merge_request_pipelines.md#control-access-to-protected-variables-and-runners).

Consultez la page sur la [sécurité des déploiements](../environments/deployment_safety.md) pour des recommandations de sécurité supplémentaires concernant la sécurisation de vos pipelines.

## Déclencher un pipeline lors de la reconstruction d'un projet upstream {#trigger-a-pipeline-when-an-upstream-project-is-rebuilt}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez configurer votre projet pour déclencher automatiquement un pipeline en fonction des étiquettes d'un autre projet. Lorsqu'un nouveau pipeline d'étiquette dans le projet abonné se termine, il déclenche un pipeline sur la branche par défaut de votre projet, indépendamment du succès, de l'échec ou de l'annulation du pipeline d'étiquette.

Vous pouvez aussi utiliser des [jobs CI/CD avec des jetons de déclenchement de pipeline](../triggers/_index.md#use-a-cicd-job) pour déclencher des pipelines lorsqu'un autre pipeline s'exécute. Cette méthode est plus fiable et flexible que les abonnements aux pipelines et constitue l'approche recommandée.

Prérequis :

- Le projet upstream doit être [public](../../user/public_access.md).
- L'utilisateur doit disposer du rôle Développeur dans le projet upstream.

Pour déclencher le pipeline lors de la reconstruction du projet upstream :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Abonnements aux pipelines**.
1. Sélectionnez **Ajouter un projet**.
1. Saisissez le projet auquel vous souhaitez vous abonner, au format `<namespace>/<project>`. Par exemple, si le projet est `https://gitlab.com/gitlab-org/gitlab`, utilisez `gitlab-org/gitlab`.
1. Sélectionnez **S'abonner**.

Le nombre maximum d'abonnements aux pipelines upstream est de 2 par défaut, pour les projets upstream et downstream. Sur GitLab Self-Managed, un administrateur peut modifier cette [limite](../../administration/cicd/limits.md#number-of-cicd-subscriptions-to-a-project).

## Calcul de la durée d'un pipeline {#how-pipeline-duration-is-calculated}

Le temps d'exécution total d'un pipeline donné exclut :

- La durée de l'exécution initiale de tout job relancé ou réexécuté manuellement.
- Tout temps d'attente (file d'attente).

Cela signifie que si un job est relancé ou réexécuté manuellement, seule la durée de la dernière exécution est incluse dans le temps d'exécution total.

Chaque job est représenté sous la forme d'une `Period`, qui se compose de :

- `Period#first` (lorsque le job a démarré).
- `Period#last` (lorsque le job s'est terminé).

Un exemple simple est :

- A (0, 2)
- A' (2, 4)
  - Il s'agit d'une nouvelle tentative de A
- B (1, 3)
- C (6, 7)

Dans l'exemple :

- A commence à 0 et se termine à 2.
- A' commence à 2 et se termine à 4.
- B commence à 1 et se termine à 3.
- C commence à 6 et se termine à 7.

Visuellement, on peut le représenter comme suit :

```plaintext
0  1  2  3  4  5  6  7
AAAAAAA
   BBBBBBB
      A'A'A'A
                  CCCC
```

Comme A est relancé, il est ignoré, et seul le job A' est comptabilisé. L'union de B, A' et C est (1, 4) et (6, 7). Par conséquent, le temps d'exécution total est :

```plaintext
(4 - 1) + (7 - 6) => 4
```

## Afficher les pipelines {#view-pipelines}

Pour afficher tous les pipelines qui se sont exécutés pour votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.

Vous pouvez filtrer la page **Pipelines** par :

- Auteur du déclenchement
- Nom de la branche
- Statut
- Étiquette
- Source

Sélectionnez **ID du pipeline** dans la liste déroulante en haut à droite pour afficher les ID des pipelines (ID unique à l'échelle de l'instance). Sélectionnez **pipeline IID** pour afficher les IID des pipelines (ID interne, unique à l'échelle du projet uniquement).

Pour afficher les pipelines liés à une merge request spécifique, accédez à l'onglet **Pipelines** dans la merge request.

### Détails du pipeline {#pipeline-details}

Sélectionnez un pipeline pour ouvrir la page de détails du pipeline, qui affiche chaque job du pipeline. Depuis cette page, vous pouvez annuler un pipeline en cours d'exécution, relancer des jobs échoués ou [supprimer un pipeline](#delete-a-pipeline).

La page de détails du pipeline affiche un graphe de tous les jobs du pipeline :

![Page de détails du pipeline](img/pipeline_details_v17_9.png)

Vous pouvez utiliser une URL standard pour accéder aux détails de pipelines spécifiques :

- `gitlab.example.com/my-group/my-project/-/pipelines/latest` :  La page de détails du dernier pipeline pour le commit le plus récent sur la branche par défaut du projet.
- `gitlab.example.com/my-group/my-project/-/pipelines/<branch>/latest` :  La page de détails du dernier pipeline pour le commit le plus récent sur la branche `<branch>` du projet.

#### Grouper les jobs par étape ou par configuration `needs` {#group-jobs-by-stage-or-needs-configuration}

Lorsque vous configurez des jobs avec le mot-clé [`needs`](../yaml/_index.md#needs), vous disposez de deux options pour grouper les jobs dans la page de détails du pipeline. Pour grouper les jobs par configuration d'étape, sélectionnez **stage** dans la section **Grouper les jobs par** :

![Graphe de pipeline affichant les jobs regroupés sous chaque étape](img/pipeline_stage_view_v17_9.png)

Pour grouper les jobs par configuration [`needs`](../yaml/_index.md#needs), sélectionnez **Dépendances des jobs**. Vous pouvez éventuellement sélectionner **Afficher les dépendances** pour afficher des lignes entre les jobs dépendants.

![Jobs groupés par dépendances de jobs](img/pipeline_dependency_view_v17_9.png)

Les jobs de la colonne la plus à gauche s'exécutent en premier, et les jobs qui en dépendent sont regroupés dans les colonnes suivantes. Dans cet exemple :

- `lint-job` est configuré avec `needs: []` et ne dépend d'aucun job, il s'affiche donc dans la première colonne, bien qu'il se trouve dans l'étape `test`.
- `test-job1` dépend de `build-job1`, et `test-job2` dépend à la fois de `build-job1` et de `build-job2`, de sorte que les deux jobs de test s'affichent dans la deuxième colonne.
- Les deux jobs `deploy` dépendent des jobs de la deuxième colonne (qui eux-mêmes dépendent d'autres jobs antérieurs), de sorte que les jobs de déploiement s'affichent dans la troisième colonne.

Lorsque vous survolez un job dans la vue **Dépendances des jobs**, chaque job devant s'exécuter avant le job sélectionné est mis en surbrillance :

![Vue des dépendances du pipeline au survol](img/pipeline_dependency_view_on_hover_v17_9.png)

### Mini-graphes de pipeline {#pipeline-mini-graphs}

Les mini-graphes de pipeline prennent moins de place et permettent de voir en un coup d'œil si tous les jobs ont réussi ou si quelque chose a échoué. Ils affichent tous les jobs associés à un seul commit et le résultat net de chaque étape de votre pipeline. Vous pouvez rapidement identifier ce qui a échoué et le corriger.

Le mini-graphe de pipeline regroupe toujours les jobs par étape et s'affiche dans toute l'interface GitLab lors de l'affichage des détails du pipeline ou du commit.

![Mini-graphe de pipeline](img/pipeline_mini_graph_v16_11.png)

Les étapes dans les mini-graphes de pipeline sont extensibles. Survolez chaque étape pour voir son nom et son statut, puis sélectionnez une étape pour développer la liste de ses jobs.

### Graphes de pipeline downstream {#downstream-pipeline-graphs}

Lorsqu'un pipeline contient un job qui déclenche un [pipeline downstream](downstream_pipelines.md), vous pouvez voir le pipeline downstream dans la vue de détails du pipeline et dans les mini-graphes.

Dans la vue de détails du pipeline, une carte s'affiche pour chaque pipeline downstream déclenché, à droite du graphe de pipeline. Survolez une carte pour voir quel job a déclenché le pipeline downstream. Sélectionnez une carte pour afficher le pipeline downstream à droite du graphe de pipeline.

Dans le mini-graphe de pipeline, le statut de chaque pipeline downstream déclenché s'affiche sous forme d'icônes de statut supplémentaires à droite du mini-graphe. Sélectionnez l'icône de statut d'un pipeline downstream pour accéder à la page de détails de ce pipeline downstream.

## Graphiques de succès et de durée des pipelines {#pipeline-success-and-duration-charts}

Les données d'analyse des pipelines sont disponibles sur la [page **Données d'analyse CI/CD**](../../user/analytics/ci_cd_analytics.md).

## Badges de pipeline {#pipeline-badges}

Les badges de statut du pipeline et de rapport de couverture des tests sont disponibles et configurables pour chaque projet. Pour obtenir des informations sur l'ajout de badges de pipeline aux projets, consultez [Badges de pipeline](settings.md#pipeline-badges).

## API des pipelines {#pipelines-api}

GitLab fournit des points de terminaison API pour :

- Effectuer des fonctions de base. Pour plus d'informations, consultez [l'API des pipelines](../../api/pipelines.md).
- Gérer les planifications de pipeline. Pour plus d'informations, consultez [l'API des planifications de pipeline](../../api/pipeline_schedules.md).
- Déclencher des exécutions de pipeline. Pour plus d'informations, consultez la page suivante :
  - [Déclencher des pipelines via l'API](../triggers/_index.md).
  - [API des jetons de déclenchement de pipeline](../../api/pipeline_triggers.md).

## Refspecs pour les runners {#ref-specs-for-runners}

Lorsqu'un runner prend en charge un job de pipeline, GitLab fournit les métadonnées de ce job. Cela inclut les [refspecs Git](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec), qui indiquent quelle référence (telle qu'une branche ou une étiquette) et quel commit (SHA1) sont extraits de votre dépôt de projet.

Ce tableau répertorie les refspecs injectées pour chaque type de pipeline :

| Type de pipeline                                        | Refspecs |
|------------------------------------------------------|----------|
| pipeline pour les branches                                | `+<sha>:refs/pipelines/<id>` et `+refs/heads/<name>:refs/remotes/origin/<name>` |
| pipeline pour les étiquettes                                    | `+<sha>:refs/pipelines/<id>` et `+refs/tags/<name>:refs/tags/<name>` |
| [pipeline de merge request](merge_request_pipelines.md) | `+refs/pipelines/<id>:refs/pipelines/<id>` |
| [pipeline pour les références de charge de travail](pipeline_types.md#workload-pipeline)  | `+refs/pipelines/<id>:refs/pipelines/<id>` |

Les références `refs/heads/<name>` et `refs/tags/<name>` existent dans votre dépôt de projet. GitLab génère la référence spéciale `refs/pipelines/<id>` pendant l'exécution d'un job de pipeline. Cette référence peut être créée même après la suppression de la branche ou de l'étiquette associée. Elle est donc utile dans certaines fonctionnalités telles que l'[arrêt automatique d'un environnement](../environments/_index.md#stopping-an-environment) et les [merge trains](merge_trains.md) qui peuvent exécuter des pipelines après la suppression d'une branche.

## Dépannage {#troubleshooting}

### Les abonnements aux pipelines continuent après la suppression d'un utilisateur {#pipeline-subscriptions-continue-after-user-deletion}

Lorsqu'un utilisateur [supprime son compte GitLab.com](../../user/profile/account/delete_account.md#delete-your-own-account), la suppression n'intervient pas avant sept jours. Pendant cette période, tout abonnement aux pipelines créé par cet utilisateur continue à s'exécuter avec les autorisations initiales de l'utilisateur. Pour éviter des exécutions de pipeline non autorisées, mettez immédiatement à jour les paramètres d'abonnement aux pipelines pour l'utilisateur supprimé.

### Les variables préremplies n'apparaissent pas sur la page **New Pipeline** {#pre-filled-variables-do-not-show-up-in-new-pipeline-page}

Si les variables prédéfinies d'un pipeline sont [définies dans un fichier séparé](../yaml/includes.md), elles peuvent ne pas s'afficher sur la page **New Pipeline**. Vous devez avoir l'autorisation d'accéder au fichier séparé, faute de quoi les variables prédéfinies ne peuvent pas être affichées.
