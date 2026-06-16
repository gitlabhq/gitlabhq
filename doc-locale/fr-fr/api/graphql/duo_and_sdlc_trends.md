---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Récupérer les données de tendance GitLab Duo et SDLC
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez l'API GraphQL pour récupérer et exporter les données GitLab Duo.

## Récupérer les données d'utilisation de l'IA {#retrieve-ai-usage-data}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/474469) dans GitLab 17.5 avec un flag nommé `code_suggestions_usage_events_in_pg`. Désactivé par défaut.
- Le feature flag `move_ai_tracking_to_instrumentation_layer` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415) dans GitLab 17.7. Désactivé par défaut.
- La dépendance à `move_ai_tracking_to_instrumentation_layer` [supprimée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527) dans GitLab 17.8.
- Le feature flag `code_suggestions_usage_events_in_pg` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/486469) dans GitLab 17.8.
- L'exigence du module complémentaire GitLab Duo Enterprise pour `AiUsageData` [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/580174) dans GitLab 18.7.

{{< /history >}}

Le point de terminaison `AiUsageData` fournit des données d'événements brutes. Il expose les événements spécifiques aux Code Suggestions via `codeSuggestionEvents` et toutes les données d'événements brutes via `all`.

> [!note]
> Sur les versions antérieures avec GitLab Duo Pro, le point de terminaison `AiUsageData` renvoie `null` sans message d'erreur.

Vous pouvez utiliser ce point de terminaison pour importer des événements dans un outil de BI ou écrire des scripts qui agrègent les données, les taux d'acceptation et les métriques par utilisateur pour tous les événements GitLab Duo.

Les données sont conservées pendant trois mois pour les clients sans ClickHouse installé. Pour les clients avec ClickHouse configuré, il n'existe actuellement aucune politique de rétention des données.

Les attributs `all` et `codeSuggestionEvents` ont une plage de dates maximale d'un mois. Si vous avez besoin de données couvrant plusieurs mois, exécutez des requêtes distinctes pour chaque mois.

L'attribut `all` peut être filtré par `startDate`, `endDate`, `events`, `userIds` et les valeurs de pagination standard.

Pour voir quels événements sont suivis, vous pouvez examiner les événements déclarés dans le fichier [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb).

Les événements GitLab Duo Chat (`request_duo_chat_response`) ne renseignent pas le champ `extras`. Contrairement aux événements Code Suggestions, les interactions Chat ne transportent pas de métadonnées de langue ou de suggestion. Un objet `extras` vide sur les événements Chat est un comportement attendu.

### Pour les projets et les groupes {#for-projects-and-groups}

Par exemple, pour récupérer les données d'utilisation de tous les événements Code Suggestions pour le groupe `gitlab-org` :

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiUsageData {
      codeSuggestionEvents(startDate: "2025-09-26") {
        nodes {
          event
          timestamp
          language
          suggestionSize
          user {
            username
          }
        }
      }
    }
  }
}
```

La requête retourne la sortie suivante :

```graphql
{
  "data": {
    "group": {
      "aiUsageData": {
        "codeSuggestionEvents": {
          "nodes": [
            {
              "event": "CODE_SUGGESTION_SHOWN_IN_IDE",
              "timestamp": "2025-09-26T18:17:25Z",
              "language": "python",
              "suggestionSize": 2,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_REJECTED_IN_IDE",
              "timestamp": "2025-09-26T18:13:45Z",
              "language": "python",
              "suggestionSize": 2,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_ACCEPTED_IN_IDE",
              "timestamp": "2025-09-26T18:13:44Z",
              "language": "python",
              "suggestionSize": 2,
              "user": {
                "username": "jasbourne"
              }
            }
          ]
        }
      }
    }
  }
}
```

Autrement, pour récupérer les données d'utilisation de tous les événements GitLab Duo pour le groupe `gitlab-org` :

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiUsageData {
      all(startDate: "2025-09-26") {
        nodes {
          event
          timestamp
          user {
            username
          }
        }
      }
    }
  }
}
```

