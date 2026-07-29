---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Chemins protégés
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La limite de débit est une technique qui améliore la sécurité et la durabilité d'une application web. Pour plus de détails, consultez [Limites de débit](../../security/rate_limits.md).

Vous pouvez limiter le débit (protéger) des chemins spécifiés. Pour ces chemins, GitLab répond avec le code de statut HTTP `429` aux requêtes POST dépassant 10 requêtes par minute par adresse IP et aux requêtes GET dépassant 10 requêtes par minute par adresse IP sur les chemins protégés.

Par exemple, les éléments suivants sont limités à un maximum de 10 requêtes par minute :

- Connexion de l'utilisateur
- Création d'un nouveau compte utilisateur (si activée)
- Réinitialisation du mot de passe utilisateur

Après 10 requêtes, le client doit attendre 60 secondes avant de pouvoir réessayer.

Voir aussi :

- Liste des chemins [protégés par défaut](../instance_limits.md#by-protected-path).
- [Limites de débit des utilisateurs et des adresses IP](user_and_ip_rate_limits.md#response-headers) pour les en-têtes renvoyés aux requêtes bloquées.

## Configurer les chemins protégés {#configure-protected-paths}

La limitation du débit des chemins protégés est activée par défaut et peut être désactivée ou personnalisée.

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Chemins protégés**.

Les requêtes dépassant la limite de débit sont enregistrées dans `auth.log`.
