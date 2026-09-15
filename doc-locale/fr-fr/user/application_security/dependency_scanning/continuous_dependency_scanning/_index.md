---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse continue des dépendances
description: "Comment GitLab détecte les nouvelles vulnérabilités pour les dépendances d'applications en dehors des pipelines CI/CD."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'analyse continue des vulnérabilités (CVS) pour l'analyse des dépendances recherche des vulnérabilités de sécurité dans les dépendances de votre projet en comparant les noms et versions de leurs composants aux informations contenues dans les derniers [avis de sécurité](#security-advisories), sans nécessiter l'exécution d'un nouveau pipeline. Un pipeline doit s'exécuter au moins une fois sur la branche par défaut pour enregistrer les composants de votre projet via un SBOM CycloneDX. Ensuite, CVS s'exécute au fur et à mesure de la publication des avis, sans autre exécution de pipeline, jusqu'à ce que vos dépendances changent.

[De nouvelles vulnérabilités peuvent apparaître](#checking-new-vulnerabilities) lorsque l'analyse continue des vulnérabilités déclenche des analyses sur tous les projets contenant des composants avec des [types de paquets pris en charge](#supported-package-types).

Les vulnérabilités créées par l'analyse continue des vulnérabilités pour l'analyse des dépendances utilisent `GitLab SBoM Vulnerability Scanner` comme nom de scanner et `Dependency Scanning` comme type de vulnérabilité.

Contrairement aux analyses de sécurité basées sur CI/CD, l'analyse continue des vulnérabilités est exécutée via des jobs en arrière-plan (Sidekiq) plutôt que via des pipelines CI/CD, et aucun artefact de rapport de sécurité n'est généré.

## Prérequis {#prerequisites}

- [Un rapport SBOM CycloneDX](#how-to-generate-a-cyclonedx-sbom-report)
- [Les avis de sécurité](#security-advisories) synchronisés avec l'instance GitLab

## Types de paquets pris en charge {#supported-package-types}

L'analyse continue des vulnérabilités prend en charge les composants avec les [types PURL](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst) suivants pour l'analyse des dépendances :

- `cargo`
- `conan`
- `go`
- `maven`
- `npm`
- `nuget`
- `packagist`
- `pub`
- `pypi`
- `rubygem`
- `swift`

Les pseudo-versions Go ne sont pas prises en charge. Une dépendance de projet qui référence une pseudo-version Go n'est jamais considérée comme affectée, car cela pourrait entraîner des faux négatifs.

## Comment générer un rapport SBOM CycloneDX {#how-to-generate-a-cyclonedx-sbom-report}

Utilisez un [rapport SBOM CycloneDX](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) pour enregistrer les composants de votre projet auprès de GitLab.

Les rapports CycloneDX doivent être conformes aux éléments suivants :

- [la spécification CycloneDX](https://github.com/CycloneDX/specification) version `1.4`, `1.5` ou `1.6`
- [la taxonomie des propriétés CycloneDX de GitLab pour l'analyse des dépendances](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabdependency_scanning-namespace-taxonomy)

GitLab propose des analyseurs de sécurité capables de générer un rapport compatible avec GitLab :

- [Analyseur d'analyse des dépendances](../dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [Analyseur Gemnasium (obsolète)](../legacy_dependency_scanning/_index.md)

## Activer ou désactiver l'analyse continue des vulnérabilités {#turn-on-or-off-continuous-vulnerability-scanning}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/500716) dans GitLab 19.0 [avec le feature flag](../../../../administration/feature_flags/_index.md) `cvs_per_scanner_type_settings`. Désactivées par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243130) dans GitLab 19.2. Suppression du feature flag `cvs_per_scanner_type_settings`.

{{< /history >}}

L'analyse continue des vulnérabilités s'exécute par défaut sur tous les fichiers SBOM CycloneDX ingérés. Vous pouvez la désactiver pour chaque projet. Lorsqu'elle est désactivée, aucun enregistrement de vulnérabilité n'est créé pour vos dépendances lors de l'ingestion de nouveaux avis de sécurité.

Prérequis :

- Vous devez avoir le rôle Maintainer, Owner ou Responsable sécurité pour le projet.

Pour activer ou désactiver l'analyse continue des vulnérabilités :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Sous **Analyse continue des vulnérabilités de dépendance**, activez ou désactivez le bouton bascule.

## Vérification des nouvelles vulnérabilités {#checking-new-vulnerabilities}

Les nouvelles vulnérabilités détectées par l'analyse continue des vulnérabilités sont visibles dans le [rapport des vulnérabilités](../../vulnerability_report/_index.md). Elles ne sont toutefois pas répertoriées dans le pipeline où le composant SBOM affecté a été détecté.

Les vulnérabilités sont créées après l'ajout ou la mise à jour d'un [avis de sécurité](#security-advisories) ; il peut s'écouler quelques heures avant que les vulnérabilités correspondantes soient ajoutées à vos projets, à condition que la base de code reste inchangée. Seuls les avis publiés au cours des 14 derniers jours sont pris en compte pour l'analyse continue des vulnérabilités.

## Lorsque des vulnérabilités ne sont plus détectées {#when-vulnerabilities-are-no-longer-detected}

L'analyse continue des vulnérabilités crée automatiquement des vulnérabilités lors de la publication d'un nouvel avis, mais elle n'est pas en mesure de déterminer quand une vulnérabilité n'est plus présente dans le projet. Pour ce faire, GitLab requiert toujours qu'une analyse d'[analyse des dépendances](../_index.md) soit exécutée dans un pipeline pour la branche par défaut, et qu'un artefact de rapport de sécurité correspondant soit généré avec les informations à jour. Lorsque ces rapports sont traités et qu'ils ne contiennent plus certaines vulnérabilités, celles-ci sont signalées comme telles, même si elles ont été créées par l'analyse continue des vulnérabilités.

## Avis de sécurité {#security-advisories}

L'analyse continue des vulnérabilités utilise la base de données de métadonnées de paquets (Package Metadata Database), un service géré par GitLab qui agrège les données relatives aux licences et aux avis de sécurité, et publie régulièrement des mises à jour utilisées par GitLab.com et les instances GitLab Self-Managed.

Sur GitLab.com, la synchronisation est gérée par GitLab et est disponible pour tous les projets.

Sur GitLab Self-Managed, vous pouvez [choisir les métadonnées du registre de paquets à synchroniser](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) dans la zone **Admin** de l'instance GitLab.

### Sources de données {#data-sources}

Les sources de données actuelles pour les avis de sécurité comprennent :

- [Base de données des avis GitLab](https://advisories.gitlab.com/) (hébergée dans le [`gemnasium-db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) dépôt, un nom historique)

### Contribuer à la base de données des vulnérabilités {#contributing-to-the-vulnerability-database}

Pour trouver une vulnérabilité, vous pouvez effectuer une recherche dans la [`GitLab advisory database`](https://advisories.gitlab.com/). Vous pouvez également [soumettre de nouvelles vulnérabilités](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