La requête retourne la sortie suivante :

```graphql
{
  "data": {
    "group": {
      "aiUsageData": {
        "all": {
          "nodes": [
            {
              "event": "FIND_NO_ISSUES_DUO_CODE_REVIEW_AFTER_REVIEW",
              "timestamp": "2025-09-26T18:17:25Z",
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "REQUEST_REVIEW_DUO_CODE_REVIEW_ON_MR_BY_AUTHOR",
              "timestamp": "2025-09-26T18:13:45Z",
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "AGENT_PLATFORM_SESSION_STARTED",
              "timestamp": "2025-09-26T18:13:44Z",
              "user": {
                "username": "jasbourne"
              }
            }
          ]
        }
      }
    }
  }
}
```

### Pour les instances {#for-instances}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/582153) dans GitLab 18.7. Cette fonctionnalité est une [expérience](../../policy/development_stages_support.md).

{{< /history >}}

Prérequis :

- Vous devez être administrateur de l'instance.

Par exemple, pour récupérer tous les événements d'utilisation GitLab Duo pour l'ensemble de l'instance :

```graphql
query {
  aiUsageData {
    all(startDate: "2025-09-26", endDate: "2025-09-30") {
      nodes {
        event
        timestamp
        user {
          username
        }
        extras
      }
    }
  }
}
```

La requête retourne la sortie suivante :

```json
{
  "data": {
    "aiUsageData": {
      "all": {
        "nodes": [
          {
            "event": "CODE_SUGGESTION_SHOWN_IN_IDE",
            "timestamp": "2025-09-26T18:17:25Z",
            "user": {
              "username": "jasbourne"
            },
            "extras": {}
          },
          {
            "event": "AGENT_PLATFORM_SESSION_STARTED",
            "timestamp": "2025-09-26T18:13:44Z",
            "user": {
              "username": "johndoe"
            },
            "extras": {
              "session_id": "abc123"
            }
          }
        ]
      }
    }
  }
}
```

## Récupérer les métriques utilisateur de l'IA {#retrieve-ai-user-metrics}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/483049) dans GitLab 17.6.
- Types de métriques spécifiques aux fonctionnalités [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/483049) dans GitLab 18.7

{{< /history >}}

Le point de terminaison `AiUserMetrics` fournit des métriques pré-agrégées par utilisateur pour toutes les fonctionnalités GitLab Duo enregistrées, notamment Code Suggestions, GitLab Duo Chat, revue de code, Agent Platform, dépannage des jobs et les appels d'outils Model Context Protocol (MCP).

Vous pouvez utiliser ce point de terminaison pour analyser l'engagement des utilisateurs de GitLab Duo et mesurer la fréquence d'utilisation des différentes fonctionnalités GitLab Duo.

Prérequis :

- Vous devez avoir ClickHouse configuré.

### Nombre total d'événements {#total-event-counts}

Le point de terminaison `AiUserMetrics` fournit les niveaux d'agrégation de nombre d'événements suivants :

- `totalEventCount` de niveau supérieur :  Renvoie la somme de tous les nombres d'événements pour toutes les fonctionnalités GitLab Duo pour un utilisateur.
- `totalEventCount` au niveau de la fonctionnalité :  Disponible dans chaque type de métrique de fonctionnalité, renvoie la somme de tous les nombres d'événements pour cette fonctionnalité spécifique.

Vous pouvez utiliser ces champs pour obtenir des comptages agrégés à différents niveaux de granularité.

Par exemple, pour récupérer les totaux au niveau supérieur et au niveau de la fonctionnalité :

