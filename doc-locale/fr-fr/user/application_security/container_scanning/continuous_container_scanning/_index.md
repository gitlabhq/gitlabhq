---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse continue des conteneurs
description: "Comment GitLab détecte les nouvelles vulnérabilités pour les dépendances d'images en dehors des pipelines CI/CD."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'analyse continue des conteneurs a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/435435) dans GitLab 16.8 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `container_scanning_continuous_vulnerability_scans`. Désactivées par défaut.
- L'analyse continue des conteneurs a été [activée sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/437162) dans GitLab 16.10.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/443712) dans GitLab 17.0. Feature flag `container_scanning_continuous_vulnerability_scans` supprimé.

{{< /history >}}

L'analyse continue des vulnérabilités (CVS) pour l'analyse des conteneurs recherche les vulnérabilités de sécurité dans les dépendances d'images de votre projet en comparant les noms et les versions de leurs composants avec les informations contenues dans les derniers [avis de sécurité](#security-advisories), sans nécessiter l'exécution d'un nouveau pipeline. CVS s'appuie sur un rapport SBOM CycloneDX stocké sur la branche par défaut pour connaître les composants utilisés par votre projet. Pour générer ce SBOM, un job d'analyse des conteneurs doit s'exécuter au moins une fois sur la branche par défaut. À partir de ce moment, CVS détecte automatiquement les avis nouvellement publiés concernant ces composants, sans nécessiter d'autres exécutions de pipeline. Lorsque le contenu de votre image change, un nouveau pipeline doit s'exécuter sur la branche par défaut pour actualiser le SBOM afin que CVS puisse évaluer l'ensemble des composants mis à jour. Dans la plupart des projets, cela se produit dans le cadre du workflow habituel, car la modification des dépendances implique généralement une modification du code qui déclenche déjà un pipeline.

