---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Affichez les annotations de couverture de test ligne par ligne dans les diffs de merge request à l'aide des rapports Cobertura ou JaCoCo."
title: Visualisation de la couverture
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le mot-clé [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) pour afficher les annotations de couverture ligne par ligne dans les diffs de merge request.

Ce mot-clé affiche uniquement les annotations de diff. Il n'affiche pas de pourcentage de couverture dans le widget MR et ne renseigne pas les graphiques d'historique de couverture. Pour afficher un pourcentage de couverture, configurez séparément le mot-clé [`coverage`](../../yaml/_index.md#coverage).

Une fois le pipeline terminé, GitLab traite le rapport en arrière-plan et annote les lignes dans le diff de merge request :

- Vert : la ligne est couverte par des tests.
- Rouge : la ligne n'est pas couverte par des tests.
- Orange (Cobertura uniquement) : la ligne est chargée mais jamais exécutée.

Les annotations apparaissent uniquement sur les fichiers modifiés dans le diff du merge request. Les fichiers non modifiés dans le merge request ne sont pas annotés, même si le rapport inclut des données de couverture pour ceux-ci.

## Configurer la visualisation de la couverture {#configure-coverage-visualization}

Pour configurer la visualisation de la couverture, ajoutez `artifacts:reports:coverage_report` à votre job :

```yaml
test:
  script:
    - run tests with coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura  # or jacoco
        path: coverage/coverage.xml
```

Pour des exemples spécifiques à chaque langage, consultez :

- [Cobertura](cobertura.md)
- [JaCoCo](jacoco.md)

Pour collecter plusieurs rapports, utilisez un [caractère générique dans le chemin de l'artefact](../../jobs/job_artifacts.md#with-wildcards). GitLab fusionne les résultats en un rapport unique.

Les rapports de couverture des pipelines enfants apparaissent dans les annotations de diff du merge request.

## Limites {#limits}

| Limite                                            | Valeur |
| ------------------------------------------------ | ----- |
| Taille maximale du fichier XML Cobertura                  | 10 Mio |
| Nombre maximum de nœuds `<source>` dans un fichier XML Cobertura | 100   |

Si votre rapport Cobertura dépasse 100 nœuds `<source>`, des annotations peuvent être manquantes ou mal alignées dans la vue diff. Pour les projets de grande taille, divisez le rapport en fichiers plus petits. Consultez le [ticket 328772](https://gitlab.com/gitlab-org/gitlab/-/issues/328772) pour plus de détails.

La visualisation n'apparaît qu'une fois le pipeline terminé. Si le pipeline comporte un [job manuel bloquant](../../jobs/job_control.md#types-of-manual-jobs), la visualisation n'est pas disponible tant que ce job n'a pas été exécuté.

Pour télécharger le rapport de couverture depuis la page de détails du job, ajoutez-le à l'artefact `paths` ainsi qu'à `reports` :

```yaml
artifacts:
  paths:
    - coverage/cobertura-coverage.xml
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

## Résolution des chemins {#path-resolution}

Les rapports de couverture utilisent des chemins de fichiers relatifs. GitLab les résout en chemins de dépôt absolus en les comparant aux fichiers modifiés dans le merge request.

Pour JaCoCo, le processus de correspondance est le suivant :

1. Trouver toutes les merge requests pour la même référence de pipeline.
1. Pour tous les fichiers modifiés, collecter les chemins absolus.
1. Pour chaque chemin relatif dans le rapport, utiliser le premier chemin absolu correspondant.

Pour Cobertura, GitLab utilise également l'élément `<sources>` pour reconstruire les chemins :

1. Extraire les segments de chemin de chaque entrée `<source>`.
1. Combiner chaque segment avec l'attribut `filename` de chaque élément `<class>`.
1. Vérifier si le chemin candidat existe dans le dépôt.
1. Utiliser la première correspondance comme chemin absolu.

Cette correction automatique fonctionne uniquement lorsque les chemins `<source>` suivent le format `<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...`.

### Exemple de résolution de chemin {#path-resolution-example}

Pour un projet C# avec le chemin complet `test-org/test-cs-project` et ces fichiers relatifs à la racine du projet :

```plaintext
Auth/User.cs
Lib/Utils/User.cs
```

Avec ces `sources` dans le XML Cobertura :

```xml
<sources>
  <source>/builds/test-org/test-cs-project/Auth</source>
  <source>/builds/test-org/test-cs-project/Lib/Utils</source>
</sources>
```

L'analyseur extrait `Auth` et `Lib/Utils` des `sources`, puis combine chacun avec l'attribut `filename` de chaque élément `<class>`. Pour une classe avec `filename="User.cs"`, le premier candidat correspondant à un fichier dans le dépôt est `Auth/User.cs`.

Pour chaque élément `<class>`, l'analyseur effectue jusqu'à 100 itérations. Si aucune correspondance n'est trouvée, la classe n'est pas incluse dans le rapport de couverture final.

## Dépannage {#troubleshooting}

Lorsque vous utilisez la visualisation de la couverture, vous pouvez rencontrer les problèmes suivants.

### Les annotations de diff n'apparaissent pas {#diff-annotations-do-not-appear}

Les annotations peuvent ne pas apparaître pour les raisons suivantes :

- Le pipeline n'est pas terminé. Les annotations sont générées une fois le pipeline terminé. Attendez la fin du pipeline, puis rechargez le diff du merge request.
- Le fichier ne figure pas dans le diff du merge request. Les annotations apparaissent uniquement sur les fichiers modifiés dans le merge request, même si le rapport inclut des données de couverture pour d'autres fichiers.
- Le chemin du fichier dans le rapport ne correspond pas au chemin du dépôt. Si la résolution du chemin échoue, l'annotation est ignorée silencieusement. Pour diagnostiquer le problème, téléchargez l'artefact XML de couverture et comparez l'attribut `filename` d'un élément `<class>` au chemin du fichier dans le dépôt relatif à la racine du projet.
- Le projet comporte plusieurs modules avec des chemins relatifs en double. Lorsque les chemins ne sont pas uniques d'un module à l'autre, GitLab ne peut pas déterminer à quel fichier appartient l'annotation. Assurez-vous que les chemins relatifs sont uniques d'un module à l'autre :

  ```diff
      src/main/java/org/acme/DemoExample.java
    - src/main/other-module/org/acme/DemoExample.java
    + src/main/other-module/org/acme/OtherDemoExample.java
  ```

- Le mot-clé `coverage` n'est pas configuré. `artifacts:reports:coverage_report` ne produit pas de pourcentage dans le widget MR. Pour afficher un pourcentage de couverture, configurez séparément le mot-clé `coverage`.

### Les métriques ne s'affichent pas pour tous les fichiers modifiés {#metrics-do-not-display-for-all-changed-files}

Ce problème survient lorsque vous créez une nouvelle merge request à partir de la même branche source mais avec une branche cible différente. Le pipeline utilise les diffs de la merge request précédente et n'affiche pas les annotations pour les fichiers absents de ce diff.

Pour résoudre ce problème, attendez que la nouvelle merge request soit créée, puis réexécutez le pipeline.