```graphql
query {
  group(fullPath:"gitlab-org") {
    aiUserMetrics {
      nodes {
        user {
          username
        }
        totalEventCount
        codeSuggestions {
          totalEventCount
          codeSuggestionAcceptedInIdeEventCount
          codeSuggestionShownInIdeEventCount
        }
        chat {
          totalEventCount
          requestDuoChatResponseEventCount
        }
      }
    }
  }
}
```

La requête retourne la sortie suivante :

```graphql
{
  "data": {
    "group": {
      "aiUserMetrics": {
        "nodes": [
          {
            "user": {
              "username": "USER_1"
            },
            "totalEventCount": 82,
            "codeSuggestions": {
              "totalEventCount": 60,
              "codeSuggestionAcceptedInIdeEventCount": 10,
              "codeSuggestionShownInIdeEventCount": 50
            },
            "chat": {
              "totalEventCount": 22,
              "requestDuoChatResponseEventCount": 22
            }
          },
          {
            "user": {
              "username": "USER_2"
            },
            "totalEventCount": 102,
            "codeSuggestions": {
              "totalEventCount": 72,
              "codeSuggestionAcceptedInIdeEventCount": 12,
              "codeSuggestionShownInIdeEventCount": 60
            },
            "chat": {
              "totalEventCount": 30,
              "requestDuoChatResponseEventCount": 30
            }
          }
        ]
      }
    }
  }
}
```

Dans cet exemple :

- Le `totalEventCount` de niveau supérieur (82 pour USER_1) est la somme de tous les événements pour toutes les fonctionnalités.
- Le `totalEventCount` de chaque fonctionnalité représente la somme des événements uniquement pour cette fonctionnalité.
  - Code Suggestions :  60 événements (10 acceptés + 50 affichés)
  - Chat :  22 événements

### Types de métriques spécifiques aux fonctionnalités {#feature-specific-metric-types}

Le point de terminaison `AiUserMetrics` fournit des métriques détaillées via des types imbriqués spécifiques aux fonctionnalités. Chaque fonctionnalité GitLab Duo possède son propre type de métrique dédié qui expose les champs de nombre d'événements pour tous les événements suivis liés à cette fonctionnalité.

Les types de métriques de fonctionnalités disponibles incluent :

- `codeSuggestions` :  Métriques spécifiques aux Code Suggestions
- `chat` :  Métriques spécifiques à GitLab Duo Chat
- `codeReview` :  Métriques spécifiques à la revue de code
- `agentPlatform` :  Métriques spécifiques à l'Agent Platform (inclut les sessions Chat agentiques)
- `troubleshootJob` :  Métriques spécifiques au dépannage des jobs
- `mcp` :  Métriques d'appels d'outils Model Context Protocol (MCP)

Chaque type de métrique de fonctionnalité inclut :

- Champs de nombre d'événements individuels pour tous les événements suivis dans cette fonctionnalité
- Un champ `totalEventCount` qui additionne tous les événements pour cette fonctionnalité spécifique

Les champs de nombre d'événements disponibles sont générés dynamiquement en fonction des événements enregistrés dans le système. Pour voir quels événements sont suivis pour chaque fonctionnalité, examinez les événements déclarés dans le fichier [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb).

Par exemple, pour récupérer des métriques détaillées pour plusieurs fonctionnalités GitLab Duo :

```graphql
query {
  group(fullPath:"gitlab-org") {
    aiUserMetrics {
      nodes {
        user {
          username
        }
        codeSuggestions {
          totalEventCount
          codeSuggestionAcceptedInIdeEventCount
          codeSuggestionShownInIdeEventCount
        }
        chat {
          totalEventCount
          requestDuoChatResponseEventCount
        }
        codeReview {
          totalEventCount
          requestReviewDuoCodeReviewOnMrByAuthorEventCount
          findNoIssuesDuoCodeReviewAfterReviewEventCount
        }
        agentPlatform {
          totalEventCount
          agentPlatformSessionStartedEventCount
          agentPlatformSessionFinishedEventCount
        }
      }
    }
  }
}
```

