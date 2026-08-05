---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'intégration des outils d'analyse de la qualité du code et des linters dans les pipelines CI/CD"
title: Qualité du code
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La qualité du code identifie les problèmes de maintenabilité avant qu'ils ne deviennent une dette technique. Les retours automatisés fournis lors des revues de code peuvent aider votre équipe à écrire un meilleur code. Les résultats apparaissent directement dans les merge requests, rendant les problèmes visibles au moment où il est le plus rentable de les corriger.

La qualité du code fonctionne avec plusieurs langages de programmation et s'intègre aux linters, vérificateurs de style et analyseurs de complexité courants. Vos outils existants peuvent alimenter le workflow de qualité du code, préservant ainsi les préférences de votre équipe tout en standardisant l'affichage des résultats.

## Fonctionnalités par édition {#features-per-tier}

Différentes fonctionnalités sont disponibles selon les [éditions GitLab](https://about.gitlab.com/pricing/), comme indiqué dans le tableau suivant :

| Fonctionnalité                                                                                     | Dans Free     | Dans Premium  | Dans Ultimate |
|:--------------------------------------------------------------------------------------------|:------------|:------------|:------------|
| [Importer les résultats de qualité du code depuis des jobs CI/CD](#import-code-quality-results-from-a-cicd-job) | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Utiliser l'analyse basée sur CodeClimate](#use-the-built-in-code-quality-cicd-template-deprecated)   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Voir les résultats dans les rapports de merge request](#merge-request-reports)                             | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Voir les résultats dans un rapport de pipeline](#pipeline-details-view)                                 | {{< no >}}  | {{< yes >}} | {{< yes >}} |
| [Voir les résultats dans la vue des modifications de la merge request](#merge-request-changes-view)               | {{< no >}}  | {{< no >}}  | {{< yes >}} |
| [Analyser l'état général dans une vue récapitulative de la qualité du projet](#project-quality-view)           | {{< no >}}  | {{< no >}}  | {{< yes >}} |

## Analyser le code pour détecter les violations de qualité {#scan-code-for-quality-violations}

La qualité du code est un système ouvert qui prend en charge l'importation des résultats de nombreux outils d'analyse. Pour détecter les violations et les faire remonter, vous pouvez :

- Utiliser directement un outil d'analyse et [importer ses résultats](#import-code-quality-results-from-a-cicd-job). _(Recommandé.)_
- [Utiliser un template CI/CD intégré](#use-the-built-in-code-quality-cicd-template-deprecated) pour activer l'analyse. Le template utilise le moteur CodeClimate, qui encapsule des outils open source courants. _(Déprécié.)_

Vous pouvez capturer les résultats de plusieurs outils dans un seul pipeline. Par exemple, vous pouvez exécuter un linter de code pour analyser votre code ainsi qu'un linter de langage pour analyser votre documentation, ou utiliser un outil autonome conjointement à une analyse basée sur CodeClimate. La qualité du code combine tous les rapports afin que vous les voyiez tous lorsque vous [consultez les résultats](#view-code-quality-results).

### Importer les résultats de qualité du code depuis un job CI/CD {#import-code-quality-results-from-a-cicd-job}

De nombreuses équipes de développement utilisent déjà des linters, des vérificateurs de style ou d'autres outils dans leurs pipelines CI/CD pour détecter automatiquement les violations des normes de codage. Vous pouvez faciliter la visualisation et la correction des résultats de ces outils en les intégrant à la qualité du code.

Pour vérifier si votre outil dispose déjà d'une intégration documentée, consultez [Intégrer des outils courants avec la qualité du code](#integrate-common-tools-with-code-quality).

Pour intégrer un autre outil à la qualité du code :

1. Ajoutez l'outil à votre pipeline CI/CD.
1. Configurez l'outil pour qu'il génère un rapport sous forme de fichier.
   - Ce fichier doit utiliser un [format JSON spécifique](#code-quality-report-format).
   - De nombreux outils prennent en charge ce format de sortie de manière native. Ils peuvent l'appeler « rapport CodeClimate », « rapport GitLab Code Quality » ou un autre nom similaire.
   - D'autres outils peuvent parfois créer une sortie JSON en utilisant un format JSON personnalisé ou un template. Étant donné que le [format de rapport](#code-quality-report-format) ne comporte que quelques champs obligatoires, vous pourrez peut-être utiliser ce type de sortie pour créer un rapport de qualité du code.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) correspondant à ce fichier.

Désormais, après l'exécution du pipeline, les résultats de l'outil de qualité sont [traités et affichés](#view-code-quality-results).

### Utiliser le template CI/CD intégré de qualité du code (déprécié) {#use-the-built-in-code-quality-cicd-template-deprecated}

> [!warning]
> Cette fonctionnalité a été [dépréciée](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed) dans GitLab 17.3 et sa suppression est prévue dans la version 19.0. [Intégrez directement les résultats d'un outil pris en charge](#import-code-quality-results-from-a-cicd-job) à la place.

La qualité du code inclut également un template CI/CD intégré, `Code-Quality.gitlab-ci.yaml`. Ce template exécute une analyse basée sur le moteur d'analyse open source CodeClimate.

Le moteur CodeClimate exécute :

- Des vérifications de maintenabilité de base pour un [ensemble de langages pris en charge](https://docs.codeclimate.com/docs/supported-languages-for-maintainability).
- Un ensemble configurable de [plugins](https://docs.codeclimate.com/docs/list-of-engines), qui encapsulent des scanners open source, pour analyser votre code source.

Pour plus de détails, consultez [Configurer l'analyse de qualité du code basée sur CodeClimate](code_quality_codeclimate_scanning.md).

#### Migrer depuis l'analyse basée sur CodeClimate {#migrate-from-codeclimate-based-scanning}

Le moteur CodeClimate utilise un ensemble personnalisable de [plugins d'analyse](code_quality_codeclimate_scanning.md#configure-codeclimate-analysis-plugins). Certains sont activés par défaut ; d'autres doivent être explicitement activés. Les intégrations suivantes sont disponibles pour remplacer les plugins intégrés :

| Plugin       | Activé par défaut                    | Remplacement |
|--------------|----------------------------------|-------------|
| Duplication  | {{< yes >}}                      | [Intégrer PMD Copy/Paste Detector](#pmd-copypaste-detector). |
| ESLint       | {{< yes >}}                      | [Intégrer ESLint](#eslint). |
| gofmt        | {{< no >}}                       | [Intégrer golangci-lint](#golangci-lint) et activer le [linter gofmt](https://golangci-lint.run/usage/linters#gofmt). |
| golint       | {{< no >}}                       | [Intégrer golangci-lint](#golangci-lint) et activer l'un des linters inclus qui remplace golint. golint est [déprécié et figé](https://github.com/golang/go/issues/38968). |
| govet        | {{< no >}}                       | [Intégrer golangci-lint](#golangci-lint). golangci-lint [inclut govet par défaut](https://golangci-lint.run/usage/linters#enabled-by-default). |
| markdownlint | {{< no >}} (pris en charge par la communauté) | [Intégrer markdownlint-cli2](#markdownlint-cli2). |
| pep8         | {{< no >}}                       | Intégrez un linter Python alternatif tel que [Flake8](#flake8), [Pylint](#pylint) ou [Ruff](#ruff). |
| RuboCop      | {{< yes >}}                      | [Intégrer RuboCop](#rubocop). |
| SonarPython  | {{< no >}}                       | Intégrez un linter Python alternatif tel que [Flake8](#flake8), [Pylint](#pylint) ou [Ruff](#ruff). |
| Stylelint    | {{< no >}} (pris en charge par la communauté) | [Intégrer Stylelint](#stylelint). |
| SwiftLint    | {{< no >}}                       | [Intégrer SwiftLint](#swiftlint). |

## Consulter les résultats de qualité du code {#view-code-quality-results}

Les résultats de qualité du code sont affichés dans :

- [Rapports de merge request](#merge-request-reports)
- [Vue des modifications de la merge request](#merge-request-changes-view)
- [Vue détaillée du pipeline](#pipeline-details-view)
- [Vue de la qualité du projet](#project-quality-view)

### Rapports de merge request {#merge-request-reports}

Les résultats de l'analyse de la qualité du code s'affichent dans l'onglet **Rapports** de la merge request. Plusieurs résultats de qualité du code ayant des empreintes identiques s'affichent comme une seule entrée.

Pour plus d'informations, consultez [les rapports de merge request](../../user/project/merge_requests/reports.md).

### Vue des modifications de merge request {#merge-request-changes-view}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les résultats de qualité du code s'affichent dans la vue **Modifications** de la merge request. Les lignes contenant des problèmes de qualité du code sont marquées par un symbole à côté de la marge. Sélectionnez le symbole pour afficher la liste des problèmes, puis sélectionnez un problème pour en afficher les détails.

![Lignes de l'onglet des modifications d'une merge request marquées d'un symbole pour indiquer les problèmes de qualité du code](img/code_quality_changes_view_v18_2.png)

### Vue détaillée du pipeline {#pipeline-details-view}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La liste complète des violations de qualité du code générées par un pipeline est affichée dans l'onglet **Qualité du code** de la page de détails du pipeline. La vue détaillée du pipeline affiche tous les résultats de qualité du code trouvés sur la branche sur laquelle il a été exécuté.

![Liste de tous les tickets de la branche, classés par gravité décroissante](img/code_quality_pipeline_details_view_v18_2.png)

### Vue de la qualité du projet {#project-quality-view}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724) dans GitLab 14.5 [avec un flag](../../administration/feature_flags/_index.md) nommé `project_quality_summary_page`. Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md). Désactivé par défaut.

{{< /history >}}

La vue de la qualité du projet affiche une vue d'ensemble des résultats de qualité du code. La vue est accessible sous **Analyse** > **Données d'analyse CI/CD**, et nécessite que le feature flag [`project_quality_summary_page`](../../administration/feature_flags/_index.md) soit activé pour ce projet particulier.

![Nombre total de tickets, appelés violations, suivi du nombre de tickets pour chaque niveau de gravité](img/code_quality_summary_v15_9.png)

## Format de rapport de qualité du code {#code-quality-report-format}

Vous pouvez [importer les résultats de qualité du code](#import-code-quality-results-from-a-cicd-job) depuis n'importe quel outil capable de générer un rapport dans le format suivant. Ce format est une version du [format de rapport CodeClimate](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) qui inclut un nombre réduit de champs.

Le fichier que vous fournissez en tant qu'[artefact de rapport de qualité du code](../yaml/artifacts_reports.md#artifactsreportscodequality) doit contenir un tableau JSON unique. Chaque objet de ce tableau doit posséder au minimum les propriétés suivantes :

| Nom                                                      | Type    | Description |
|-----------------------------------------------------------|---------|-------------|
| `description`                                             | Chaîne  | Une description lisible par l'humain de la violation de qualité du code. |
| `check_name`                                              | Chaîne  | Un nom unique représentant la vérification, ou la règle, associée à cette violation. |
| `fingerprint`                                             | Chaîne  | Une empreinte unique pour identifier cette violation de qualité du code spécifique, par exemple un hachage de son contenu. |
| `location.path`                                           | Chaîne  | Le fichier contenant la violation de qualité du code, exprimé sous forme de chemin relatif dans le dépôt. Ne pas préfixer avec `./`. |
| `location.lines.begin` ou `location.positions.begin.line` | Entier | La ligne sur laquelle la violation de qualité du code s'est produite. |
| `severity`                                                | Chaîne  | La gravité de la violation, qui peut être l'une des valeurs suivantes : `info`, `minor`, `major`, `critical` ou `blocker`. |

Le format diffère du [format de rapport CodeClimate](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) de la manière suivante :

- Bien que le [format de rapport CodeClimate](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) prenne en charge davantage de propriétés, la qualité du code ne traite que les champs listés précédemment.
- L'analyseur GitLab n'autorise pas de [marque d'ordre d'octet](https://en.wikipedia.org/wiki/Byte_order_mark) au début du fichier.

Par exemple, voici un rapport conforme :

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "check_name": "no-unused-vars",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```

## Intégrer des outils courants avec la qualité du code {#integrate-common-tools-with-code-quality}

De nombreux outils prennent nativement en charge le [format de rapport](#code-quality-report-format) requis pour intégrer leurs résultats à la qualité du code. Ils peuvent l'appeler « rapport CodeClimate », « rapport GitLab Code Quality » ou un autre nom similaire.

D'autres outils peuvent être configurés pour créer une sortie JSON en fournissant un template personnalisé ou une spécification de format. Étant donné que le [format de rapport](#code-quality-report-format) ne comporte que quelques champs obligatoires, vous pourrez peut-être utiliser ce type de sortie pour créer un rapport de qualité du code.

Si vous utilisez déjà un outil dans votre pipeline CI/CD, vous devriez adapter le job existant pour y ajouter un rapport de qualité du code. L'adaptation du job existant vous évite d'exécuter un job séparé qui pourrait dérouter les développeurs et allonger la durée d'exécution de vos pipelines.

Si vous n'utilisez pas encore d'outil, vous pouvez écrire un job CI/CD de toutes pièces ou adopter l'outil en utilisant un composant CI/CD du [catalogue CI/CD](../components/_index.md#cicd-catalog).

### Outils d'analyse du code {#code-scanning-tools}

#### ESLint {#eslint}

Si vous avez déjà un job [ESLint](https://eslint.org/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Ajoutez [`eslint-formatter-gitlab`](https://www.npmjs.com/package/eslint-formatter-gitlab) comme dépendance de développement dans votre projet.
1. Ajoutez l'option `--format gitlab` à la commande que vous utilisez pour exécuter ESLint.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.
   - Par défaut, le formateur lit votre configuration CI/CD et déduit le nom du fichier dans lequel il doit enregistrer le rapport. Si le formateur ne parvient pas à déduire le nom de fichier que vous avez utilisé dans votre déclaration d'artefact, définissez la variable CI/CD `ESLINT_CODE_QUALITY_REPORT` sur le nom de fichier spécifié pour votre artefact, tel que `gl-code-quality-report.json`.

Vous pouvez également utiliser ou adapter le [composant CI/CD ESLint](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### Stylelint {#stylelint}

Si vous avez déjà un job [Stylelint](https://stylelint.io/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Ajoutez [`@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab) comme dépendance de développement dans votre projet.
1. Ajoutez l'option `--custom-formatter=@studiometa/stylelint-formatter-gitlab` à la commande que vous utilisez pour exécuter Stylelint.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.
   - Par défaut, le formateur lit votre configuration CI/CD et déduit le nom du fichier dans lequel il doit enregistrer le rapport. Si le formateur ne parvient pas à déduire le nom de fichier que vous avez utilisé dans votre déclaration d'artefact, définissez la variable CI/CD `STYLELINT_CODE_QUALITY_REPORT` sur le nom de fichier spécifié pour votre artefact, tel que `gl-code-quality-report.json`.

Pour plus de détails et un exemple de définition de job CI/CD, consultez la [documentation de `@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab#usage).

#### MyPy {#mypy}

Si vous avez déjà un job [MyPy](https://mypy-lang.org/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Installez [`mypy-gitlab-code-quality`](https://pypi.org/project/mypy-gitlab-code-quality/) comme dépendance dans votre projet.
1. Modifiez votre commande `mypy` pour envoyer sa sortie vers un fichier.
1. Ajoutez une étape au `script` de votre job pour retraiter le fichier dans le format requis en utilisant `mypy-gitlab-code-quality`. Par exemple :

   ```yaml
   - mypy $(find -type f -name "*.py" ! -path "**/.venv/**") --no-error-summary > mypy-out.txt || true  # "|| true" is used for preventing job failure when mypy find errors
   - mypy-gitlab-code-quality < mypy-out.txt > gl-code-quality-report.json
   ```

1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter le [composant CI/CD MyPy](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### Flake8 {#flake8}

Si vous avez déjà un job [Flake8](https://flake8.pycqa.org/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Installez [`flake8-gl-codeclimate`](https://github.com/awelzel/flake8-gl-codeclimate) comme dépendance dans votre projet.
1. Ajoutez les arguments `--format gl-codeclimate --output-file gl-code-quality-report.json` à la commande que vous utilisez pour exécuter Flake8.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter le [composant CI/CD Flake8](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### Pylint {#pylint}

Si vous avez déjà un job [Pylint](https://pypi.org/project/pylint/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Installez [`pylint-gitlab`](https://pypi.org/project/pylint-gitlab/) comme dépendance dans votre projet.
1. Ajoutez l'argument `--output-format=pylint_gitlab.GitlabCodeClimateReporter` à la commande que vous utilisez pour exécuter Pylint.
1. Modifiez votre commande `pylint` pour envoyer sa sortie vers un fichier.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter le [composant CI/CD Pylint](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### Ruff {#ruff}

Si vous avez déjà un job [Ruff](https://docs.astral.sh/ruff/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Ajoutez l'argument `--output-format=gitlab` à la commande que vous utilisez pour exécuter Ruff.
1. Modifiez votre commande `ruff check` pour envoyer sa sortie vers un fichier.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter l'[intégration GitLab CI/CD Ruff documentée](https://docs.astral.sh/ruff/integrations/#gitlab-cicd) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### golangci-lint {#golangci-lint}

Si vous avez déjà un job [`golangci-lint`](https://golangci-lint.run/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Ajoutez les arguments à la commande que vous utilisez pour exécuter `golangci-lint`.

   - Pour la v1, ajoutez `--out-format code-climate:gl-code-quality-report.json,line-number`.
   - Pour la v2, ajoutez `--output.code-climate.path=gl-code-quality-report.json`.

1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter le [composant CI/CD golangci-lint](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### PMD Copy/Paste Detector {#pmd-copypaste-detector}

Le [PMD Copy/Paste Detector (CPD)](https://pmd.github.io/pmd/pmd_userdocs_cpd.html) nécessite une configuration supplémentaire car sa sortie par défaut n'est pas conforme au format requis.

Vous pouvez utiliser ou adapter le [composant CI/CD PMD](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### SwiftLint {#swiftlint}

L'utilisation de [SwiftLint](https://realm.github.io/SwiftLint/) nécessite une configuration supplémentaire car sa sortie par défaut n'est pas conforme au format requis.

Vous pouvez utiliser ou adapter le [composant CI/CD Swiftlint](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### RuboCop {#rubocop}

L'utilisation de [RuboCop](https://rubocop.org/) nécessite une configuration supplémentaire car sa sortie par défaut n'est pas conforme au format requis.

Vous pouvez utiliser ou adapter le [composant CI/CD RuboCop](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

#### Roslynator {#roslynator}

L'utilisation de [Roslynator](https://josefpihrt.github.io/docs/roslynator/) nécessite une configuration supplémentaire car sa sortie par défaut n'est pas conforme au format requis.

Vous pouvez utiliser ou adapter le [composant CI/CD Roslynator](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration) pour exécuter l'analyse et intégrer sa sortie à la qualité du code.

### Outils d'analyse de la documentation {#documentation-scanning-tools}

Vous pouvez utiliser la qualité du code pour analyser n'importe quel fichier stocké dans un dépôt, même s'il ne s'agit pas de code.

#### Vale {#vale}

Si vous avez déjà un job [Vale](https://vale.sh/) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Créez un fichier template Vale dans votre dépôt qui définit le format requis.
   - Vous pouvez copier le [template open source utilisé pour vérifier la documentation GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/vale-json.tmpl).
   - Vous pouvez également utiliser une autre variante open source comme celle utilisée dans le [projet Vale `gitlab-ci-utils` de la communauté](https://gitlab.com/gitlab-ci-utils/container-images/vale/-/blob/main/vale/vale-glcq.tmpl). Ce projet communautaire fournit également [une image de conteneur préconfigurée](https://gitlab.com/gitlab-ci-utils/container-images/vale) qui inclut le même template afin que vous puissiez l'utiliser directement dans vos pipelines.
1. Ajoutez les arguments `--output="$VALE_TEMPLATE_PATH" --no-exit` à la commande que vous utilisez pour exécuter Vale.
1. Modifiez votre commande `vale` pour envoyer sa sortie vers un fichier.
1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport.

Vous pouvez également utiliser ou adapter une définition de job open source pour exécuter l'analyse et intégrer sa sortie à la qualité du code, par exemple :

- L'[étape de linting Vale](https://gitlab.com/gitlab-org/gitlab/-/blob/94f870b8e4b965a41dd2ad576d50f7eeb271f117/.gitlab/ci/docs.gitlab-ci.yml#L71-87) utilisée pour vérifier la documentation GitLab.
- Le [projet Vale `gitlab-ci-utils` de la communauté](https://gitlab.com/gitlab-ci-utils/container-images/vale#usage).

#### markdownlint-cli2 {#markdownlint-cli2}

Si vous avez déjà un job [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) dans vos pipelines CI/CD, vous devriez ajouter un rapport pour envoyer sa sortie vers la qualité du code. Pour intégrer sa sortie :

1. Ajoutez [`markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality) comme dépendance de développement dans votre projet.
1. Si vous n'en avez pas encore, créez un fichier `.markdownlint-cli2.jsonc` à la racine de votre dépôt.
1. Ajoutez une directive `outputFormatters` dans `.markdownlint-cli2.jsonc` :

   ```json
   {
     "outputFormatters": [
       [ "markdownlint-cli2-formatter-codequality" ]
     ]
   }
   ```

1. Déclarez un [artefact de rapport `codequality`](../yaml/artifacts_reports.md#artifactsreportscodequality) qui pointe vers l'emplacement du fichier de rapport. Par défaut, le fichier de rapport est nommé `markdownlint-cli2-codequality.json`.
   1. Recommandé. Ajoutez le nom du fichier de rapport au fichier `.gitignore` du dépôt.

Pour plus de détails et un exemple de définition de job CI/CD, consultez la [documentation de `markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality).
