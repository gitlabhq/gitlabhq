---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Affichez et déboguez les résultats des tests unitaires sans parcourir les job logs.
title: Rapports de tests unitaires
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les rapports de tests unitaires affichent les résultats des tests directement dans les merge requests et les détails du pipeline, ce qui vous permet d'identifier les échecs sans parcourir les job logs.

Utilisez les rapports de tests unitaires lorsque vous souhaitez :

- Voir immédiatement les échecs de tests dans les merge requests.
- Comparer les résultats des tests entre les branches.
- Déboguer les tests en échec grâce aux détails d'erreur et aux captures d'écran.
- Suivre les patterns d'échec des tests au fil du temps.

Les rapports de tests unitaires nécessitent le format JUnit XML et n'affectent pas le statut du job. Pour qu'un job échoue lorsque les tests échouent, le [script](../yaml/_index.md#script) de votre job doit se terminer avec un statut non nul.

GitLab Runner charge vos résultats de tests au format JUnit XML en tant qu'[artefacts](../yaml/artifacts_reports.md#artifactsreportsjunit). Lorsque vous accédez à une merge request, vos résultats de tests sont comparés entre la branche source (head) et la branche cible (base) afin de montrer ce qui a changé.

## Format de fichier et limites de taille {#file-format-and-size-limits}

Les rapports de tests unitaires doivent utiliser le format JUnit XML avec des exigences spécifiques pour garantir un parsing et un affichage corrects.

### Exigences relatives aux fichiers {#file-requirements}

Vos fichiers de rapport de tests doivent :

- Utiliser le format JUnit XML avec l'extension de fichier `.xml`.
- Avoir une taille inférieure à 30 Mo par fichier individuel.
- Avoir une taille totale inférieure à 100 Mo pour tous les fichiers JUnit d'un job.

Si vous avez des noms de tests en double, seul le premier test est utilisé et les autres portant le même nom sont ignorés.

Pour les limites des cas de test, consultez [Nombre maximum de cas de test par rapport de tests unitaires](../../user/gitlab_com/_index.md#cicd).

### Spécification du format JUnit XML {#junit-xml-format-specification}

GitLab parse un sous-ensemble d'éléments et d'attributs JUnit XML pour afficher les résultats des tests dans l'interface utilisateur.

| Élément XML  | Attribut XML   | Description |
| ------------ | --------------- | ----------- |
| `testsuites` | `time`          | Temps d'exécution total pour toutes les suites de tests. Utilisé pour les calculs du temps d'exécution des tests. |
| `testsuite`  | `name`          | Nom de la suite de tests. Parsé pour le regroupement interne. |
| `testsuite`  | `time`          | Temps d'exécution pour une suite de tests individuelle. Utilisé pour les calculs du temps d'exécution des tests. |
| `testcase`   | `classname`     | Nom de la classe ou de la catégorie de test. Affiché comme nom de suite dans l'interface utilisateur. |
| `testcase`   | `name`          | Nom du test individuel. |
| `testcase`   | `file`          | Chemin du fichier où le test est défini. |
| `testcase`   | `time`          | Temps d'exécution du test en secondes. |
| `failure`    | Contenu de l'élément | Message d'échec et trace de pile. |
| `error`      | Contenu de l'élément | Message d'erreur et trace de pile. |
| `skipped`    | Contenu de l'élément | Raison du saut du test. |
| `system-out` | Contenu de l'élément | Sortie système et balises de pièces jointes. Parsé uniquement depuis les éléments `testcase`. |
| `system-err` | Contenu de l'élément | Sortie d'erreur système. Parsé uniquement depuis les éléments `testcase`. |

Les éléments et attributs suivants ne sont pas parsés :

- Attributs de `testsuite` (tests, failures, errors, timestamp)
- Attributs de `testcase` (assertions, line, status)
- Éléments `properties`
- `system-out` et `system-err` au niveau `testsuite`

#### Exemple de structure XML {#xml-structure-example}

```xml
<testsuites>
  <testsuite name="Authentication Tests" tests="1" failures="1">
    <testcase classname="LoginTest" name="test_invalid_password" file="spec/auth_spec.rb" time="0.23">
      <failure>Expected authentication to fail</failure>
      <system-out>[[ATTACHMENT|screenshots/failure.png]]</system-out>
    </testcase>
  </testsuite>
</testsuites>
```

Ce XML s'affiche dans GitLab comme suit :

- Suite : `LoginTest` (depuis `testcase classname`)
- Nom : `test_invalid_password` (depuis `testcase name`)
- Fichier : `spec/auth_spec.rb` (depuis `testcase file`)
- Temps : `0.23s` (depuis `testcase time`)
- Capture d'écran : Disponible dans la boîte de dialogue des détails du test (depuis `testcase system-out`)
- Non affiché : « Authentication Tests » (depuis `testsuite name`)

## Types de résultats de tests {#test-result-types}

Les résultats des tests sont comparés entre la branche source et la branche cible de la merge request afin de montrer ce qui a changé :

- Tests nouvellement en échec : Tests qui ont réussi sur la branche cible mais ont échoué sur votre branche.
- Erreurs nouvellement rencontrées : Tests qui ont réussi sur la branche cible mais ont généré des erreurs sur votre branche.
- Échecs existants : Tests qui ont échoué sur les deux branches.
- Échecs résolus : Tests qui ont échoué sur la branche cible mais ont réussi sur votre branche.

Si les branches ne peuvent pas être comparées, par exemple lorsqu'il n'y a pas encore de données pour la branche cible, seuls les tests en échec de votre branche sont affichés.

Pour les tests qui ont échoué sur la branche par défaut au cours des 14 derniers jours, un message de type `Failed {n} time(s) in {default_branch} in the last 14 days` s'affiche. Ce décompte inclut les tests en échec des pipelines terminés, mais pas les [pipelines bloqués](../jobs/job_control.md#types-of-manual-jobs). La prise en charge des pipelines bloqués est proposée dans le [ticket 431265](https://gitlab.com/gitlab-org/gitlab/-/issues/431265).

## Configurer les rapports de tests unitaires {#configure-unit-test-reports}

Configurez les rapports de tests unitaires pour afficher les résultats des tests dans les merge requests et les pipelines.

Pour configurer les rapports de tests unitaires :

1. Configurez votre job de test pour générer des rapports de tests au format JUnit XML. Pour les détails de configuration, consultez la documentation de votre framework de test.
1. Dans votre fichier `.gitlab-ci.yml`, ajoutez [`artifacts:reports:junit`](../yaml/artifacts_reports.md#artifactsreportsjunit) à votre job de test.
1. Spécifiez le chemin vers vos fichiers de rapport de tests XML. La propriété `junit` accepte :

   - Un nom de fichier unique : `junit: report.xml`
   - Un pattern de nom de fichier : `junit: test-results/**/*.xml`
   - Un tableau de noms de fichiers : `junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`
   - Une combinaison des deux : `junit: [rspec.xml, test-results/TEST-*.xml]`

   Les répertoires ne sont pas pris en charge (par exemple, `junit: test-results` ou `junit: test-results/**`).

1. Facultatif. Pour rendre les fichiers de rapport navigables, incluez-les avec [`artifacts:paths`](../yaml/_index.md#artifactspaths).
1. Facultatif. Pour charger les rapports même lorsque les jobs échouent, utilisez [`artifacts:when:always`](../yaml/_index.md#artifactswhen).

Exemple de configuration pour Ruby avec RSpec :

```yaml
ruby:
  stage: test
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

Vous pouvez consulter les résultats des tests :

- Dans l'onglet **Tests** des détails du pipeline une fois votre job de test terminé.
- Dans le panneau **Synthèse des tests** des merge requests une fois votre pipeline terminé.

## Afficher les résultats des tests dans les merge requests {#view-test-results-in-merge-requests}

Affichez des informations détaillées sur les échecs de tests dans les merge requests.

Le panneau **Synthèse des tests** affiche une vue d'ensemble de vos résultats de tests, notamment le nombre de tests en échec et en succès.

![Panneau Synthèse des tests développé affichant un test en échec avec le lien Afficher les détails](img/test_summary_panel_expanded_v18_1.png)

Pour afficher les détails des échecs de tests :

1. Dans une merge request, accédez au panneau **Synthèse des tests**.
1. Pour développer le panneau **Synthèse des tests**, sélectionnez **Afficher les détails** ({{< icon name="chevron-lg-down" >}}).
1. Sélectionnez **Afficher les détails** en regard d'un test en échec.

La boîte de dialogue affiche le nom du test, le chemin du fichier, le temps d'exécution, la pièce jointe de capture d'écran (si configurée) et la sortie d'erreur.

Pour afficher tous les résultats des tests :

- Depuis le panneau **Synthèse des tests**, sélectionnez **Rapport complet** pour accéder à l'onglet **Tests** dans les détails du pipeline.

### Copier les noms des tests en échec {#copy-failed-test-names}

Copiez les noms des tests pour les réexécuter localement à des fins de débogage.

Prérequis :

- Votre rapport JUnit doit inclure les attributs `<file>` pour les tests en échec.

Pour copier tous les noms des tests en échec :

- Depuis le panneau **Synthèse des tests**, sélectionnez **Copier les tests échoués** ({{< icon name="copy-to-clipboard" >}}).

Les tests en échec sont copiés sous forme de chaîne de caractères séparée par des espaces.

Pour copier un seul nom de test en échec :

1. Pour développer le panneau **Synthèse des tests**, sélectionnez **Afficher les détails** ({{< icon name="chevron-lg-down" >}}).
1. Sélectionnez **Afficher les détails** en regard du test que vous souhaitez copier.
1. Dans la boîte de dialogue, sélectionnez **Copier le nom du test pour l'exécuter à nouveau en local** ({{< icon name="copy-to-clipboard" >}}).

Le nom du test est copié dans votre presse-papiers.

## Afficher les résultats des tests dans les pipelines {#view-test-results-in-pipelines}

Affichez toutes les suites et cas de tests dans les détails du pipeline, y compris les résultats des pipelines enfants.

Pour afficher les résultats des tests du pipeline :

1. Accédez à la page de détails de votre pipeline.
1. Sélectionnez l'onglet **Tests**.
1. Sélectionnez une suite de tests pour voir les cas de tests individuels.

![Résultats des tests affichant 1671 tests avec un temps d'exécution total de 1 minute 11 secondes et les temps d'exécution individuels des jobs.](img/pipelines_junit_test_report_v18_3.png)

Vous pouvez également récupérer les rapports de tests avec l'[API Pipelines](../../api/pipelines.md#retrieve-a-test-report-for-a-pipeline).

### Métriques de durée des tests {#test-timing-metrics}

Les résultats des tests affichent différentes métriques de durée :

Durée du pipeline : Temps écoulé entre le démarrage et la fin du pipeline.

Temps d'exécution des tests : Temps total passé à exécuter tous les tests sur tous les jobs, additionné.

Temps d'attente en file : Temps passé par les jobs à attendre des runners disponibles.

Lorsque les jobs s'exécutent en parallèle, le temps d'exécution cumulé des tests peut dépasser la durée du pipeline.

La durée du pipeline indique le temps d'attente des résultats, tandis que le temps d'exécution des tests indique les ressources de calcul utilisées.

Par exemple, un pipeline qui se termine en 81 minutes peut afficher 9 heures 10 minutes de temps d'exécution des tests si de nombreux jobs de test s'exécutent en parallèle sur plusieurs runners.

## Ajouter des captures d'écran aux rapports de tests {#add-screenshots-to-test-reports}

Ajoutez des captures d'écran aux rapports de tests pour faciliter le débogage des échecs de tests.

Pour ajouter des captures d'écran aux rapports de tests :

1. Dans votre fichier JUnit XML, ajoutez des balises de pièces jointes avec les chemins des captures d'écran relatifs à `$CI_PROJECT_DIR` :

   ```xml
   <testcase time="1.00" name="Test">
     <system-out>[[ATTACHMENT|/path/to/some/file]]</system-out>
   </testcase>
   ```

1. Dans votre fichier `.gitlab-ci.yml`, configurez votre job pour charger les captures d'écran en tant qu'artefacts :

   - Spécifiez le chemin vers vos fichiers de captures d'écran.
   - Facultatif. Utilisez [`artifacts:when: always`](../yaml/_index.md#artifactswhen) pour charger les captures d'écran lorsque les tests échouent.

   Par exemple :

   ```yaml
   ruby:
     stage: test
     script:
       - bundle install
       - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
       - # Your test framework should save screenshots to a directory
     artifacts:
       when: always
       paths:
         - rspec.xml
         - screenshots/
       reports:
         junit: rspec.xml
   ```

1. Exécutez votre pipeline.

Vous pouvez accéder au lien de la capture d'écran dans la boîte de dialogue des détails du test lorsque vous sélectionnez **Afficher les détails** pour un test en échec dans le panneau **Synthèse des tests**.

![Un rapport de test unitaire en échec avec les détails du test et une capture d'écran en pièce jointe](img/unit_test_report_screenshot_v18_1.png)

## Dépannage {#troubleshooting}

### Le rapport de tests apparaît vide {#test-report-appears-empty}

Il est possible que le panneau **Synthèse des tests** apparaisse vide dans les merge requests.

Ce problème survient lorsque :

- Les artefacts de rapport ont expiré.
- Les fichiers JUnit dépassent les limites de taille.

Pour résoudre ce problème, définissez une valeur [`expire_in`](../yaml/_index.md#artifactsexpire_in) plus longue pour l'artefact de rapport, ou exécutez un nouveau pipeline pour générer un nouveau rapport.

Si les fichiers JUnit dépassent les limites de taille, assurez-vous que :

- Les fichiers JUnit individuels sont inférieurs à 30 Mo.
- La taille totale de tous les fichiers JUnit pour le job est inférieure à 100 Mo.

La prise en charge des limites personnalisées est proposée dans l'[epic 16374](https://gitlab.com/groups/gitlab-org/-/epics/16374).

### Résultats des tests manquants {#test-results-are-missing}

Il est possible que vous voyiez moins de résultats de tests que prévu dans vos rapports.

Cela peut se produire lorsque vous avez des noms de tests en double dans votre fichier JUnit XML. Seul le premier test pour chaque nom est utilisé et les doublons sont ignorés.

Pour résoudre ce problème, assurez-vous que tous les noms et classes de tests sont uniques.

### Aucun rapport de tests n'apparaît dans les merge requests {#no-test-reports-appear-in-merge-requests}

Il est possible que le panneau **Synthèse des tests** n'apparaisse pas du tout dans les merge requests.

Ce problème peut survenir lorsque la branche cible ne dispose d'aucune donnée de test pour la comparaison.

Pour résoudre ce problème, exécutez un pipeline sur votre branche cible pour générer des données de test de référence.

### Erreurs de parsing JUnit XML {#junit-xml-parsing-errors}

Il est possible que des indicateurs d'erreur de parsing s'affichent en regard des noms de jobs dans votre pipeline.

Cela peut se produire lorsque les fichiers JUnit XML contiennent des erreurs de formatage ou des éléments non valides.

Pour résoudre ce problème :

- Vérifiez que vos fichiers JUnit XML respectent le format standard.
- Vérifiez que tous les éléments XML sont correctement fermés.
- Assurez-vous que les noms et valeurs d'attributs sont correctement formatés.

Pour les [jobs groupés](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views), seule la première erreur de parsing du groupe est affichée.
