---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Données d'évaluation des risques de vulnérabilité"
---

Utilisez les données de risque de vulnérabilité pour évaluer l'impact potentiel sur votre environnement.

- Gravité : chaque vulnérabilité se voit attribuer une valeur de gravité GitLab standardisée.
- Pour les vulnérabilités du catalogue [Common Vulnerabilities and Exposures (CVE)](https://www.cve.org/), les données suivantes peuvent être récupérées via la page [vulnerability details](_index.md) ou à l'aide d'une requête GraphQL :
  - Probabilité d'exploitation : score de l'[Exploit Prediction Scoring System (EPSS)](https://www.first.org/epss/).
  - Existence d'exploits connus : statut des [Known Exploited Vulnerabilities (KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog).

Utilisez ces données pour aider à prioriser les actions de remédiation et de mitigation. Par exemple, une vulnérabilité de gravité moyenne avec un score EPSS élevé peut nécessiter une mitigation plus rapide qu'une vulnérabilité de gravité élevée avec un score EPSS faible.

## EPSS {#epss}

{{< history >}}

- Introduit dans GitLab 17.4 [avec des feature flags](../../../administration/feature_flags/_index.md) nommés `epss_querying` (dans le ticket [470835](https://gitlab.com/gitlab-org/gitlab/-/issues/470835)) et `epss_ingestion` (dans le ticket [467672](https://gitlab.com/gitlab-org/gitlab/-/issues/467672)). Fonctionnalité désactivée par défaut.
- Renommés en `cve_enrichment_querying` et `cve_enrichment_ingestion`, et [activés sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/481431) dans GitLab 17.6.
- [Disponible de manière générale](https://gitlab.com/groups/gitlab-org/-/epics/11544) dans GitLab 17.7. Les feature flags `cve_enrichment_querying` et `cve_enrichment_ingestion` ont été supprimés.

{{< /history >}}

Le score EPSS fournit une estimation de la probabilité qu'une vulnérabilité du catalogue CVE soit exploitée dans les 30 prochains jours. EPSS attribue à chaque CVE un score compris entre 0 et 1 (équivalent à 0 % à 100 %).

## KEV {#kev}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/499407) dans GitLab 17.7.

{{< /history >}}

Le catalogue KEV répertorie les vulnérabilités dont l'exploitation est avérée. Vous devez prioriser la remédiation des vulnérabilités du catalogue KEV par rapport aux autres vulnérabilités. Des attaques utilisant ces vulnérabilités ont eu lieu, et la méthode d'exploitation est probablement connue des personnes malveillantes.

## Reachability {#reachability}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/16510) dans GitLab 17.11.

{{< /history >}}

La reachability indique si un package vulnérable est importé par votre application. Les vulnérabilités dans les packages avec lesquels votre code interagit directement présentent un risque plus élevé que celles présentes dans les dépendances non utilisées. Priorisez la correction des vulnérabilités accessibles, car elles représentent des points d'exposition réels que des personnes malveillantes pourraient exploiter.

Pour plus de détails, consultez [Static reachability](../dependency_scanning/static_reachability.md).

## Interroger les données d'évaluation des risques {#query-risk-assessment-data}

Utilisez l'API GraphQL pour interroger les valeurs de gravité, EPSS et KEV des vulnérabilités d'un projet.

Le type `Vulnerability` de l'API GraphQL possède un champ `cveEnrichment`, qui est renseigné lorsque le champ `identifiers` contient un identifiant CVE. Le champ `cveEnrichment` contient l'identifiant CVE, le score EPSS et le statut KEV de la vulnérabilité. Les scores EPSS sont arrondis à la deuxième décimale.

Par exemple, la requête API GraphQL suivante renvoie toutes les vulnérabilités d'un projet donné ainsi que leur identifiant CVE, leur score EPSS et leur statut KEV (`isKnownExploit`). Exécutez la requête dans l'[explorateur GraphQL](../../../api/graphql/_index.md#interactive-graphql-explorer) ou tout autre client GraphQL.

```graphql
{
  project(fullPath: "<full/path/to/project>") {
    vulnerabilities {
      nodes {
        severity
        identifiers {
          externalId
          externalType
        }
        cveEnrichment {
          epssScore
          isKnownExploit
          cve
        }
        reachability
      }
    }
  }
}
```

Exemple de sortie :

```json
{
  "data": {
    "project": {
      "vulnerabilities": {
        "nodes": [
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2019-3859",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.2,
              "isKnownExploit": false,
              "cve": "CVE-2019-3859"
            }
            "reachability": "UNKNOWN"
          },
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2016-8735",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.94,
              "isKnownExploit": true,
              "cve": "CVE-2016-8735"
            }
            "reachability": "IN_USE"
          },
        ]
      }
    }
  },
  "correlationId": "..."
}
```

## Vulnerability Prioritizer {#vulnerability-prioritizer}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

Utilisez le [composant CI/CD Vulnerability Prioritizer](https://gitlab.com/explore/catalog/components/vulnerability-prioritizer) pour aider à prioriser les vulnérabilités d'un projet (notamment les CVE). Le composant génère un rapport de priorisation dans la sortie du job `vulnerability-prioritizer`.

Les vulnérabilités sont listées dans l'ordre suivant :

1. Les vulnérabilités avec exploitation connue (KEV) sont la priorité absolue.
1. Les scores EPSS plus élevés (proches de 1) sont priorisés.
1. Les gravités sont classées de `Critical` à `Low`.

Seules les vulnérabilités détectées par l'[analyse des dépendances](../dependency_scanning/_index.md) et le [container scanning](../container_scanning/_index.md) sont incluses, car le composant CI/CD Vulnerability Prioritizer nécessite des données uniquement disponibles dans les enregistrements Common Vulnerabilities and Exposures (CVE). De plus, seules les vulnérabilités [détectées (**Nécessite un classement**) et confirmées](_index.md#vulnerability-status-values) sont affichées.

Pour ajouter le composant CI/CD Vulnerability Prioritizer au pipeline CI/CD de votre projet, consultez la [documentation de Vulnerability Prioritizer](https://gitlab.com/components/vulnerability-prioritizer).
