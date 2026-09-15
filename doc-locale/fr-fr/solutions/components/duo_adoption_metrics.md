---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Mesurez et visualisez l'adoption et l'utilisation de GitLab Duo avec un pipeline de collecte de données basé sur la CI, un client API GraphQL et un tableau de bord Duo Analytics."
title: "Métriques et analyses d'adoption de GitLab Duo"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Métriques et analyses d'adoption de GitLab Duo {#gitlab-duo-adoption-metrics--analytics}

Ce projet fournit des analyses d'utilisation de GitLab Duo de bout en bout, combinant :

- **Duo GraphQL Data Collection** – Un orchestrateur Python générique qui appelle les scripts collecteurs Duo, s'appuyant sur un client API GraphQL GitLab.
- **Duo Usage Metrics Pipeline** – Des jobs CI qui collectent et agrègent périodiquement les données d'utilisation de Duo pour vos groupes GitLab.
- **Duo Analytics Dashboard** – Un tableau de bord hébergé sur GitLab Pages affichant l'adoption de Duo, l'intensité d'utilisation et les tendances d'engagement.

## Premiers pas {#getting-started}

Vous pouvez contrôler les pipelines d'analyse exécutés en définissant ces **Project CI/CD Variables** :

| Variable | Configuration Duo | Description |
|----------|-----------|-------------|
| `ENABLE_DUO_METRICS` | `"true"` | Activer/désactiver le pipeline de métriques IA Duo. |
| `ENABLE_PROJECT_METRICS` | `"false"` | Désactiver les métriques traditionnelles centrées sur les projets lorsque seule l'adoption de Duo vous intéresse. |
| `DUO_TOKEN` | `TOKEN VALUE` | Jeton d'accès personnel avec les autorisations `read_api` et `ai_features` pour la collecte des données d'utilisation de Duo. |
| `GROUP_PATH` | `example_group` | Chemin du groupe principal ou du sous-groupe pour lequel collecter les métriques Duo. |

**Étapes pour démarrer rapidement**

1. Dupliquez ce dépôt.
1. Accédez à **Project Settings → CI/CD → Variables**.
1. Ajoutez les variables ci-dessus avec les valeurs appropriées à votre environnement.
1. Configurez un **scheduled pipeline** à l'intervalle de votre choix. La collecte des données d'utilisation de Duo peut être intensive ; il est donc recommandé de l'exécuter **une fois par jour**.
1. Exécutez le pipeline planifié manuellement ou attendez son déclenchement automatique.
1. Une fois le pipeline terminé, ouvrez l'application **Pages** sous **Deploy → Pages** pour accéder au tableau de bord Duo Analytics.

## Déploiement GitLab Pages (métriques Duo) {#gitlab-pages-deployment-duo-metrics}

Lorsque les métriques Duo sont activées, le déploiement Pages s'effectue automatiquement après la fin du pipeline Duo :

- **Duo Metrics Pipeline** → Déploie vers une URL telle que `https://your-username.gitlab.io/project-name/duo-metrics/`.
- **Main Landing Page** → Disponible à l'adresse `https://your-username.gitlab.io/project-name/`, avec des liens vers les tableaux de bord disponibles.

La page d'accueil détecte automatiquement les tableaux de bord présents et affiche les liens Duo lorsque `ENABLE_DUO_METRICS="true"`.

## Développement local et tests {#local-development--testing}

Pour tester localement les analyses Duo (sans CI) :

1. Assurez-vous que Python et les dépendances sont installés (par exemple via `poetry install` à la racine du dépôt).
1. Définissez les variables d'environnement requises dans un fichier `.env` local ou dans une session shell :
   - `DUO_TOKEN`
   - `GROUP_PATH`
1. Exécutez le script orchestrateur générique pour collecter les données brutes d'utilisation de Duo :

```shell
python ai_raw_data_collection.py
```

1. Ouvrez les métriques générées dans le dossier local `public/` ou `docs/` (selon votre configuration), ou exécutez le tableau de bord localement comme décrit dans la documentation du projet de composant de solution.

## Fonctionnalités du tableau de bord Duo {#duo-dashboard-features}

Le tableau de bord Duo Analytics se concentre sur l'adoption de GitLab Duo et les schémas d'utilisation de l'IA, notamment :

- **License & Adoption Analytics** – Suivez le nombre d'utilisateurs ayant accès à Duo et le nombre d'utilisateurs actifs.
- **Code Suggestions Analytics** – Surveillez les taux d'acceptation, le volume de suggestions et la distribution par langage pour le codage assisté par IA.
- **Duo Chat Analytics** – Consultez les interactions de chat, les cohortes d'utilisateurs et les volumes de conversations.
- **User Engagement Analytics** – Segmentez les utilisateurs par niveau d'utilisation (inactif, en exploration, régulier, intensif).
- **Language & Workflow Performance** – Analysez l'efficacité de Duo (par exemple, taux d'acceptation, utilisation des suggestions) par langage de programmation ou workflow.

Ces métriques sont entièrement dérivées des signaux liés à Duo ; les métriques de projet traditionnelles ne sont pas nécessaires pour utiliser ce tableau de bord.

## Pipeline de collecte des données d'utilisation Duo {#duo-usage-data-collection-pipeline}

Les métriques d'adoption Duo sont créées par un pipeline de collecte de données piloté par la CI qui repose sur :

- Un **generic Python orchestrator** : `ai_raw_data_collection.py`
- Un **GitLab GraphQL API client** réutilisable : `gitlab_graphql_api`

