---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Guide de déploiement de la solution GitLab Security Metrics and KPIs, notamment l'export des données de vulnérabilité vers Splunk, la configuration du pipeline CI/CD, la configuration du tableau de bord et les bonnes pratiques."
title: Security Metrics and KPIs
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document décrit le guide d'installation, de configuration et d'utilisation du composant de solution GitLab Security Metrics and KPIs. Ce composant de solution de sécurité fournit des métriques et des KPIs consultables par unités métier, plages temporelles, niveaux de gravité des vulnérabilités et types de sécurité. Il peut fournir un instantané de la posture de sécurité sur une base mensuelle ou trimestrielle sous forme de documents PDF. Les données sont visualisées à l'aide d'un tableau de bord dans Splunk.

![Security Metrics and KPIs](img/security_metrics_kpi_v17_9.png)

Cette solution exporte les données de vulnérabilité des projets ou groupes GitLab via l'API GraphQL, les envoie à Splunk via le HTTP Event Collector (HEC) et inclut un tableau de bord prêt à l'emploi pour la visualisation des métriques de sécurité. Le processus d'export est conçu pour s'exécuter en tant que pipeline CI/CD GitLab sur une base planifiée.

## Premiers pas {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique en ligne des composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

### Configurer le projet du composant de solution {#set-up-the-solution-component-project}

1. Créez un nouveau projet GitLab pour héberger cet exportateur.
1. Copiez les fichiers fournis dans votre projet :
   - `export_vulns.py`
   - `send_to_splunk.py`
   - `requirements.txt`
   - `.gitlab-ci.yml`
1. Configurez les variables CI/CD requises dans les paramètres de votre projet.
1. Configurez une planification de pipeline (par exemple, quotidienne ou hebdomadaire).

## Fonctionnement {#how-it-works}

La solution se compose de deux composants principaux :

1. Un exportateur de vulnérabilités qui récupère les données depuis le tableau de bord de sécurité GitLab
1. Un ingéreur Splunk qui traite les données exportées et les envoie vers Splunk HEC

Le pipeline s'exécute en deux étapes :

1. `extract` : récupère les vulnérabilités et les enregistre au format CSV
1. `ingest` : envoie les données de vulnérabilité à Splunk

## Configuration {#configuration}

### Variables CI/CD requises {#required-cicd-variables}

| Variable | Description | Exemple de valeur |
|----------|-------------|---------------|
| `SCOPE` | Portée cible pour l'analyse des vulnérabilités | `group:security/appsec` ou `security/my-project` |
| `GRAPHQL_API_TOKEN` | Jeton d'accès personnel GitLab avec accès API | `glpat-XXXXXXXXXXXXXXXX` |
| `GRAPHQL_API_URL` | URL de l'API GraphQL GitLab | `https://gitlab.com/api/graphql` |
| `SPLUNK_HEC_TOKEN` | Jeton HTTP Event Collector de Splunk | `11111111-2222-3333-4444-555555555555` |
| `SPLUNK_HEC_URL` | URL du point de terminaison HEC de Splunk | `https://splunk.company.com:8088/services/collector` |

### Variables CI/CD facultatives {#optional-cicd-variables}

| Variable | Description | Exemple de valeur | Valeur par défaut |
|----------|-------------|---------------|---------|
| `SEVERITY_FILTER` | Liste de niveaux de gravité séparés par des virgules | `CRITICAL,HIGH,MEDIUM` | Toutes les gravités |
| `VULN_TIME_WINDOW` | Fenêtre temporelle pour la collecte des vulnérabilités | `24h`, `7d` ou `all` | `24h` |

### Configuration de la portée {#scope-configuration}

La variable `SCOPE` détermine les projets ou groupes à analyser :

- Pour un projet : `mygroup/myproject`
- Pour un groupe : `group:mygroup/subgroup`
- Pour l'instance entière : `instance`

### Exemples de filtres de gravité {#severity-filter-examples}

Niveaux de gravité valides :

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

Exemples de combinaisons :

- `CRITICAL,HIGH`
- `CRITICAL,HIGH,MEDIUM`
- Laisser vide pour inclure toutes les gravités

### Configuration de la fenêtre temporelle {#time-window-configuration}

La variable `VULN_TIME_WINDOW` contrôle la période de recherche des vulnérabilités :

- Format : `<number><unit>` où :
  - `number` : tout entier positif
  - `unit` : `h` pour les heures ou `d` pour les jours
- Exemples :
  - `24h` : 24 dernières heures
  - `7h` : 7 dernières heures
  - `15d` : 15 derniers jours
  - `30d` : 30 derniers jours
  - `all` : toutes les vulnérabilités (utile pour la première exécution)

Valeur par défaut : `24h`

Exemples de configurations de pipeline :

```yaml
# For 12-hour window
variables:
  VULN_TIME_WINDOW: "12h"

# For 3-day window
variables:
  VULN_TIME_WINDOW: "3d"

# For all vulnerabilities
variables:
  VULN_TIME_WINDOW: "all"
```

Planifiez votre pipeline en fonction de la fenêtre temporelle choisie. Par exemple :

- Pour 12h : planifier deux fois par jour
- Pour 3d : planifier tous les 3 jours
- Ajoutez un chevauchement dans la planification pour éviter de manquer des vulnérabilités

## Configuration du pipeline {#pipeline-setup}

1. **First Run** :

   - Définissez `VULN_TIME_WINDOW: "all"` pour collecter toutes les vulnérabilités historiques
   - Exécutez le pipeline une fois

