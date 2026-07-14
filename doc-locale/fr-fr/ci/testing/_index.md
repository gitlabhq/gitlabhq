---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tester avec GitLab CI/CD
description: "Générez des rapports de tests, des analyses de qualité du code et des analyses de sécurité qui s'affichent dans les merge requests."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez GitLab CI/CD pour tester les modifications dans les branches de fonctionnalités. Vous pouvez afficher des rapports de tests et lier des informations importantes directement dans les [merge requests](../../user/project/merge_requests/_index.md).

## Rapports de tests et de qualité {#testing-and-quality-reports}

Vous pouvez générer les rapports suivants :

| Fonctionnalité                                                                                 | Description |
| --------------------------------------------------------------------------------------- | ----------- |
| [Tests d'accessibilité](accessibility_testing.md)                                       | Détectez les violations d'accessibilité pour les pages modifiées. |
| [Tests de performance du navigateur](browser_performance_testing.md)                           | Mesurez l'impact des modifications du code sur les performances du navigateur. |
| [Couverture du code](code_coverage/_index.md)                                                | Consultez les résultats de couverture des tests, la couverture ligne par ligne dans les diffs et les métriques globales. |
| [Qualité du code](code_quality.md)                                                         | Analysez la qualité du code source avec Code Climate. |
| [Afficher des artefacts de job arbitraires](../yaml/_index.md#artifactsexpose_as)                 | Créez un lien vers les artefacts de job sélectionnés à l'aide de `artifacts:expose_as`. |
| [Tests fail fast](fail_fast_testing.md)                                               | Arrêtez les pipelines prématurément en cas d'échec des tests RSpec. |
| [Analyse des licences](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | Analysez et gérez les licences des dépendances. |
| [Tests de performance de charge](load_performance_testing.md)                                 | Mesurez l'impact des modifications du code sur les performances du serveur. |
| [Rapports de métriques](metrics_reports.md)                                                   | Suivez des métriques personnalisées telles que l'utilisation de la mémoire et les performances. |
| [Rapports de tests unitaires](unit_test_reports.md)                                               | Consultez les résultats des tests et identifiez les échecs sans vérifier les job logs. |

## Rapports de sécurité {#security-reports}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Vous pouvez générer des [rapports de sécurité](../../user/application_security/_index.md) en analysant votre projet à la recherche de vulnérabilités :

| Fonctionnalité                                                                                       | Description |
| --------------------------------------------------------------------------------------------- | ----------- |
| [Analyse des conteneurs](../../user/application_security/container_scanning/_index.md)            | Analysez les images Docker à la recherche de vulnérabilités. |
| [Test dynamique de sécurité des applications (DAST)](../../user/application_security/dast/_index.md) | Analysez les applications web en cours d'exécution à la recherche de vulnérabilités. |
| [Analyse des dépendances](../../user/application_security/dependency_scanning/_index.md)          | Analysez les dépendances à la recherche de vulnérabilités. |
| [Test statique de sécurité des applications (SAST)](../../user/application_security/sast/_index.md)  | Analysez le code source à la recherche de vulnérabilités. |
