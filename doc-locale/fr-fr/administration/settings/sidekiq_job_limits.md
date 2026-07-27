---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de taille des jobs Sidekiq
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les jobs [Sidekiq](../sidekiq/_index.md) sont stockés dans Redis. Pour éviter une utilisation excessive de la mémoire pour Redis, nous :

- Compressons les arguments des jobs avant de les stocker dans Redis.
- Rejetons les jobs qui dépassent la limite de seuil spécifiée après compression.

Prérequis :

- Accès administrateur.

Pour accéder aux limites de taille des jobs Sidekiq :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Limites de taille des jobs Sidekiq**.
1. Ajustez le seuil de compression ou la limite de taille. La compression peut être désactivée en sélectionnant le mode **Track**.

## Paramètres disponibles {#available-settings}

| Paramètre                                   | Valeur par défaut          | Description                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Mode de limitation                             | Compress         | Ce mode compresse les jobs au seuil spécifié et les rejette s'ils dépassent la limite spécifiée après compression.                                               |
| Seuil de compression des jobs Sidekiq (octets) | 100 000 (100 Ko) | Lorsque la taille des arguments dépasse ce seuil, ils sont compressés avant d'être stockés dans Redis.                                                                          |
| Limite de taille des jobs Sidekiq (octets)            | 0                | Les jobs dépassant cette taille après compression sont rejetés. Cela évite une utilisation excessive de la mémoire dans Redis, ce qui pourrait entraîner une instabilité. Le régler sur 0 empêche le rejet des jobs.     |

Après avoir modifié ces valeurs, [redémarrez Sidekiq](../restart_gitlab.md).