[De nouvelles vulnérabilités peuvent apparaître](#checking-new-vulnerabilities) lorsque l'analyse continue des vulnérabilités déclenche des analyses sur tous les projets contenant des composants avec des [types de paquets pris en charge](#supported-package-types).

Les vulnérabilités créées par l'analyse continue des vulnérabilités pour l'analyse des conteneurs utilisent `GitLab SBoM Vulnerability Scanner` comme nom du scanner et `Container Scanning` comme type de vulnérabilité.

Contrairement aux analyses de sécurité basées sur CI/CD, l'analyse continue des vulnérabilités est exécutée via des jobs en arrière-plan (Sidekiq) plutôt que via des pipelines CI/CD, et aucun artefact de rapport de sécurité n'est généré.

## Prérequis {#prerequisites}

- [Un rapport SBOM CycloneDX](#how-to-generate-a-cyclonedx-sbom-report)
- [Avis de sécurité](#security-advisories) synchronisés avec l'instance GitLab

## Types de paquets pris en charge {#supported-package-types}

L'analyse continue des vulnérabilités prend en charge les composants avec les [types PURL](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst) suivants :

- `apk`
- `deb`
- `rpm`

Limitations connues :

- Les versions APK contenant des zéros non significatifs ne sont pas prises en charge. La prise en charge de ces versions est suivie dans le ticket [471509](https://gitlab.com/gitlab-org/gitlab/-/issues/471509).
- Les versions RPM contenant `^` ne sont pas prises en charge. La prise en charge de ces versions est suivie dans le ticket [459969](https://gitlab.com/gitlab-org/gitlab/-/issues/459969).
- Les paquets RPM dans les distributions Red Hat ne sont pas pris en charge. La prise en charge de ce cas d'utilisation est suivie dans l'epic [12980](https://gitlab.com/groups/gitlab-org/-/epics/12980).

## Comment générer un rapport SBOM CycloneDX {#how-to-generate-a-cyclonedx-sbom-report}

Utilisez un [rapport SBOM CycloneDX](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) pour enregistrer les composants de votre projet auprès de GitLab.

Les rapports CycloneDX doivent être conformes aux éléments suivants :

- [La spécification CycloneDX](https://github.com/CycloneDX/specification) version `1.4`, `1.5` ou `1.6`
- [La taxonomie des propriétés CycloneDX de GitLab pour l'analyse des conteneurs](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabcontainer_scanning-namespace-taxonomy)

GitLab propose des analyseurs de sécurité permettant de générer un rapport compatible avec GitLab :

- [Analyse des conteneurs](../_index.md#getting-started)
- [Analyse des conteneurs pour le registre](../_index.md#container-scanning-for-registry)

## Activer ou désactiver l'analyse continue des vulnérabilités {#turn-on-or-off-continuous-vulnerability-scanning}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/500716) dans GitLab 19.0 [avec le feature flag](../../../../administration/feature_flags/_index.md) `cvs_per_scanner_type_settings`. Désactivées par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243130) dans GitLab 19.2. Feature flag `cvs_per_scanner_type_settings` supprimé.

{{< /history >}}

L'analyse continue des vulnérabilités s'exécute par défaut sur tous les fichiers SBOM CycloneDX ingérés. Vous pouvez la désactiver pour chaque projet. Lorsqu'elle est désactivée, aucun enregistrement de vulnérabilité n'est créé pour les dépendances d'images lors de l'ingestion de nouveaux avis de sécurité.

Prérequis :

- Vous devez disposer du rôle Maintainer, Owner ou Responsable sécurité pour le projet.

Pour activer ou désactiver l'analyse continue des vulnérabilités :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Sous **Analyse continue des vulnérabilités dans les conteneurs**, activez ou désactivez le bouton bascule.

## Vérification des nouvelles vulnérabilités {#checking-new-vulnerabilities}

Les nouvelles vulnérabilités détectées par l'analyse continue des vulnérabilités sont visibles dans le [rapport sur les vulnérabilités](../../vulnerability_report/_index.md). Cependant, elles ne sont pas répertoriées dans le pipeline où le composant SBOM concerné a été détecté.

Les vulnérabilités sont créées après l'ajout ou la mise à jour d'un [avis de sécurité](#security-advisories). Il peut s'écouler quelques heures avant que les vulnérabilités correspondantes soient ajoutées à vos projets, à condition que la base de code reste inchangée. Seuls les avis publiés au cours des 14 derniers jours sont pris en compte pour l'analyse continue des vulnérabilités.

## Lorsque les vulnérabilités ne sont plus détectées {#when-vulnerabilities-are-no-longer-detected}

L'analyse continue des vulnérabilités crée automatiquement des vulnérabilités lorsqu'un nouvel avis est publié, mais elle n'est pas en mesure de déterminer quand une vulnérabilité n'est plus présente dans le projet. Pour ce faire, GitLab requiert toujours l'exécution d'une analyse par [analyse des conteneurs](../_index.md) dans un pipeline pour la branche par défaut, ainsi que la génération d'un artefact de rapport de sécurité correspondant avec les informations à jour. Lorsque ces rapports sont traités et qu'ils ne contiennent plus certaines vulnérabilités, celles-ci sont signalées comme telles, même si elles ont été créées par l'analyse continue des vulnérabilités.

> [!warning]
> Les vulnérabilités détectées par l'analyse des conteneurs pour le registre ne peuvent pas être résolues à l'aide de cette méthode et restent visibles même après leur correction dans vos images. Cela est dû au fait que l'analyse des conteneurs pour le registre ne génère que des SBOM, et non les rapports de sécurité requis pour marquer les vulnérabilités comme résolues.

## Avis de sécurité {#security-advisories}

L'analyse continue des vulnérabilités utilise la base de données de métadonnées de paquets (Package Metadata Database), un service géré par GitLab qui agrège les données de licences et d'avis de sécurité, et publie régulièrement des mises à jour utilisées par les instances GitLab.com et GitLab Self-Managed.

Sur GitLab.com, la synchronisation est gérée par GitLab et est disponible pour tous les projets.

Sur GitLab Self-Managed, vous pouvez [choisir les métadonnées du registre de paquets à synchroniser](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) dans la zone **Admin** de l'instance GitLab.

### Sources de données {#data-sources}

Les sources de données actuelles pour les avis de sécurité incluent :

- [Trivy DB](https://github.com/aquasecurity/trivy-db), créé à partir du [`vuln-list repository`](https://github.com/aquasecurity/vuln-list) d'Aqua Security

### Contribuer à la base de données des vulnérabilités {#contributing-to-the-vulnerability-database}

Pour trouver une vulnérabilité, vous pouvez effectuer une recherche dans le [`vuln-list repository`](https://github.com/aquasecurity/vuln-list) d'Aqua Security contenant les données brutes. Vous pouvez également [contribuer](https://github.com/aquasecurity/vuln-list-update/blob/main/CONTRIBUTING.md) à Trivy-DB.
