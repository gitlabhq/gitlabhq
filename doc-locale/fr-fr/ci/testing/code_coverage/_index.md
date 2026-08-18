---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Suivez les pourcentages de couverture et visualisez la couverture de test ligne par ligne dans les merge requests.
title: Couverture du code
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour suivre la couverture du code dans les merge requests, vous pouvez afficher un pourcentage dans le widget MR, annoter des lignes individuelles dans le diff MR, ou les deux. Chaque sortie nécessite un mot-clé distinct. La configuration de l'un n'active pas l'autre.

| Sortie                                                                           | Mot-clé |
| -------------------------------------------------------------------------------- | ------- |
| Afficher un pourcentage de couverture dans le widget MR, la liste des pipelines et les graphiques d'analyse | [`coverage`](../../yaml/_index.md#coverage) |
| Afficher les annotations ligne par ligne dans le diff MR                                     | [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) |

Pour obtenir les deux sorties, configurez les deux mots-clés.

## Rapports de couverture {#coverage-reporting}

Les rapports de couverture extraient un pourcentage de la sortie du job log de votre outil de test. Vous définissez une expression régulière dans le mot-clé `coverage`. GitLab analyse le job log, extrait le premier nombre correspondant et le stocke.

GitLab affiche cette valeur dans :

- Le widget MR, incluant le delta par rapport à la branche cible.
- La liste des jobs du pipeline.
- Les graphiques d'historique de couverture par projet et par groupe dans **Analyse** > **Données d'analyse du dépôt**.
- Les badges de couverture.
- La règle d'approbation `Coverage-Check` (GitLab Premium et GitLab Ultimate), qui peut exiger une approbation lorsque la couverture diminue.

Pour les instructions de configuration, consultez [configurer les rapports de couverture](coverage_reporting.md).

## Visualisation de la couverture {#coverage-visualization}

La visualisation de la couverture analyse un rapport XML Cobertura ou JaCoCo que votre job de test charge en tant qu'artefact CI/CD. Une fois le pipeline terminé, GitLab traite le rapport en arrière-plan et annote les lignes dans le diff MR.

Les annotations apparaissent uniquement sur les fichiers modifiés dans le diff MR. Les fichiers non modifiés dans le merge request ne sont pas annotés, même si le rapport inclut des données de couverture pour ceux-ci.

Pour les instructions de configuration, consultez [configurer la visualisation de la couverture](coverage_visualization.md).
