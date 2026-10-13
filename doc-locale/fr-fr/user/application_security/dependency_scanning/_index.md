---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse des dépendances
description: "Vulnérabilités, remédiation, configuration, analyseurs et rapports."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'analyse des dépendances identifie les vulnérabilités de sécurité connues dans les dépendances de votre projet, notamment les packages d'exécution, de développement et transitifs (imbriqués). GitLab propose plusieurs méthodes d'analyse des dépendances, chacune adaptée à un workflow différent. Utilisez le récapitulatif ci-dessous pour choisir la méthode adaptée à votre projet.

## Méthodes d'analyse disponibles {#available-scanning-methods}

### Analyse des dépendances à l'aide de SBOM {#dependency-scanning-using-sbom}

Analyse les artefacts SBOM CycloneDX produits dans votre pipeline par l'analyseur d'analyse des dépendances par rapport à la base de données d'avis de GitLab. Il s'agit de la méthode recommandée pour les nouveaux projets et de l'orientation à long terme pour l'analyse des dépendances dans GitLab.

Pour plus de détails, consultez [Analyse des dépendances à l'aide de SBOM](dependency_scanning_sbom/_index.md).

### Analyse continue des dépendances {#continuous-dependency-scanning}

Réanalyse en continu les composants SBOM depuis le dernier pipeline réussi de votre branche par défaut à chaque mise à jour de la base de données d'avis de GitLab, afin que les vulnérabilités nouvellement divulguées apparaissent sans avoir à relancer un pipeline.

Pour plus de détails, consultez [Analyse continue des dépendances](continuous_dependency_scanning/_index.md).

### Analyse des dépendances avec Gemnasium {#dependency-scanning-with-gemnasium}

L'analyseur d'origine basé sur les pipelines, qui détecte les dépendances et les compare à la base de données d'avis de GitLab dans un job CI/CD.

> [!warning]
> L'analyse des dépendances basée sur l'analyseur Gemnasium est dépréciée dans GitLab 17.9 et proposée pour suppression dans GitLab 20.0. Pour obtenir des conseils sur la migration, consultez le [guide de migration](migration_guide_to_sbom_based_scans.md). Pour plus d'informations, consultez l'[epic 15961](https://gitlab.com/groups/gitlab-org/-/epics/20456).

Pour plus de détails, consultez la [page d'analyse des dépendances héritée](legacy_dependency_scanning/_index.md).

### Analyser les dépendances pour détecter des comportements (Libbehave) {#analyze-dependencies-for-behaviors-libbehave}

Une version expérimentale qui analyse le comportement d'exécution de vos dépendances pour détecter les activités suspectes ou malveillantes au-delà des CVE connus.

Pour plus de détails, consultez [Analyser les dépendances pour détecter des comportements](experiment_libbehave_dependency.md).

## Comparaison des méthodes d'analyse {#comparison-of-scanning-methods}

| Méthode                             | Statut               | Déclencheur            | Idéal pour                                                   |
| ---------------------------------- | -------------------- | ------------------ | ---------------------------------------------------------- |
| Analyse des dépendances à l'aide de SBOM     | Disponibilité générale | Pipeline           | Nouveaux projets, workflows SBOM-first                         |
| Analyse continue des dépendances     | Disponibilité générale | Mise à jour de la base de données d'avis | Détection des CVE nouvellement divulguées sans relancer les pipelines |
| Analyse des dépendances avec Gemnasium | Dépréciée (17.9)    | Pipeline           | Projets existants en attente de migration                        |
| Analyser les dépendances pour détecter des comportements | version expérimentale           | Pipeline           | Détection des comportements malveillants de packages                       |

## Fonctionnalités natives IA {#ai-native-features}

### Résolution agentique des changements majeurs {#agentic-breaking-change-resolution}

Lorsqu'une merge request qui incrémente une dépendance a un pipeline en échec, GitLab Duo peut analyser l'échec et proposer des correctifs pour le résoudre.

Pour plus d'informations, consultez [la résolution agentique des changements majeurs (pour les incréments de dépendances)](agentic-breaking-change-resolution.md).

## Contribuer à la base de données de vulnérabilités {#contributing-to-the-vulnerability-database}

Pour trouver une vulnérabilité, vous pouvez rechercher dans la [`GitLab advisory database`](https://advisories.gitlab.com/). Vous pouvez également [soumettre de nouvelles vulnérabilités](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
