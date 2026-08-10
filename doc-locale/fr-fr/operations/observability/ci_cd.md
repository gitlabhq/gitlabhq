---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: Afficher la télémétrie des pipelines CI/CD pour Observability
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

Lorsqu'elle est activée, GitLab Observability instrumente automatiquement vos pipelines CI/CD, offrant une visibilité sur les performances des pipelines, les durées des jobs et le flux d'exécution, sans aucune modification du code.

- Visibilité sur les jobs qui ralentissent vos pipelines
- Évolution des performances des pipelines au fil du temps
- Les goulots d'étranglement dans votre processus de déploiement

## Activer l'instrumentation des pipelines {#enable-pipeline-instrumentation}

Pour activer l'instrumentation automatique des pipelines, ajoutez la variable CI/CD `GITLAB_OBSERVABILITY_EXPORT` à votre projet ou groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable**.
1. Configurez la variable :
   - **Clé** : `GITLAB_OBSERVABILITY_EXPORT`
   - **Valeur** : une ou plusieurs des valeurs suivantes : `traces`, `metrics`, `logs` (séparées par des virgules pour plusieurs valeurs)
   - **Type** : Variable
   - **Portée de l'environnement** : tout (ou des environnements spécifiques)
1. Sélectionnez **Ajouter une variable**.

## Types d'instrumentation {#instrumentation-types}

La variable `GITLAB_OBSERVABILITY_EXPORT` accepte les valeurs suivantes :

- `traces` : exporte des traces distribuées montrant le flux d'exécution des pipelines, les dépendances des jobs et la chronologie
- `metrics` : exporte des métriques sur la durée des pipelines, les taux de réussite des jobs et l'utilisation des ressources
- `logs` : exporte des logs structurés issus de l'exécution des pipelines

Vous pouvez activer plusieurs types en les séparant par des virgules :

```plaintext
traces,metrics,logs
```

## Fonctionnement {#how-it-works}

Une fois la variable définie, GitLab effectue automatiquement les opérations suivantes :

1. Capture les données d'exécution du pipeline après chaque exécution terminée
1. Convertit les données au format OpenTelemetry selon votre configuration
1. Exporte les données de télémétrie vers votre instance GitLab Observability
1. Rend les données disponibles dans vos tableaux de bord d'observabilité

Aucune modification de votre fichier `.gitlab-ci.yml` n'est requise. L'instrumentation s'effectue automatiquement en arrière-plan.

## Afficher la télémétrie des pipelines {#view-pipeline-telemetry}

Après avoir exécuté des pipelines avec l'instrumentation activée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Observability** > **Services**.
1. Sélectionnez votre service `gitlab-ci` pour afficher les traces, les métriques et les logs de vos exécutions de pipelines.

Le modèle de tableau de bord CI/CD de [GitLab Observability Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/) fournit des visualisations préconfigurées pour l'analyse des performances des pipelines.

## Sujets connexes {#related-topics}

- [Dépannage d'Observability](troubleshooting.md)
