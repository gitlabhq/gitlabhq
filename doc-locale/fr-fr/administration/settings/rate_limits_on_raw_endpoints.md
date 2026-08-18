---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de débit sur les endpoints bruts
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Limite du nombre de demandes de blob brut par minute (non authentifiée) [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/226344) dans GitLab 18.10.

{{< /history >}}

Prérequis :

- Accès administrateur.

Deux paramètres de limite de débit contrôlent l'accès aux endpoints bruts :

- **Limite du nombre de demandes de blob brut par minute** :  Limite les requêtes pour chaque projet et chemin de fichier. Par défaut : `300` requêtes par minute.
- **Raw blob request rate limit per minute (unauthenticated)** :  Limite les requêtes non authentifiées pour chaque projet, sur l'ensemble des chemins de fichiers. Par défaut : `800` requêtes par minute.

Pour configurer ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Optimisation des performances**.

![La limite du nombre de demandes de blob brut par minute définie à 300 et 800.](img/rate_limits_on_raw_endpoints_v18_10.png)

Par exemple, si la limite de débit basée sur le chemin est `300`, les requêtes dépassant `300` par minute vers `https://gitlab.com/gitlab-org/gitlab-foss/raw/master/app/controllers/application_controller.rb` sont bloquées. L'accès au fichier brut est rétabli après 1 minute.

La limite de débit basée sur le chemin est :

- Appliquée indépendamment pour chaque projet et chemin de fichier.
- Non appliquée par adresse IP ou par utilisateur.
- Active par défaut. Pour la désactiver, définissez l'option sur `0`.

La limite de débit non authentifiée à l'échelle du projet est :

- Appliquée pour chaque projet, sur l'ensemble des chemins de fichiers, pour les requêtes non authentifiées uniquement.
- Non appliquée aux utilisateurs authentifiés.
- Non appliquée par adresse IP.
- Active par défaut. Pour la désactiver, définissez l'option sur `0`.

Les requêtes dépassant la limite de débit sont enregistrées dans `auth.log`.
