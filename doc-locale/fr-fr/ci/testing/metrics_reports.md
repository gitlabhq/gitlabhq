---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Suivre et comparer les performances, la mémoire et les métriques personnalisées."
title: Rapports métriques
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les rapports métriques affichent des métriques personnalisées dans les merge requests pour suivre les performances, l'utilisation de la mémoire et d'autres mesures entre les branches.

Utilisez les rapports métriques pour :

- Surveiller les modifications de l'utilisation de la mémoire.
- Suivre les résultats des tests de charge.
- Mesurer la complexité du code.
- Comparer les statistiques de couverture du code.

## Workflow de traitement des métriques {#metrics-processing-workflow}

Lorsqu'un pipeline s'exécute, GitLab lit les métriques à partir de l'artefact de rapport et les stocke sous forme de valeurs de chaîne pour la comparaison. Le nom de fichier par défaut est `metrics.txt`.

Pour une merge request, GitLab compare les métriques de la branche de fonctionnalité aux valeurs de la branche cible et les affiche dans le widget de merge request dans cet ordre :

- Métriques existantes avec des valeurs modifiées.
- Métriques ajoutées par la merge request (marquées avec un badge **Nouvelle**).
- Métriques supprimées par la merge request (marquées avec un badge **Supprimée**).
- Métriques existantes avec des valeurs inchangées.

### Sélection du pipeline de référence {#baseline-pipeline-selection}

Pour comparer les métriques entre les branches, GitLab identifie un pipeline de référence sur la branche cible en utilisant ce processus :

1. Recherche un pipeline sur la branche cible correspondant à ces SHA de commit, dans l'ordre :
   1. L'extrémité de la branche cible au moment où le [pipeline de merge request](../pipelines/merge_request_pipelines.md) a été créé. Ce SHA est uniquement disponible pour les pipelines de merge request.
   1. Le commit de base de fusion (l'ancêtre commun des branches source et cible).
   1. Le commit de départ du diff de la merge request.
1. Sélectionne le pipeline créé le plus récemment (par ID de pipeline) pour le premier SHA ayant un pipeline correspondant.

La sélection du pipeline de référence :

- Ne filtre pas par statut de pipeline. Un pipeline dans n'importe quel état (`success`, `failed`, `canceled`, ou `skipped`) peut être sélectionné comme référence.
- Ne vérifie pas si le pipeline de référence possède des artefacts de rapport de métriques. Si le pipeline de référence existe mais ne possède pas d'artefacts de métriques, toutes les métriques de la branche de fonctionnalité sont affichées comme nouvelles.

Le widget de comparaison des métriques s'affiche uniquement lorsque le pipeline de la branche de fonctionnalité est dans un état terminé et possède des artefacts de rapport de métriques.

Le type de pipeline détermine quel SHA de commit est mis en correspondance en premier :

- Pipelines de merge request : Le SHA de l'extrémité de la branche cible est généralement disponible ; la référence est donc généralement le dernier pipeline à l'extrémité de la branche cible au moment où le pipeline de merge request a été créé.
- Pipelines de branche : Le SHA de l'extrémité de la branche cible n'est pas disponible ; le commit de base de fusion est donc utilisé à la place. La référence est le dernier pipeline sur la branche cible au commit ancêtre commun.

Pour s'assurer qu'une référence est toujours disponible pour la comparaison :

- Exécutez des pipelines sur votre branche cible qui produisent des artefacts de rapport de métriques.
- Si vous utilisez des pipelines de branche, assurez-vous que le commit de base de fusion possède un pipeline sur la branche cible.

## Configurer les rapports métriques {#configure-metrics-reports}

Ajoutez des rapports métriques à votre pipeline CI/CD pour suivre les métriques personnalisées dans les merge requests.

Prérequis :

- Le fichier de métriques doit utiliser le format texte [OpenMetrics](https://prometheus.io/docs/instrumenting/exposition_formats/#openmetrics-text-format).

Pour configurer les rapports métriques :

1. Dans votre fichier `.gitlab-ci.yml`, ajoutez un job qui génère un rapport de métriques.
1. Ajoutez un script au job qui génère des métriques au format OpenMetrics.
1. Configurez le job pour téléverser le fichier de métriques avec [`artifacts:reports:metrics`](../yaml/artifacts_reports.md#artifactsreportsmetrics).

Par exemple :

```yaml
metrics:
  stage: test
  script:
    - echo 'memory_usage_bytes 2621440' > metrics.txt
    - echo 'response_time_seconds 0.234' >> metrics.txt
    - echo 'test_coverage_percent 87.5' >> metrics.txt
    - echo '# EOF' >> metrics.txt
  artifacts:
    reports:
      metrics: metrics.txt
```

Une fois le pipeline exécuté, les rapports métriques s'affichent dans le widget de merge request.

![Widget de rapport de métriques dans une merge request affichant les noms et les valeurs des métriques.](img/metrics_report_v18_3.png)

Pour des spécifications de format supplémentaires et des exemples, consultez [Prometheus text format details](https://prometheus.io/docs/instrumenting/exposition_formats/#text-format-details).

## Dépannage {#troubleshooting}

Lorsque vous utilisez des rapports métriques, vous pouvez rencontrer les problèmes suivants.

### Les rapports métriques n'ont pas changé {#metrics-reports-did-not-change}

Il est possible que le message **L'analyse des rapports métriques n'a détecté aucun nouveau changement** s'affiche lors de la consultation des rapports métriques dans les merge requests.

Ce problème se produit dans les cas suivants :

- La branche cible ne possède pas de rapport de métriques de référence pour la comparaison.
- Votre abonnement GitLab n'inclut pas les rapports métriques (GitLab Premium ou GitLab Ultimate requis).

Pour résoudre ce problème :

1. Vérifiez que votre édition d'abonnement GitLab inclut les rapports métriques.
1. Assurez-vous que la branche cible possède un pipeline avec des rapports métriques configurés. Pour vous assurer qu'un tel pipeline est disponible, exécutez des pipelines sur la branche cible qui produisent des artefacts de rapport de métriques.
1. Vérifiez que votre fichier de métriques utilise un format OpenMetrics valide.
