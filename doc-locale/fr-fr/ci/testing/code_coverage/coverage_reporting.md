---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Afficher un pourcentage de couverture de test dans les merge requests, les analyses et les badges."
title: Rapport de couverture
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le mot-clé [`coverage`](../../yaml/_index.md#coverage) pour extraire un pourcentage de couverture depuis la sortie du job log de votre test et l'afficher dans les merge requests et les analyses.

Ce mot-clé affiche uniquement un pourcentage de couverture. Il ne produit pas d'annotations ligne par ligne dans le diff de la MR. Pour afficher les annotations de ligne, configurez [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) séparément.

## Configurer le rapport de couverture {#configure-coverage-reporting}

Pour configurer le rapport de couverture :

1. Ajoutez le mot-clé `coverage` à votre job avec une expression régulière correspondant à la sortie de votre outil de test :

   ```yaml
   test:
     script:
       - pytest --cov
     coverage: '/TOTAL.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
   ```

1. Pour agréger la couverture de plusieurs jobs, ajoutez le mot-clé `coverage` à chaque job.

### Modèles d'expressions régulières de couverture {#coverage-regex-patterns}

Les modèles d'expressions régulières suivants correspondent à la sortie des outils de couverture de test courants. Testez-les soigneusement, car les formats de sortie des outils peuvent changer au fil du temps.

{{< tabs >}}

{{< tab title="Python and Ruby" >}}

| Outil           | Langage | Commande        | Modèle d'expression régulière |
| -------------- | -------- | -------------- | ------------- |
| pytest-cov     | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov-html | Ruby     | `rspec spec`   | `/Line\sCoverage:\s\d+\.\d+%/` |

{{< /tab >}}

{{< tab title="C/C++ and Rust" >}}

| Outil      | Langage | Commande           | Modèle d'expression régulière |
| --------- | -------- | ----------------- | ------------- |
| gcovr     | C/C++    | `gcovr`           | `/^TOTAL.*\s+(\d+\%)$/` |
| tarpaulin | Rust     | `cargo tarpaulin` | `/^\d+.\d+% coverage/` |

{{< /tab >}}

{{< tab title="Java and JVM" >}}

| Outil      | Langage    | Commande                            | Modèle d'expression régulière |
| --------- | ----------- | ---------------------------------- | ------------- |
| JaCoCo    | Java/Kotlin | `./gradlew test jacocoTestReport`  | `/Total.*?([0-9]{1,3})%/` |
| Scoverage | Scala       | `sbt coverage test coverageReport` | `/(?i)total.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |

{{< /tab >}}

{{< tab title="Node.js" >}}

| Outil      | Commande                                    | Modèle d'expression régulière |
| --------- | ------------------------------------------ | ------------- |
| tap       | `tap --coverage-report=text-summary`       | `/^Statements\s*:\s*([^%]+)/` |
| nyc       | `nyc npm test`                             | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| jest      | `jest --ci --coverage`                     | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| node:test | `node --experimental-test-coverage --test` | `/all files[^\|]*\|[^\|]*\s+([\d\.]+)/` |

{{< /tab >}}

{{< tab title="PHP" >}}

| Outil    | Commande                                  | Modèle d'expression régulière |
| ------- | ---------------------------------------- | ------------- |
| pest    | `pest --coverage --colors=never`         | `/Statement coverage[A-Za-z\.*]\s*:\s*([^%]+)/` |
| phpunit | `phpunit --coverage-text --colors=never` | `/^\s*Lines:\s*\d+.\d+\%/` |

{{< /tab >}}

{{< tab title="Go" >}}

| Outil              | Commande                                                                    | Modèle d'expression régulière |
| ----------------- | -------------------------------------------------------------------------- | ------------- |
| go test (single)  | `go test -cover`                                                           | `/coverage: \d+.\d+% of statements/` |
| go test (project) | `go test -coverprofile=cover.profile && go tool cover -func cover.profile` | `/total:\s+\(statements\)\s+\d+.\d+%/` |

{{< /tab >}}

{{< tab title=".NET and PowerShell" >}}

| Outil        | Langage   | Commande       | Modèle d'expression régulière |
| ----------- | ---------- | ------------- | ------------- |
| OpenCover   | .NET       | Aucune          | `/(Visited Points).*\((.*)\)/` |
| dotnet test | .NET       | `dotnet test` | `/Total\s*\|*\s(\d+(?:\.\d+)?)/` |
| Pester      | PowerShell | Aucune          | `/Covered (\d{1,3}(\.\|,)?\d{0,2}%)/` |

{{< /tab >}}

{{< tab title="Elixir" >}}

| Outil        | Commande            | Modèle d'expression régulière |
| ----------- | ------------------ | ------------- |
| excoveralls | Aucune               | `/\[TOTAL\]\s+(\d+\.\d+)%/` |
| mix         | `mix test --cover` | `/\d+.\d+\%\s+\|\s+Total/` |

{{< /tab >}}

{{< /tabs >}}

## Ajouter une règle d'approbation de vérification de couverture {#add-a-coverage-check-approval-rule}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Vous pouvez demander à des utilisateurs spécifiques ou à un groupe d'approuver les merge requests qui réduisent la couverture de test du projet.

Prérequis :

- Configurez le rapport de couverture.

Pour ajouter une règle d'approbation `Coverage-Check` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Sous **Approbations des requêtes de fusion**, effectuez l'une des opérations suivantes :
   - À côté de la règle d'approbation `Coverage-Check`, sélectionnez **Activer**.
   - Pour une configuration manuelle, sélectionnez **Ajouter une règle d'approbation**, puis saisissez `Coverage-Check` comme **Nom de la règle**.
1. Sélectionnez une **Branche cible**.
1. Définissez le **Nombre requis d'approbations**.
1. Sélectionnez les **Utilisateurs** ou les **Groupes** chargés de fournir l'approbation.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> La règle d'approbation `Coverage-Check` requiert une approbation lorsque le pipeline de base de fusion ne contient aucune donnée de couverture, même si la merge request améliore la couverture globale.

## Afficher l'historique de couverture {#view-coverage-history}

Vous pouvez suivre les tendances de couverture de votre projet ou groupe au fil du temps.

### Pour un projet {#for-a-project}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse du dépôt**.
1. Dans la liste déroulante, sélectionnez le job pour lequel vous souhaitez afficher les données historiques.
1. facultatif. Pour télécharger les données, sélectionnez **Télécharger les données brutes (.csv)**.

### Pour un groupe {#for-a-group}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse du dépôt**.
1. facultatif. Pour télécharger les données, sélectionnez **Télécharger les données de couverture de test historisées (.csv)**.

## Afficher les badges de couverture {#display-coverage-badges}

Pour ajouter un badge de couverture à votre projet, consultez [les badges de rapport de couverture de test](../../../user/project/badges.md#test-coverage-report-badges).

## Dépannage {#troubleshooting}

Lorsque vous utilisez le rapport de couverture, vous pouvez rencontrer les problèmes suivants.

### Le pourcentage de couverture n'apparaît pas dans le widget MR {#coverage-percentage-does-not-appear-in-the-mr-widget}

Le mot-clé `coverage` extrait un pourcentage depuis la sortie du job log de votre job à l'aide d'une expression régulière. Si le pourcentage n'apparaît pas :

- Vérifiez que votre expression régulière correspond à la sortie réelle de votre outil. Copiez une ligne depuis le job log et testez-la avec votre expression régulière.
- Certains outils produisent des codes de couleur ANSI qui perturbent la correspondance par expression régulière. Si votre outil ne prend pas en charge la désactivation de la sortie en couleur, supprimez les codes avant l'analyse :

  ```shell
  lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
  ```

- Vérifiez que le job s'est terminé avec succès. La couverture est extraite uniquement des jobs réussis.
- La sortie de couverture des pipelines enfants n'est pas enregistrée. Pour plus de détails, consultez [l'issue 280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818).

> [!note]
> Le mot-clé `coverage` affiche uniquement un pourcentage dans le widget MR. Pour les annotations ligne par ligne dans le diff, configurez [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) séparément.
