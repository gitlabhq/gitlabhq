---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Afficher les annotations de couverture de test ligne par ligne dans les diffs de merge request à l'aide des rapports XML JaCoCo."
title: Visualisation de la couverture JaCoCo
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/227345) dans GitLab 17.3 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `jacoco_coverage_reports`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170513) dans GitLab 17.6. L'indicateur de fonctionnalité `jacoco_coverage_reports` a été supprimé.

{{< /history >}}

Utilisez les rapports de couverture JaCoCo pour afficher les annotations de couverture ligne par ligne dans les diffs de merge request. GitLab lit le rapport XML JaCoCo et annote chaque ligne modifiée comme couverte (vert) ou non couverte (rouge).

La visualisation de la couverture utilise le mot-clé [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report). Elle n'affiche pas de pourcentage de couverture dans le widget de merge request et ne renseigne pas les graphiques d'historique de couverture. Pour afficher un pourcentage de couverture, configurez le mot-clé [`coverage`](../../yaml/_index.md#coverage) séparément.

> [!note]
> Les rapports agrégés provenant de projets multi-modules ne sont pas pris en charge. Pour contribuer à la prise en charge des rapports agrégés, consultez le [ticket 491015](https://gitlab.com/gitlab-org/gitlab/-/issues/491015).

## Ajouter un job de couverture JaCoCo {#add-a-jacoco-coverage-job}

Ajoutez un job de couverture JaCoCo lorsque vous souhaitez afficher les annotations de couverture ligne par ligne dans les diffs de merge request.

Prérequis :

- Un [fichier XML JaCoCo](https://www.jacoco.org/jacoco/trunk/coverage/jacoco.xml) correctement formaté qui fournit la [couverture de ligne](https://www.eclemma.org/jacoco/trunk/doc/counters.html).

Pour ajouter un job de couverture JaCoCo :

1. Ajoutez un job à votre fichier `.gitlab-ci.yml` avec `artifacts:reports:coverage_report` défini sur `jacoco`. Par exemple :

   ```yaml
   test-jdk11:
     stage: test
     image: maven:3.6.3-jdk-11
     script:
       - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
     artifacts:
       reports:
         coverage_report:
           coverage_format: jacoco
           path: target/site/jacoco/jacoco.xml
   ```

1. Définissez `path` sur l'emplacement du rapport XML JaCoCo généré.

Si le job génère plusieurs rapports, utilisez un [caractère générique dans le chemin de l'artefact](../../jobs/job_artifacts.md#with-wildcards).

## Indicateurs de couverture {#coverage-indicators}

La visualisation JaCoCo utilise les [instructions (couverture C0)](https://www.eclemma.org/jacoco/trunk/doc/counters.html), représentées par `ci` (instructions couvertes) dans les rapports.

Une fois le pipeline terminé, la couverture s'affiche dans la vue des diffs de merge request avec ces indicateurs :

- Instructions couvertes (vert) : lignes comportant au moins une instruction couverte (`ci > 0`)
- Aucune instruction couverte (rouge) : lignes sans aucune instruction couverte (`ci = 0`)
- Aucune information de couverture : lignes non incluses dans le rapport de couverture

Par exemple, avec cette sortie de rapport :

```xml
<line nr="83" mi="2" ci="0" mb="0" cb="0"/>
<line nr="84" mi="2" ci="0" mb="0" cb="0"/>
<line nr="85" mi="2" ci="0" mb="0" cb="0"/>
<line nr="86" mi="2" ci="0" mb="0" cb="0"/>
<line nr="88" mi="0" ci="7" mb="0" cb="1"/>
```

La vue des diffs de merge request affiche la couverture comme suit :

![Vue des diffs de merge request affichant les indicateurs de couverture avec des barres rouges pour les lignes non couvertes et des barres vertes pour les lignes couvertes.](img/jacoco_coverage_example_v18_3.png)

Dans cet exemple, les lignes 83 à 86 affichent des barres rouges pour le code non couvert, la ligne 88 affiche une barre verte pour le code couvert, et les lignes 87, 89 à 90 ne disposent d'aucune donnée de couverture.

## Dépannage {#troubleshooting}

Pour résoudre les problèmes liés à la visualisation de la couverture, notamment les échecs de résolution de chemin et les annotations qui ne s'affichent pas comme prévu, consultez le [dépannage de la visualisation de la couverture](coverage_visualization.md#troubleshooting).

## Donner un retour {#give-feedback}

La visualisation de la couverture JaCoCo est activement améliorée. Pour signaler des problèmes ou suggérer des améliorations, laissez votre retour dans le [ticket 479804](https://gitlab.com/gitlab-org/gitlab/-/issues/479804).
