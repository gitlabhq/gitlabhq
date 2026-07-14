---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Contrôle de l'état de Sidekiq"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab fournit des sondes de vivacité et de disponibilité pour indiquer l'état de santé du service et son accessibilité au cluster Sidekiq. Ces endpoints [peuvent être fournis aux planificateurs comme Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) pour retenir le trafic jusqu'à ce que le système soit prêt ou redémarrer le conteneur si nécessaire.

Le serveur de contrôle de l'état peut être configuré lors de la [configuration de Sidekiq](_index.md).

## Disponibilité {#readiness}

La sonde de disponibilité vérifie si les workers Sidekiq sont prêts à traiter des jobs.

```plaintext
GET /readiness
```

Si le serveur est lié à `localhost:8092`, le cluster de processus peut être sondé pour vérifier sa disponibilité comme suit :

```shell
curl "http://localhost:8092/readiness"
```

En cas de succès, l'endpoint renvoie un code de statut HTTP `200` et une réponse similaire à la suivante :

```json
{
   "status": "ok"
}
```

## Vivacité {#liveness}

Vérifie si le cluster Sidekiq est en cours d'exécution.

```plaintext
GET /liveness
```

Si le serveur est lié à `localhost:8092`, le cluster de processus peut être sondé pour vérifier sa vivacité comme suit :

```shell
curl "http://localhost:8092/liveness"
```

En cas de succès, l'endpoint renvoie un code de statut HTTP `200` et une réponse similaire à la suivante :

```json
{
   "status": "ok"
}
```