### Orchestrateur : `ai_raw_data_collection.py` {#orchestrator-ai_raw_data_collectionpy}

Le script `ai_raw_data_collection.py` est responsable de :

- La lecture des variables d'environnement/CI (telles que `GROUP_PATH`, `DUO_TOKEN` et la configuration du pipeline).
- L'invocation d'un ou plusieurs **collector scripts** qui implémentent des requêtes d'utilisation Duo concrètes.
- La coordination :
  - De la pagination entre les groupes et les projets.
  - Des fenêtres de dates/heures ou des stratégies d'échantillonnage pour les événements d'utilisation Duo.
  - De la normalisation des résultats dans un format cohérent et adapté à l'analyse (par exemple, CSV/JSON).
- L'écriture des données collectées vers les emplacements utilisés par le tableau de bord Duo et les étapes d'agrégation en aval.

Il agit comme un **generic entry point** pour la collecte des données brutes d'utilisation Duo, vous permettant de :

- Ajouter de nouveaux collecteurs liés à Duo sans modifier la configuration CI.
- Contrôler les collecteurs exécutés via des variables d'environnement ou des jobs CI.

### Client API GraphQL GitLab et collections {#gitlab-graphql-api-client--collections}

Toute la logique GraphQL liée à Duo est encapsulée dans le package Python `gitlab_graphql_api`, notamment dans :

- `gitlab_graphql_api > collections`

Concepts clés :

- **GraphQL client abstraction** – Un client central gère l'authentification, la pagination et la gestion des erreurs vis-à-vis du point de terminaison GraphQL GitLab.
- **Collection classes** – Le module `collections` fournit des abstractions de niveau supérieur (telles que « collections de projets » ou « collections d'utilisateurs ») qui exposent des méthodes pour récupérer des données structurées. Les collecteurs Duo les utilisent pour :
  - Récupérer les groupes et les projets pour un `GROUP_PATH` donné.
  - Interroger les champs d'utilisation Duo et l'activité liée à l'IA.
- **Versioned API usage** – La même API de collections peut être étendue au fur et à mesure que GitLab améliore ou développe les champs GraphQL liés à Duo, sans modifier l'orchestrateur.

Les collecteurs Duo importent ces classes de collection et définissent les requêtes spécifiques dont ils ont besoin (par exemple, la récupération du nombre de suggestions de code IA, des événements d'utilisation du chat ou des statistiques d'adoption au niveau des utilisateurs).

> **Remarque :** Le schéma GraphQL et les noms de champs pour l'utilisation Duo sont documentés aux côtés des classes de collection dans `gitlab_graphql_api > collections`. Consultez cette documentation lors de l'extension ou de la personnalisation des données collectées pour les métriques Duo.

## Configuration de la collecte de données Duo {#configuring-duo-data-collection}

Bien que le pipeline puisse être personnalisé, une configuration type réservée à Duo nécessite :

- **Minimal CI configuration** :
  - Activez le pipeline Duo en définissant `ENABLE_DUO_METRICS="true"`.
  - Désactivez éventuellement les pipelines non liés à Duo en définissant `ENABLE_PROJECT_METRICS="false"`.
- **Environment variables** utilisées par `ai_raw_data_collection.py` :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DUO_TOKEN` | Jeton avec `read_api` + `ai_features`, utilisé pour les requêtes GraphQL Duo. | `glpat-xxxx` |
| `GROUP_PATH` | Groupe ou sous-groupe dont l'utilisation de Duo doit être mesurée. | `"gitlab-org/your-group"` |
| `DUO_METRICS_OUTPUT_DIR` | Répertoire de sortie optionnel pour les données brutes d'utilisation Duo. | `"duo-metrics/raw"` |

Une fois ces paramètres définis, le job CI qui exécute `ai_raw_data_collection.py` va :

1. Utiliser les collections `gitlab_graphql_api` pour interroger les données d'utilisation Duo pour le groupe spécifié.
1. Écrire les artefacts bruts d'utilisation Duo qui peuvent être :
   - Agrégés dans des rapports.
   - Chargés directement par le tableau de bord Duo.

## Extension des métriques Duo {#extending-duo-metrics}

Pour ajouter ou affiner les métriques d'adoption Duo :

1. **Identify** les champs GraphQL GitLab pertinents pour le nouveau signal Duo (par exemple, des compteurs d'utilisation supplémentaires ou de nouvelles fonctionnalités IA).
1. **Update or add** un script collecteur qui :
   - Utilise les abstractions `gitlab_graphql_api > collections`.
   - Écrit les données dans un format cohérent avec les collecteurs Duo existants.
1. **Wire the collector** à `ai_raw_data_collection.py` (ou contrôlez-le via des variables d'environnement).
1. **Update the dashboard** pour consommer et visualiser les nouveaux champs, si nécessaire.

Étant donné que la logique d'accès GraphQL et de pagination est encapsulée dans `gitlab_graphql_api`, l'extension des métriques Duo implique généralement :

- Des modifications minimales dans l'orchestrateur.
- Une concentration sur la modélisation de la nouvelle métrique et la mise à jour du tableau de bord.

## Ressources {#resources}

- [Projet de composant de solution GitLab Duo Adoption Metrics](https://gitlab.com/gitlab-com/product-accelerator/work-streams/packaging/gitlab-graphql-api)
- Package `gitlab_graphql_api` et module `collections` (pour les schémas d'utilisation GraphQL de Duo)
