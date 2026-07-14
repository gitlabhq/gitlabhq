---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
gitlab_dedicated: no
title: "Vérification de l'état de santé"
description: "Effectuer des vérifications de l'état de santé, de l'activité et de la disponibilité."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des sondes d'activité et de disponibilité pour indiquer l'état de santé du service et l'accessibilité aux services requis. Ces sondes rapportent l'état de la connexion à la base de données, de la connexion Redis et de l'accès au système de fichiers. Ces endpoints [peuvent être fournis à des planificateurs comme Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) pour retenir le trafic jusqu'à ce que le système soit prêt ou pour redémarrer le conteneur si nécessaire.

Les endpoints de vérification de l'état de santé sont généralement utilisés pour les équilibreurs de charge et d'autres systèmes de planification Kubernetes qui doivent déterminer la disponibilité du service avant de rediriger le trafic.

Vous ne devez pas utiliser ces endpoints pour déterminer le temps de disponibilité effectif sur de grands déploiements Kubernetes. Cela peut afficher des faux négatifs lorsque des pods sont supprimés par mise à l'échelle automatique, en cas de défaillance d'un nœud, ou pour d'autres besoins opérationnels normaux et non perturbateurs.

Pour déterminer le temps de disponibilité sur de grands déploiements Kubernetes, observez le trafic vers l'interface utilisateur. Celui-ci est correctement équilibré et planifié, et constitue donc un meilleur indicateur du temps de disponibilité effectif. Vous pouvez également surveiller l'endpoint de la page de connexion `/users/sign_in`.

<!-- vale gitlab_base.Spelling = NO -->

Sur GitLab.com, des outils tels que [Pingdom](https://www.pingdom.com/) et les mesures Apdex sont utilisés pour déterminer le temps de disponibilité.

<!-- vale gitlab_base.Spelling = YES -->

## Liste d'autorisation IP {#ip-allowlist}

Pour accéder aux ressources de surveillance, l'IP du client demandeur doit être incluse dans la liste d'autorisation. Pour plus de détails, consultez [comment ajouter des adresses IP à la liste d'autorisation pour les endpoints de surveillance](ip_allowlist.md).

## Utilisation des endpoints en local {#using-the-endpoints-locally}

Avec les paramètres de liste d'autorisation par défaut, les sondes sont accessibles depuis localhost en utilisant les URL suivantes :

```plaintext
GET http://localhost/-/health
```

```plaintext
GET http://localhost/health_check
```

```plaintext
GET http://localhost/-/readiness
```

```plaintext
GET http://localhost/-/liveness
```

## État de santé {#health}

Vérifie si le serveur d'application est en cours d'exécution. Il ne vérifie pas si la base de données ou les autres services sont en cours d'exécution. Cet endpoint contourne les contrôleurs Rails et est implémenté en tant que middleware supplémentaire `BasicHealthCheck` très tôt dans le cycle de vie du traitement des requêtes.

```plaintext
GET /-/health
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/-/health"
```

Exemple de réponse :

```plaintext
GitLab OK
```

## Vérification complète de l'état de santé {#comprehensive-health-check}

> [!warning]
> **N'utilisez pas `/health_check` pour l'équilibrage de charge ou la mise à l'échelle automatique.** Cet endpoint valide les services backend (base de données, Redis) et échouera même lorsque l'application fonctionne correctement si ces services sont lents ou indisponibles. Cela peut entraîner la suppression inutile de nœuds d'application sains des équilibreurs de charge.

L'endpoint `/health_check` effectue des vérifications complètes de l'état de santé, notamment la connectivité de la base de données, la disponibilité de Redis et d'autres services backend. Il est fourni par le gem `health_check` et valide l'ensemble de la pile applicative.

Utilisez cet endpoint pour :

- Surveillance complète de l'application
- Validation de l'état de santé des services backend
- Résolution des problèmes de connectivité
- Tableaux de bord de surveillance et alertes

```plaintext
GET /health_check
GET /health_check/database
GET /health_check/cache
GET /health_check/migrations
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/health_check"
```

Exemple de réponse (succès) :

```plaintext
success
```

Exemple de réponse (échec) :

```plaintext
health_check failed: Unable to connect to database
```

Vérifications disponibles :

- `database` - Connectivité de la base de données
- `migrations` - État des migrations de la base de données
- `cache` - Connectivité du cache Redis
- `geo` (EE uniquement) - État de la réplication Geo

## Disponibilité {#readiness}

La sonde de disponibilité vérifie si l'instance GitLab est prête à accepter le trafic via les contrôleurs Rails. Par défaut, la vérification valide uniquement les vérifications d'instance.

Si le paramètre `all=1` est spécifié, la vérification valide également les services dépendants (base de données, Redis, Gitaly, etc.) et fournit un état pour chacun.

```plaintext
GET /-/readiness
GET /-/readiness?all=1
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/-/readiness"
```

Exemple de réponse :

```json
{
   "master_check":[{
      "status":"failed",
      "message": "unexpected Master check result: false"
   }],
   ...
}
```

En cas d'échec, l'endpoint renvoie un code de statut HTTP `503`.

Cette vérification est exemptée de Rack Attack.

## Activité {#liveness}

> [!warning]
> Dans GitLab [12.4](https://about.gitlab.com/upcoming-releases/), le corps de la réponse de la vérification d'activité a été modifié pour correspondre à l'exemple ci-dessous.

Vérifie si le serveur d'application est en cours d'exécution. Cette sonde est utilisée pour savoir si les contrôleurs Rails ne sont pas bloqués en raison d'un multi-threading.

```plaintext
GET /-/liveness
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/-/liveness"
```

Exemple de réponse :

En cas de succès, l'endpoint renvoie un code de statut HTTP `200` et une réponse comme ci-dessous.

```json
{
   "status": "ok"
}
```

En cas d'échec, l'endpoint renvoie un code de statut HTTP `503`.

Cette vérification est exemptée de Rack Attack.

## Sidekiq {#sidekiq}

Découvrez comment configurer les [vérifications de l'état de santé Sidekiq](../sidekiq/sidekiq_health_check.md).