La requête retourne la sortie suivante :

```graphql
{
  "data": {
    "group": {
      "aiUserMetrics": {
        "nodes": [
          {
            "user": {
              "username": "USER_1"
            },
            "codeSuggestions": {
              "totalEventCount": 60,
              "codeSuggestionAcceptedInIdeEventCount": 10,
              "codeSuggestionShownInIdeEventCount": 50
            },
            "chat": {
              "totalEventCount": 22,
              "requestDuoChatResponseEventCount": 22
            },
            "codeReview": {
              "totalEventCount": 8,
              "requestReviewDuoCodeReviewOnMrByAuthorEventCount": 5,
              "findNoIssuesDuoCodeReviewAfterReviewEventCount": 3
            },
            "agentPlatform": {
              "totalEventCount": 15,
              "agentPlatformSessionStartedEventCount": 8,
              "agentPlatformSessionFinishedEventCount": 7
            }
          },
          {
            "user": {
              "username": "USER_2"
            },
            "codeSuggestions": {
              "totalEventCount": 72,
              "codeSuggestionAcceptedInIdeEventCount": 12,
              "codeSuggestionShownInIdeEventCount": 60
            },
            "chat": {
              "totalEventCount": 30,
              "requestDuoChatResponseEventCount": 30
            },
            "codeReview": {
              "totalEventCount": 5,
              "requestReviewDuoCodeReviewOnMrByAuthorEventCount": 3,
              "findNoIssuesDuoCodeReviewAfterReviewEventCount": 2
            },
            "agentPlatform": {
              "totalEventCount": 20,
              "agentPlatformSessionStartedEventCount": 12,
              "agentPlatformSessionFinishedEventCount": 8
            }
          }
        ]
      }
    }
  }
}
```

## Récupérer les métriques de tendance GitLab Duo et SDLC {#retrieve-gitlab-duo-and-sdlc-trend-metrics}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) dans GitLab 16.11.
- L'exigence du module complémentaire [modifiée](https://gitlab.com/gitlab-org/gitlab/-/issues/498497) de GitLab Duo Enterprise vers GitLab Duo Pro dans GitLab 17.6.
- L'exigence du module complémentaire [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/580174) dans GitLab 18.7.

{{< /history >}}

Le point de terminaison `AiMetrics` alimente le tableau de bord des tendances GitLab Duo et SDLC et fournit les métriques pré-agrégées suivantes pour Code Suggestions et GitLab Duo Chat :

- `codeSuggestionsShown`
- `codeSuggestionsAccepted`
- `codeSuggestionAcceptanceRate`
- `codeSuggestionUsers`
- `duoChatUsers`

Prérequis :

- Vous devez avoir ClickHouse configuré.

Par exemple, pour récupérer les données d'utilisation de Code Suggestions et GitLab Duo Chat pour une période spécifiée pour le groupe `gitlab-org` :

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiMetrics(startDate: "2024-12-01", endDate: "2024-12-31") {
      codeSuggestions{
        shownCount
        acceptedCount
        acceptedLinesOfCode
        shownLinesOfCode
      }
      codeContributorsCount
      duoChatContributorsCount
      duoUsedCount
    }
  }
}
```

La requête retourne la sortie suivante :

```graphql
{
  "data": {
    "group": {
      "aiMetrics": {
        "codeSuggestions": {
          "shownCount": 88728,
          "acceptedCount": 7016,
          "acceptedLinesOfCode": 9334,
          "shownLinesOfCode": 124118
        },
        "codeContributorsCount": 719,
        "duoChatContributorsCount": 681,
        "duoUsedCount": 714
      }
    }
  },
}
```

## Exporter les données de métriques IA au format CSV {#export-ai-metrics-data-to-csv}

Vous pouvez exporter les données de métriques IA vers un fichier CSV avec l'[outil GitLab AI Metrics Exporter](https://gitlab.com/smathur/custom-duo-metrics).