1. **Ongoing Collection** :

   - Définissez `VULN_TIME_WINDOW` sur la fenêtre souhaitée (`24h` ou `7d`)
   - Configurez une planification de pipeline :
     - Pour `24h` : planifier quotidiennement
     - Pour `7d` : planifier hebdomadairement

## Intégration Splunk {#splunk-integration}

Le script envoie les vulnérabilités sous forme d'événements à Splunk.

### Configuration de l'index {#index-configuration}

1. Créez un nouvel index nommé `gitlab_vulns` dans Splunk
1. Lors de la création de votre jeton HEC :
   - Définissez l'**index** par défaut sur `gitlab_vulns` (cet index est référencé dans la recherche de base du tableau de bord Splunk fourni)
   - Assurez-vous que le jeton dispose des autorisations d'écriture dans cet index
   - Assurez-vous que le jeton possède un **sourcetype** permettant une analyse correcte des données d'événement au format JSON

Chaque événement inclut :

- Heure de détection
- Titre et description de la vulnérabilité
- Niveau de gravité
- Informations sur le scanner
- Détails du projet
- URL du projet et de la vulnérabilité

## Configuration du tableau de bord {#dashboard-setup}

Le tableau de bord fourni offre une visibilité complète sur vos données de vulnérabilité GitLab avec les visualisations suivantes :

- Métriques P95 de l'âge pour les vulnérabilités Critiques et Élevées (jauges radiales)
- Analyse du vieillissement montrant la distribution des vulnérabilités Critiques et Élevées par tranches d'âge (0-30 jours, 31-90 jours, 91-180 jours, 180+ jours)
- Top 10 des CVE les plus fréquents avec leur nombre d'occurrences
- Distribution des vulnérabilités par chemin de projet et niveau de gravité
- Toutes les métriques peuvent être filtrées par unité métier et plage temporelle

Pour configurer le tableau de bord :

1. **Business Unit Mapping** :
   1. Créez un fichier CSV avec deux colonnes :

      ```shell
      project_url,business_unit
      ```

   1. Mappez chaque URL de projet GitLab à son unité métier correspondante.
   1. Importez le fichier dans Splunk en tant que table de correspondance :
      1. Accédez à **Paramètres** > **Lookups** > **Lookup table files**.
      1. Sélectionnez **New Lookup Table File**.
      1. Importez votre fichier CSV.
      1. Définissez le **Destination filename** sur `business_unit_mapping.csv`.
      1. Configurez les autorisations :
         1. Trouvez la ligne intitulée `<splunk_dir>/etc/apps/search/lookups/business_unit_mapping.csv`.
         1. Sélectionnez **Autorisations**.
         1. Définissez les autorisations sur l'une des options suivantes :
            - Définir sur **Globales** pour un accès à l'échelle de l'instance.
            - Partager avec des applications ou des rôles spécifiques selon les besoins.
         1. Sélectionnez **Enregistrer**.

1. **Dashboard Installation** :
   1. Enregistrez le fichier `vuln_metrics_dashboard.xml` fourni.
   1. Dans Splunk :
      1. Accédez à l'application Search.
      1. Cliquez sur **Tableaux de bord** > **Create New Dashboard**.
      1. Sélectionnez **Source** dans la vue d'édition.
      1. Remplacez le XML par défaut par le contenu de `vuln_metrics_dashboard.xml`.
      1. Enregistrez le tableau de bord.

## Format de sortie {#output-format}

Le fichier CSV intermédiaire contient :

- `detectedAt` : horodatage de détection
- `title` : titre de la vulnérabilité
- `severity` : Niveau de gravité
- `primaryIdentifier` : identifiant de vulnérabilité
- `exporter` : Nom du scanner
- `projectPath` : chemin du projet GitLab
- `projectUrl` : URL du projet
- `description` : Description de la vulnérabilité
- `webUrl` : URL des détails de la vulnérabilité

## Gestion des erreurs {#error-handling}

La solution inclut :

- Gestion de la limite de débit avec backoff exponentiel
- Traitement par lots pour l'ingestion Splunk
- Rapport d'erreurs approprié
- Gestion des délais d'expiration
- Prise en charge de l'encodage UTF-8

## Bonnes pratiques {#best-practices}

1. **Token Permissions** :

   - GRAPHQL_API_TOKEN nécessite :
     - Accès en lecture au groupe/projet cible
     - Accès au tableau de bord de sécurité
   - SPLUNK_HEC_TOKEN nécessite :
     - Autorisations de soumission d'événements vers l'index cible

1. **Schedule Frequency** :

   - Faites correspondre la planification à votre `VULN_TIME_WINDOW`
   - Incluez un chevauchement pour éviter de manquer des vulnérabilités
   - Tenez compte des SLA de votre organisation

1. **Surveillance** :

   - Surveiller la réussite/l'échec du pipeline
   - Suivre le nombre de vulnérabilités exportées
   - Surveiller la réussite de l'ingestion Splunk

## Dépannage {#troubleshooting}

Problèmes courants et solutions :

1. **No vulnerabilities exported** :

   - Vérifier le paramètre SCOPE
   - Vérifier les autorisations du jeton
   - Vérifier l'accès au tableau de bord de sécurité

1. **Splunk ingestion fails** :

   - Vérifier l'URL HEC et le jeton
   - Vérifier la connectivité réseau
   - Vérifier les autorisations de l'index
