---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gestion des sièges du module complémentaire GitLab Duo avec LDAP
description: "Automatisez l'attribution et la suppression des sièges du module complémentaire GitLab Duo en synchronisant l'état des sièges avec l'appartenance des utilisateurs aux groupes LDAP spécifiés."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175101) dans GitLab 17.8.

{{< /history >}}

Les administrateurs GitLab peuvent configurer l'attribution automatique des sièges du module complémentaire GitLab Duo en fonction de l'appartenance aux groupes LDAP. Lorsqu'elle est activée, GitLab attribue ou supprime automatiquement les sièges du module complémentaire pour les utilisateurs lorsqu'ils se connectent, en fonction de leur appartenance aux groupes LDAP.

## Workflow de gestion des sièges {#seat-management-workflow}

1. **Configuration** : Les administrateurs spécifient les groupes LDAP dans les `duo_add_on_groups` [paramètres de configuration](#configure-gitlab-duo-add-on-seat-management).
1. **Seat synchronization** : GitLab vérifie les appartenances aux groupes LDAP de deux manières :
   - **On user sign-in** : Lorsqu'un utilisateur se connecte via LDAP, GitLab vérifie immédiatement ses appartenances aux groupes.
   - **Scheduled sync** : GitLab synchronise automatiquement tous les utilisateurs LDAP quotidiennement à 02h00 pour s'assurer que les attributions de sièges sont à jour, même sans connexion des utilisateurs.
1. **Seat assignment** :
   - Si l'utilisateur appartient à un groupe répertorié dans `duo_add_on_groups`, un siège du module complémentaire lui est attribué (s'il n'en a pas déjà un).
   - Si l'utilisateur n'appartient à aucun groupe répertorié, son siège du module complémentaire est supprimé (s'il en avait un précédemment).
1. **Async processing** : L'attribution et la suppression des sièges sont traitées de manière asynchrone afin de ne pas interrompre le flow principal de connexion.

Le diagramme suivant illustre le workflow :

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    accTitle: Workflow of GitLab Duo add-on seat management with LDAP
    accDescr: Sequence diagram showing automatic GitLab Duo add-on seat management based on LDAP group membership. Users sign in, GitLab authenticates them, then enqueues a background job to sync seat assignment based on their group membership.

    participant User
    participant GitLab
    participant LDAP
    participant Background Job

    User->>GitLab: Sign in with LDAP credentials
    GitLab->>LDAP: Authenticate user
    LDAP-->>GitLab: User authenticated
    GitLab->>Background Job: Enqueue 'LdapAddOnSeatSyncWorker' seat sync job
    GitLab-->>User: Sign-in complete
    Background Job->>Background Job: Start
    Background Job->>LDAP: Check user's groups against duo_add_on_groups
    LDAP-->>Background Job: Return membership of groups
    alt User member of any duo_add_on_groups?
        Background Job->>GitLab: Assign Duo Add-on seat
    else User not in duo_add_on_groups
        Background Job->>GitLab: Remove Duo Add-on seat (if assigned)
    end
    Background Job-->>Background Job: Complete

    Note over GitLab, Background Job: Additionally, LdapAllAddOnSeatSyncWorker runs daily at 2 AM to sync all LDAP users
```

## Configurer la gestion des sièges du module complémentaire GitLab Duo {#configure-gitlab-duo-add-on-seat-management}

Pour activer la gestion des sièges du module complémentaire avec LDAP :

1. Ouvrez le fichier de configuration GitLab que vous avez modifié pour l'[installation](auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups).
1. Ajoutez le paramètre `duo_add_on_groups` à la configuration de votre serveur LDAP.
1. Spécifiez un tableau de noms de groupes LDAP devant disposer de sièges du module complémentaire GitLab Duo.

L'exemple suivant est une configuration `gitlab.rb` pour les installations de packages Linux :

```ruby
gitlab_rails['ldap_servers'] = {
  'main' => {
    # Additional LDAP settings removed for readability
    'duo_add_on_groups' => ['duo_users', 'admins'],
  }
}
```
