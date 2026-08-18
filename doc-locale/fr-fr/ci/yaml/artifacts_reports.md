---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Types de rapports d'artefacts pour les résultats de tests, les analyses de sécurité, les vérifications de la qualité du code et les métriques de performance."
title: "Types de rapports d'artefacts CI/CD"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez [`artifacts:reports`](_index.md#artifactsreports) pour :

- Collecter des rapports de tests, des rapports de qualité du code, des rapports de sécurité et d'autres artefacts générés par les modèles inclus dans les jobs.
- Certains de ces rapports sont utilisés pour afficher des informations dans :
  - Merge requests
  - Les vues de pipeline.
  - [Tableaux de bord de sécurité](../../user/application_security/security_dashboard/_index.md).

Les artefacts créés pour `artifacts: reports` sont toujours chargés, quel que soit le résultat du job (succès ou échec). Vous pouvez utiliser [`artifacts:expire_in`](_index.md#artifactsexpire_in) pour définir une durée d'expiration pour les artefacts, ce qui remplace le [paramètre par défaut](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration) de l'instance. GitLab.com peut avoir une [valeur d'expiration des artefacts par défaut différente](../../user/gitlab_com/_index.md#cicd).

Certains types `artifacts:reports` peuvent être générés par plusieurs jobs dans le même pipeline et utilisés par les fonctionnalités de merge request ou de pipeline de chaque job.

Pour parcourir les fichiers de sortie du rapport, assurez-vous d'inclure le mot-clé [`artifacts:paths`](_index.md#artifactspaths) dans la définition de votre job.

> [!note]
> Les rapports combinés dans les pipelines parents utilisant les [artefacts des pipelines enfants](_index.md#needspipelinejob) ne sont pas pris en charge. La prise en charge de cette fonctionnalité est proposée dans l'epic [8205](https://gitlab.com/groups/gitlab-org/-/epics/8205).

## `artifacts:reports:accessibility` {#artifactsreportsaccessibility}

Le rapport `accessibility` utilise [pa11y](https://pa11y.org/) pour rendre compte de l'impact sur l'accessibilité des modifications introduites dans les merge requests.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans le [widget d'accessibilité](../testing/accessibility_testing.md#accessibility-merge-request-widget) de la merge request.

Pour plus d'informations, consultez [Tests d'accessibilité](../testing/accessibility_testing.md).

## `artifacts:reports:annotations` {#artifactsreportsannotations}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.

{{< /history >}}

Le rapport `annotations` est utilisé pour associer des données auxiliaires à un job.

Un rapport d'annotations est un fichier JSON comportant des sections d'annotations. Chaque section d'annotation peut avoir n'importe quel nom souhaité et peut contenir un nombre quelconque d'annotations du même type ou de types différents.

Chaque annotation est une clé unique (le type d'annotation), contenant les sous-clés avec les données de cette annotation.

### Types d'annotations {#annotation-types}

#### `external_link` {#external_link}

Une annotation `external_link` peut être associée à un job pour ajouter un lien à la page de sortie du job. La valeur d'une annotation `external_link` est un objet avec les clés suivantes :

| Clé     | Description |
|---------|-------------|
| `label` | Le label lisible par les humains associé au lien. |
| `url`   | L'URL pointée par le lien. |

### Exemple de rapport {#example-report}

Voici un exemple de ce à quoi peut ressembler un rapport d'annotations de job :

```json
{
  "my_annotation_section_1": [
    {
      "external_link": {
        "label": "URL 1",
        "url": "https://url1.example.com/"
      }
    },
    {
      "external_link": {
        "label": "URL 2",
        "url": "https://url2.example.com/"
      }
    }
  ]
}
```

## `artifacts:reports:api_fuzzing` {#artifactsreportsapi_fuzzing}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `api_fuzzing` collecte les [bugs de fuzzing d'API](../../user/application_security/api_fuzzing/_index.md) en tant qu'artefacts.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [widget de sécurité](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#view-details-of-an-api-fuzzing-vulnerability) de la merge request.
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).
- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [tableau de bord de sécurité](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#security-dashboard).

## `artifacts:reports:browser_performance` {#artifactsreportsbrowser_performance}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Le rapport `browser_performance` collecte les métriques de test de performance du navigateur en tant qu'artefact. Cet artefact est un fichier JSON généré par le [plugin GitLab pour sitespeed.io](https://gitlab.com/gitlab-org/gl-performance).

GitLab affiche les résultats dans la merge request. Pour plus d'informations, consultez [les tests de performance du navigateur](../testing/browser_performance_testing.md).

GitLab ne peut pas afficher les résultats combinés de plusieurs rapports `browser_performance`.

## `artifacts:reports:coverage_report` {#artifactsreportscoverage_report}

Utilisez `coverage_report` pour collecter un rapport de couverture au format Cobertura ou JaCoCo. Une fois le pipeline terminé, GitLab analyse le rapport et affiche les annotations de couverture ligne par ligne dans le diff de la merge request.

> [!note]
> Ce mot-clé produit uniquement des annotations de diff. Il n'affiche pas de pourcentage de couverture dans le widget de la MR et ne renseigne pas les graphiques d'historique de couverture. Pour afficher un pourcentage de couverture, configurez séparément le mot-clé [`coverage`](_index.md#coverage).

Pour plus d'informations, consultez la page suivante :

- [Visualisation de la couverture Cobertura](../testing/code_coverage/cobertura.md)
- [Visualisation de la couverture JaCoCo](../testing/code_coverage/jacoco.md)

```yaml
artifacts:
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

Vous pouvez générer plusieurs rapports et les collecter à l'aide de [caractères génériques](../jobs/job_artifacts.md#with-wildcards). GitLab fusionne les résultats en un seul rapport.

Les rapports de couverture des pipelines enfants apparaissent dans les annotations de diff de la merge request, mais ne sont pas partagés avec les pipelines parents.

## `artifacts:reports:codequality` {#artifactsreportscodequality}

Le rapport `codequality` collecte les [problèmes de qualité du code](../testing/code_quality.md). Le rapport de qualité du code collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [rapport de qualité du code](../../user/project/merge_requests/reports.md#code-quality-report) de la merge request.
- Les [annotations de diff](../testing/code_quality.md#merge-request-changes-view) de la merge request.
- Le [rapport complet](../testing/metrics_reports.md).

La valeur [`artifacts:expire_in`](_index.md#artifactsexpire_in) est définie sur `1 week`.

## `artifacts:reports:container_scanning` {#artifactsreportscontainer_scanning}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `container_scanning` collecte les [vulnérabilités de l'analyse des conteneurs](../../user/application_security/container_scanning/_index.md). Le rapport d'analyse des conteneurs collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [widget d'analyse des conteneurs](../../user/application_security/container_scanning/_index.md) de la merge request.
- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).

## `artifacts:reports:coverage_fuzzing` {#artifactsreportscoverage_fuzzing}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `coverage_fuzzing` collecte les [bugs de fuzzing de couverture](../../user/application_security/coverage_fuzzing/_index.md). Le rapport de fuzzing de couverture collecté est chargé dans GitLab en tant qu'artefact. GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [widget de fuzzing de couverture](../../user/application_security/coverage_fuzzing/_index.md#interacting-with-the-vulnerabilities) de la merge request.
- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:cyclonedx` {#artifactsreportscyclonedx}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Ce rapport est une nomenclature logicielle (Software Bill of Materials) décrivant les composants d'un projet selon le format de protocole [CycloneDX](https://cyclonedx.org/docs/1.4).

Vous pouvez spécifier plusieurs rapports CycloneDX par job. Ceux-ci peuvent être fournis sous forme de liste de noms de fichiers, d'un modèle de nom de fichier, ou des deux :

- Un modèle de nom de fichier (`cyclonedx: gl-sbom-*.json`, `junit: test-results/**/*.json`).
- Un tableau de noms de fichiers (`cyclonedx: [gl-sbom-npm-npm.cdx.json, gl-sbom-bundler-gem.cdx.json]`).
- Une combinaison des deux (`cyclonedx: [gl-sbom-*.json, my-cyclonedx.json]`).
- Les répertoires ne sont pas pris en charge (`cyclonedx: test-results`, `cyclonedx: test-results/**`).

L'exemple suivant montre un job qui expose des artefacts CycloneDX :

```yaml
artifacts:
  reports:
    cyclonedx:
      - gl-sbom-npm-npm.cdx.json
      - gl-sbom-bundler-gem.cdx.json
```

## `artifacts:reports:dast` {#artifactsreportsdast}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `dast` collecte les [vulnérabilités DAST](../../user/application_security/dast/_index.md). Le rapport DAST collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le widget de sécurité de la merge request.
- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:dependency_scanning` {#artifactsreportsdependency_scanning}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `dependency_scanning` collecte les [vulnérabilités d'analyse des dépendances](../../user/application_security/dependency_scanning/_index.md). Le rapport d'analyse des dépendances collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [widget d'analyse des dépendances](../../user/application_security/dependency_scanning/_index.md) de la merge request.
- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).
- La [liste des dépendances](../../user/application_security/dependency_list/_index.md).

## `artifacts:reports:dotenv` {#artifactsreportsdotenv}

Le rapport `dotenv` collecte les variables CI/CD d'un fichier et les rend disponibles en tant que variables CI/CD pour les jobs ultérieurs dans le pipeline.

Pour plus d'informations, consultez [les variables dotenv](../variables/dotenv_variables.md).

## `artifacts:reports:junit` {#artifactsreportsjunit}

Le rapport `junit` collecte les [fichiers XML au format de rapport JUnit](https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=formats-junit-xml-format). Les rapports de tests unitaires collectés sont chargés dans GitLab en tant qu'artefact. Bien que JUnit ait été développé à l'origine en Java, il existe de nombreux portages tiers pour d'autres langages tels que JavaScript, Python et Ruby.

Consultez [Rapports de tests unitaires](../testing/unit_test_reports.md) pour plus de détails et d'exemples. L'exemple suivant montre comment collecter un rapport XML JUnit à partir de tests Ruby RSpec :

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [panneau **Synthèse des tests**](../testing/unit_test_reports.md#view-test-results-in-merge-requests) de la merge request.
- L'[onglet **Tests** du pipeline](../testing/unit_test_reports.md#view-test-results-in-pipelines).

Certains outils JUnit exportent vers plusieurs fichiers XML. Vous pouvez spécifier plusieurs chemins de rapport de test dans un seul job pour les concaténer en un seul fichier. Utilisez l'une des options suivantes :

- Un modèle de nom de fichier (`junit: rspec-*.xml`, `junit: test-results/**/*.xml`).
- Un tableau de noms de fichiers (`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`).
- Une combinaison des deux (`junit: [rspec.xml, test-results/TEST-*.xml]`).
- Les répertoires ne sont pas pris en charge (`junit: test-results`, `junit: test-results/**`).

## `artifacts:reports:load_performance` {#artifactsreportsload_performance}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Le rapport `load_performance` collecte les [métriques de test de performance de charge](../testing/load_performance_testing.md) et est chargé en tant qu'artefact.

Les résultats sont affichés dans le [widget de test de charge](../testing/load_performance_testing.md#load-performance-results-in-merge-requests) de la merge request. Les résultats combinés de plusieurs rapports `load_performance` ne sont pas pris en charge.

## `artifacts:reports:metrics` {#artifactsreportsmetrics}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Le rapport `metrics` collecte les [métriques](../testing/metrics_reports.md). Le rapport de métriques collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans le [widget de rapports de métriques](../testing/metrics_reports.md) de la merge request.

## `artifacts:reports:requirements` {#artifactsreportsrequirements}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Le rapport `requirements` collecte les fichiers `requirements.json`. Le rapport d'exigences collecté est chargé dans GitLab en tant qu'artefact et les [exigences](../../user/project/requirements/_index.md) existantes sont marquées comme satisfaites.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans les [exigences du projet](../../user/project/requirements/_index.md#view-a-requirement).

## `artifacts:reports:sarif` {#artifactsreportssarif}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/452042) dans GitLab 18.11 avec un [feature flag](../../administration/feature_flags/_index.md) nommé `sarif_ingestion`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag nommé `sarif_ingestion`. Pour plus d'informations, consultez l'historique.

Le rapport `sarif` collecte les résultats de sécurité provenant d'outils émettant une sortie [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html). Le rapport SARIF collecté est chargé dans GitLab en tant qu'artefact.

Utilisez ce type de rapport pour ingérer les résultats de n'importe quel scanner compatible SARIF, tel que Semgrep, les plugins de sécurité ESLint ou les outils GitHub Advanced Security.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- L'[onglet **Sécurité**](../../user/application_security/detect/security_scanning_results.md) du pipeline.
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).
- Le [rapport de vulnérabilités du projet](../../user/application_security/vulnerability_report/_index.md).

**Exemple** :

```yaml
semgrep:
  image: returntocorp/semgrep
  script:
    - semgrep ci --sarif --output gl-sarif-report.sarif
  artifacts:
    reports:
      sarif: gl-sarif-report.sarif
```

Pour plus d'informations sur le comportement, les limites, le mappage des champs et les types de rapports inférés, consultez [Rapports SARIF](../../user/application_security/detect/sarif.md).

## `artifacts:reports:sast` {#artifactsreportssast}

Le rapport `sast` collecte les [vulnérabilités SAST](../../user/application_security/sast/_index.md). Le rapport SAST collecté est chargé dans GitLab en tant qu'artefact.

Pour plus d'informations, consultez la page suivante :

- [Afficher les résultats SAST](../../user/application_security/sast/_index.md#understanding-the-results)
- [Sortie SAST](../../user/application_security/sast/_index.md#download-a-sast-report)

## `artifacts:reports:secret_detection` {#artifactsreportssecret_detection}

Le rapport `secret-detection` collecte les [secrets détectés](../../user/application_security/secret_detection/pipeline/_index.md). Le rapport de détection des secrets collecté est chargé dans GitLab.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans :

- Le [widget d'analyse des secrets](../../user/application_security/secret_detection/pipeline/_index.md) de la merge request.
- L'[onglet sécurité du pipeline](../../user/application_security/detect/security_scanning_results.md).
- Le [tableau de bord de sécurité](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:terraform` {#artifactsreportsterraform}

Le rapport `terraform` obtient un fichier OpenTofu `tfplan.json`. [Traitement JQ requis pour supprimer les informations d'identification](../../user/infrastructure/iac/mr_integration.md#configure-opentofu-report-artifacts). Le rapport de plan OpenTofu collecté est chargé dans GitLab en tant qu'artefact.

GitLab peut afficher les résultats d'un ou plusieurs rapports dans le [widget OpenTofu](../../user/infrastructure/iac/mr_integration.md#output-opentofu-plan-information-into-a-merge-request) de la merge request.

Pour plus d'informations, consultez [Afficher les informations `tofu plan` dans une merge request](../../user/infrastructure/iac/mr_integration.md).
