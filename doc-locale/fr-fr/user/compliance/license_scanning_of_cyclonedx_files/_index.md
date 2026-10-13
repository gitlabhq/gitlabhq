---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse de licences des fichiers CycloneDX
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'analyseur de conformité des licences hérité (`License-Scanning.gitlab-ci.yml`) a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/439162) dans GitLab 17.0.
- GitLab 17.5 a introduit la prise en charge de l'utilisation d'un artefact de rapport CycloneDX comme source de données pour les informations de licence. Cette fonctionnalité a été publiée derrière le feature flag `license_scanning_with_sbom_licenses`, et désactivée par défaut.
- Dans GitLab 17.6, l'utilisation d'un artefact de rapport CycloneDX comme source de données pour les informations de licence a été activée par défaut. Le feature flag `license_scanning_with_sbom_licenses` était toujours présent pour désactiver la fonctionnalité si nécessaire.
- Dans GitLab 17.8, le feature flag `license_scanning_with_sbom_licenses` a été supprimé.

{{< /history >}}

Pour détecter les licences utilisées, la conformité des licences repose sur l'exécution des [jobs d'analyse des dépendances](../../application_security/dependency_scanning/_index.md), et sur l'analyse du Software Bill of Materials (SBOM) [CycloneDX](https://cyclonedx.org/) généré par ces jobs. Cette méthode d'analyse est capable de parser et d'identifier plus de 600 types de licences différents, tels que définis dans [la liste SPDX](https://spdx.org/licenses/). Des scanners tiers peuvent être utilisés pour générer la liste des dépendances, à condition qu'ils produisent un artefact de rapport CycloneDX pour [un langage pris en charge](#supported-languages-and-package-managers) et qu'ils suivent la taxonomie des propriétés CycloneDX de GitLab. La possibilité de fournir d'autres licences est suivie dans l'epic [10861](https://gitlab.com/groups/gitlab-org/-/epics/10861).

> [!note]
> La fonctionnalité d'analyse de licences repose sur des métadonnées de paquets accessibles publiquement, collectées dans une base de données externe et synchronisées automatiquement avec l'instance GitLab. Cette base de données est un bucket Google Cloud Storage multirégional hébergé aux États-Unis. L'analyse est exécutée exclusivement au sein de l'instance GitLab. Aucune information contextuelle (par exemple, une liste de dépendances de projet) n'est envoyée au service externe.

## Configuration {#configuration}

Pour activer l'analyse de licences des fichiers CycloneDX :

- Utilisation du template d'analyse des dépendances
  - Activez l'[analyse des dépendances](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning) et assurez-vous que ses prérequis sont satisfaits.
  - Sur GitLab Self-Managed, vous pouvez [choisir les métadonnées du registre de paquets à synchroniser](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) dans la zone **Admin** pour l'instance GitLab. Pour que cette synchronisation des données fonctionne, vous devez autoriser le trafic réseau sortant depuis votre instance GitLab vers le domaine `storage.googleapis.com`. Si votre connectivité réseau est limitée ou inexistante, reportez-vous à la section de documentation [fonctionnement dans un environnement hors ligne](#running-in-an-offline-environment) pour obtenir des conseils supplémentaires.
- Ou utilisez le [composant CI/CD](../../../ci/components/_index.md) pour les registres de paquets applicables.

## Langages pris en charge et gestionnaires de paquets {#supported-languages-and-package-managers}

{{< history >}}

- Prise en charge de Swift [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/506756) dans GitLab 17.9.
- Prise en charge de Dart [introduite](https://gitlab.com/groups/gitlab-org/-/epics/18351) dans GitLab 18.10.

{{< /history >}}

L'analyse de licences est prise en charge pour les langages et gestionnaires de paquets suivants :

<!-- markdownlint-disable MD044 -->
<table class="supported-languages">
  <thead>
    <tr>
      <th>Langage</th>
      <th>Gestionnaire de paquets</th>
      <th>Template d'analyse des dépendances</th>
      <th>Composant CI/CD</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>C#</td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>C++</td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>Dart</td>
      <td><a href="https://pub.dev/">pub</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>Go<sup>1</sup></td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td rowspan="3">Java</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://developer.android.com/">Android</a></td>
      <td>Oui</td>
      <td><a href="https://gitlab.com/components/android-dependency-scanning">Oui</a></td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript et TypeScript</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td rowspan="4">Python</td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td><a href="https://doc.rust-lang.org/cargo/">cargo</a></td>
      <td>Non</td>
      <td><a href="https://gitlab.com/components/dependency-scanning#generating-cargo-sboms">Oui</a></td>
    </tr>
    <tr>
      <td>Scala</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td><a href="https://developer.apple.com/swift/">sbt</a></td>
      <td>Oui</td>
      <td>Non</td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-enable MD044 -->

**Notes de bas de page** :

1. Les bibliothèques standard Go telles que `stdlib` ne sont pas prises en charge et apparaîtront avec une licence `unknown`. La prise en charge de celles-ci est suivie dans le [ticket 480305](https://gitlab.com/gitlab-org/gitlab/-/issues/480305).

Les fichiers et versions pris en charge sont ceux pris en charge par l'[analyse des dépendances](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files).

## Sources de données {#data-sources}

Les informations de licence pour les paquets pris en charge sont obtenues à partir des sources ci-dessous. GitLab effectue un traitement supplémentaire sur les données d'origine, qui comprend le mappage des variations vers les noms de licences canoniques.

| Gestionnaire de paquets | Source                                                           |
|-----------------|------------------------------------------------------------------|
| Cargo           | <https://deps.dev/>                                              |
| Conan           | <https://github.com/conan-io/conan-center-index>                 |
| Go              | <https://index.golang.org/>                                      |
| Maven           | <https://storage.googleapis.com/maven-central>                   |
| npm             | <https://deps.dev/>                                              |
| NuGet           | <https://api.nuget.org/v3/catalog0/index.json>                   |
| Packagist       | <https://packagist.org/packages/list.json>                       |
| pub             | <https://pub.dev/>                                               |
| PyPI            | <https://warehouse.pypa.io/api-reference/bigquery-datasets.html> |
| RubyGems        | <https://rubygems.org/versions>                                  |

## Expressions de licence {#license-expressions}

{{< history >}}

- Prise en charge des expressions de licence SPDX dans les SBOMs CycloneDX [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225) dans GitLab 19.3.

{{< /history >}}

GitLab lit les [expressions de licence](https://spdx.github.io/spdx-spec/v2-draft/SPDX-license-expressions/) SPDX depuis le champ `expression` dans les SBOMs CycloneDX, y compris la syntaxe `LicenseRef-[NAME]` pour les licences personnalisées non-SPDX. Lorsque l'entrée SBOM d'un composant inclut une `expression`, GitLab stocke et évalue l'expression complète. Auparavant, les composants avec des expressions de licence apparaissaient avec une licence `unknown`.

Les expressions de licence sont prises en charge dans les [politiques d'approbation de licences](../license_approval_policies.md). Lorsqu'une politique cible une licence qui apparaît comme un terme dans l'expression d'un composant, la politique s'évalue correctement par rapport à l'expression complète.

## Blocage des merge requests en fonction des licences détectées {#blocking-merge-requests-based-on-detected-licenses}

Les utilisateurs peuvent exiger une approbation pour les merge requests en fonction des licences détectées en configurant une [politique d'approbation de licences](../license_approval_policies.md).

## Fonctionnement dans un environnement hors ligne {#running-in-an-offline-environment}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, des ajustements sont nécessaires pour analyser avec succès les rapports CycloneDX à la recherche de licences. Pour plus d'informations, consultez le [guide de démarrage rapide](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database) hors ligne.

## Utiliser un rapport CycloneDX comme source d'informations de licence {#use-cyclonedx-report-as-a-source-of-license-information}

{{< history >}}

- Introduit dans GitLab 17.5 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `license_scanning_with_sbom_licenses`. Désactivées par défaut.
- Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated dans GitLab 17.6.
- Disponible généralement dans GitLab 17.8. Suppression du feature flag `license_scanning_with_sbom_licenses`.
- Prise en charge des expressions de licence SPDX [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225) dans GitLab 19.3.

{{< /history >}}

L'analyse de licences utilise le champ [licenses](https://cyclonedx.org/use-cases/#license-compliance) du SBOM JSON CycloneDX lorsqu'il est disponible. Si les informations de licence ne sont pas disponibles, les informations de licence importées depuis la base de données de licences externe sont utilisées. Les informations de licence peuvent être fournies à l'aide d'un identifiant SPDX valide, d'un nom de licence ou d'une expression de licence SPDX. De plus amples informations sur le format du champ de licence sont disponibles dans la spécification [CycloneDX](https://cyclonedx.org/use-cases/#license-compliance).

Les générateurs de SBOMs CycloneDX compatibles qui fournissent le champ de licences sont disponibles dans le [CycloneDX Tool Center](https://cyclonedx.org/tool-center/).

### Configurer la source d'informations des licences {#configure-license-information-source}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/501662) dans GitLab 18.3.

{{< /history >}}

Choisissez la source d'informations de licence à utiliser lorsque les deux sont disponibles.

Pour configurer la source d'informations de licence préférée pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Source d'informations des licences**, sélectionnez l'une des options suivantes :
   - **SBOM** (par défaut) - Utilise les informations de licence provenant des rapports CycloneDX.
     - Le scanner lit les informations de licence à partir des rapports situés dans le projet à l'emplacement `/gl-sbom-*.cdx.json`.
     - Pour écraser une licence, mettez à jour les données de licence directement dans ce fichier.
   - **PMDB** \- Utilise les informations de licence provenant de la base de données de licences externe.

### Activer ou désactiver l'analyse de licences pour les fichiers CycloneDX {#enable-or-disable-license-scanning-for-cyclonedx-files}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/500716) dans GitLab 19.0 [avec le feature flag](../../../administration/feature_flags/_index.md) `license_scanning_for_cyclonedx_setting`. Désactivées par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241413) dans GitLab 19.2. Suppression du feature flag `license_scanning_for_cyclonedx_setting`.

{{< /history >}}

L'analyse de licences s'exécute par défaut sur tous les fichiers SBOM CycloneDX ingérés. Vous pouvez désactiver l'analyse de licences par projet depuis la page de configuration de la sécurité. Lorsqu'elle est désactivée, les licences issues de l'ingestion SBOM apparaissent comme `unknown` dans la liste des dépendances.

Prérequis :

- Vous devez disposer du rôle Maintainer, Owner ou Responsable sécurité pour le projet.

Pour activer ou désactiver l'analyse de licences pour les fichiers CycloneDX :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Analyse de licences pour CycloneDX**, activez ou désactivez le bouton bascule.

## Dépannage {#troubleshooting}

### Un fichier CycloneDX n'est pas analysé et ne semble fournir aucun résultat {#a-cyclonedx-file-is-not-being-scanned-and-appears-to-provide-no-results}

Assurez-vous que le fichier CycloneDX est conforme à la [spécification JSON CycloneDX](https://cyclonedx.org/docs/1.7/json/). Cette spécification [n'autorise pas les entrées en double](https://cyclonedx.org/docs/1.7/json/#components). Les projets contenant plusieurs fichiers SBOM doivent soit déclarer chaque fichier SBOM comme artefact de rapport CI individuel, soit s'assurer que les doublons sont supprimés si les SBOMs sont fusionnés dans le cadre du pipeline CI.

Vous pouvez valider les fichiers SBOM CycloneDX par rapport à la `CycloneDX JSON specification` comme suit :

```shell
$ docker run -it --rm -v "$PWD:/my-cyclonedx-sboms" -w /my-cyclonedx-sboms cyclonedx/cyclonedx-cli:latest cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json

Validating JSON BOM...
BOM validated successfully.
```

Si le BOM JSON échoue à la validation, par exemple parce qu'il y a des composants en double :

```shell
Validation failed: Found duplicates at the following index pairs: "(A, B), (C, D)"
#/properties/components/uniqueItems
```

Ce problème peut être résolu en mettant à jour le template CI pour utiliser [jq](https://jqlang.github.io/jq/) afin de supprimer les composants en double du rapport `gl-sbom-*.cdx.json` en remplaçant la définition du job qui produit les composants en double. Par exemple, ce qui suit supprime les composants en double du fichier de rapport `gl-sbom-gem-bundler.cdx.json` produit par le job `gemnasium-dependency_scanning` :

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  after_script:
    - apk update && apk add jq
    - jq '.components |= unique' gl-sbom-gem-bundler.cdx.json > tmp.json && mv tmp.json gl-sbom-gem-bundler.cdx.json
```

### Supprimer les données de licence inutilisées {#remove-unused-license-data}

Les modifications apportées à l'analyse de licences (publiées dans GitLab 15.9) nécessitaient qu'une quantité significative d'espace disque supplémentaire soit disponible sur les instances. Ce problème a été résolu dans GitLab 16.3 par l'epic [Reduce package metadata table on-disk footprint](https://gitlab.com/groups/gitlab-org/-/epics/10415). Mais si votre instance exécutait l'analyse de licences entre GitLab 15.9 et 16.3, vous souhaitez peut-être supprimer les données inutiles.

Pour supprimer les données inutiles :

1. Vérifiez si le feature flag [`package_metadata_synchronization`](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#new-license-compliance-scanner) est actuellement ou était précédemment activé, et si c'est le cas, désactivez-le. Utilisez la [console Rails](../../../administration/operations/rails_console.md) pour exécuter les commandes suivantes.

   ```ruby
   Feature.enabled?(:package_metadata_synchronization) && Feature.disable(:package_metadata_synchronization)
   ```

1. Vérifiez s'il existe des données obsolètes dans la base de données :

   ```ruby
   PackageMetadata::PackageVersionLicense.count
   PackageMetadata::PackageVersion.count
   ```

1. S'il existe des données obsolètes dans la base de données, supprimez-les en exécutant les commandes suivantes dans l'ordre :

   ```ruby
   ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
   PackageMetadata::PackageVersionLicense.delete_all
   PackageMetadata::PackageVersion.delete_all
   ```

### L'analyse des vulnérabilités ne produit aucun résultat pour un SBOM CycloneDX {#vulnerability-scanning-produces-no-results-for-a-cyclonedx-sbom}

Si votre fichier CycloneDX est analysé pour les licences mais que l'analyse des vulnérabilités ne produit aucun résultat, consultez [L'analyse des vulnérabilités ne produit aucun résultat pour les SBOM CycloneDX personnalisés ou fusionnés](../../application_security/dependency_scanning/legacy_dependency_scanning/troubleshooting_dependency_scanning.md#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms).

### Les licences des dépendances sont inconnues {#dependency-licenses-are-unknown}

Les informations de licence open source sont stockées dans la base de données et utilisées pour résoudre les licences des dépendances d'un projet. La licence d'une dépendance peut apparaître comme `unknown` si les informations de licence n'existent pas ou si ces données ne sont pas encore disponibles dans la base de données.

Les recherches de licences pour une dépendance sont effectuées à la fin du pipeline, donc si ces données n'étaient pas disponibles à ce moment-là, une licence `unknown` est enregistrée. Cette licence est affichée jusqu'à ce qu'un pipeline ultérieur soit exécuté, moment auquel une autre recherche de licence est effectuée. Si une recherche confirme que la licence de la dépendance a changé, la nouvelle licence est affichée à ce moment-là.
