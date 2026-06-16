---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Limites de débit pour les utilisateurs authentifiés dans GitLab Dedicated, limites par défaut par architecture de référence et stratégies de gestion."
title: Limites de débit pour les utilisateurs authentifiés
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated applique automatiquement des limites de débit pour les utilisateurs authentifiés afin de garantir la stabilité du système et d'aider à maintenir les performances pour tous les utilisateurs de votre instance. Les limites de débit empêchent tout utilisateur ou compte de service unique de générer des alertes excessives ou de provoquer une dégradation généralisée de l'instance.

Lorsqu'un utilisateur dépasse sa limite de débit, GitLab renvoie un code de statut HTTP `429 Too Many Requests` avec une réponse en texte brut `Retry later`.

Les limites de débit sont automatiquement configurées et gérées par GitLab. Vous ne pouvez pas :

- Modifier les valeurs des limites de débit.
- Désactiver la limitation de débit.
- Configurer des limites de débit personnalisées via la zone d'administration.
- Accéder aux paramètres de limitation de débit dans l'interface utilisateur.

GitLab gère ces paramètres pour garantir des performances et une stabilité optimales pour votre instance.

Pour plus d'informations, consultez [les limites de débit](../../security/rate_limits.md).

## Limites de débit par type de requête {#rate-limits-by-request-type}

Les limites de débit s'appliquent à tous les utilisateurs authentifiés, y compris les utilisateurs réguliers et les comptes de service. GitLab définit automatiquement ces limites en fonction de la taille de votre architecture de référence. Les limites s'appliquent séparément aux requêtes API et aux requêtes web :

- Requêtes API :  Appels d'API REST et GraphQL, y compris les requêtes provenant d'intégrations, de jobs CI/CD et de scripts d'automatisation.
- Requêtes web :  Requêtes effectuées via l'interface utilisateur de GitLab.

| Architecture de référence | Requêtes API par minute | Requêtes web par minute |
| ---------------------- | ----------------------- | ----------------------- |
| 1 000 utilisateurs            | 1 200                   | 120                     |
| 2 000 utilisateurs            | 2 400                   | 480                     |
| 3 000 utilisateurs            | 3 600                   | 600                     |
| 5 000 utilisateurs            | 6 000                   | 600                     |
| 10 000 utilisateurs           | 12 000                  | 1 200                   |
| 25 000 utilisateurs           | 30 000                  | 3 000                   |
| 50 000 utilisateurs           | 60 000                  | 6 000                   |

Pour plus d'informations, consultez les [architectures de référence](../reference_architectures/_index.md).

## En-têtes de réponse {#response-headers}

GitLab inclut des informations sur les limites de débit dans les en-têtes de réponse pour toutes les requêtes. Vous pouvez utiliser ces en-têtes pour surveiller votre utilisation actuelle et le quota restant.

Pour plus d'informations sur les limites de débit qui incluent des en-têtes de réponse et les en-têtes disponibles, consultez [les systèmes de limitation de débit multiples](../settings/user_and_ip_rate_limits.md#multiple-rate-limiting-systems).

## Améliorer l'efficacité des requêtes {#improve-request-efficiency}

Pour travailler plus efficacement avec les limites de débit :

1. Optimiser les modèles de requêtes :

   - Ajoutez des délais entre les requêtes dans les scripts automatisés.
   - Combinez les requêtes API lorsque c'est possible.
   - Utilisez GraphQL pour récupérer uniquement les données dont vous avez besoin.
   - Implémentez une pagination efficace pour les grands ensembles de données.

1. Auditer et optimiser les usages à fort volume :

   - Examinez les utilisateurs ou les comptes de service qui effectuent le plus de requêtes.
   - Examinez les jobs CI/CD qui effectuent des appels API excessifs.
   - Examinez les intégrations qui se connectent à votre instance GitLab.
   - Mettez à jour les processus automatisés pour rester en dessous des seuils des limites de débit.
