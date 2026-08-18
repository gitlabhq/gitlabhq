---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Crochets système
description: "Utilisez les crochets système pour déclencher des requêtes HTTP POST à partir d'événements GitLab. Inclut des exemples de charge utile JSON."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les crochets système envoient des requêtes HTTP POST à des URL externes ou exécutent des scripts locaux sur le serveur lorsque des événements spécifiques se produisent.

Contrairement aux webhooks de projet, les crochets système surveillent les événements sur l'ensemble de l'instance GitLab, pas seulement les projets individuels. Ces crochets capturent des événements tels que la création d'utilisateurs, les modifications de projets et de groupes, et les poussées vers le dépôt depuis n'importe quel projet.

## Événements déclenchés {#triggered-events}

| Type d'événement                                | Déclencheur |
|-------------------------------------------|---------|
| `group_create`                            | Un groupe est créé. |
| `group_destroy`                           | Un groupe est supprimé. |
| `group_rename`                            | Le chemin ou le nom d'un groupe change. |
| `key_create`                              | Une clé SSH est créée. |
| `key_destroy`                             | Une clé SSH est supprimée. |
| `project_create`                          | Un projet est créé. |
| `project_destroy`                         | Un projet est supprimé. |
| `project_rename`                          | Le chemin ou le nom d'un projet change. |
| `project_transfer`                        | Un projet est transféré vers un nouvel espace de nommage. |
| `project_update`                          | Les attributs du projet changent (sauf le chemin du projet). |
| `repository_update`                       | Une poussée inclut des étiquettes ou plusieurs branches. |
| `user_access_request_revoked_for_group`   | La demande d'accès d'un utilisateur à un groupe est annulée. |
| `user_access_request_revoked_for_project` | La demande d'accès d'un utilisateur à un projet est annulée. |
| `user_access_request_to_group`            | Un utilisateur demande l'accès à un groupe. |
| `user_access_request_to_project`          | Un utilisateur demande l'accès à un projet. |
| `user_add_to_group`                       | Un utilisateur est ajouté en tant que membre d'un groupe. |
| `user_add_to_team`                        | Un utilisateur est ajouté en tant que membre d'un projet. |
| `user_create`                             | Un compte utilisateur est créé. |
| `user_destroy`                            | Un compte utilisateur est supprimé. |
| `user_failed_login`                       | Un utilisateur bloqué tente de se connecter. |
| `user_remove_from_group`                  | Un utilisateur est supprimé d'un groupe. |
| `user_remove_from_team`                   | Un utilisateur est supprimé d'un projet. |
| `user_rename`                             | Le nom d'utilisateur d'un utilisateur change. |
| `user_update_for_group`                   | Le rôle d'un membre du groupe change. |
| `user_update_for_team`                    | Le rôle d'un membre du projet change. |
| `gitlab_subscription_member_approval`     | La promotion de rôle est demandée (`"action": "enqueue"`). |
| `gitlab_subscription_member_approvals`    | La promotion de rôle est approuvée (`"action": "approve"`) ou refusée (`"action": "deny"`). |
| `push`                                    | Une poussée est effectuée vers le dépôt (sauf les étiquettes). |
| `tag_push`                                | Une étiquette est ajoutée ou supprimée. |
| `merge_request`                           | Un merge request est créé, mis à jour, fusionné ou fermé. |

> [!note]
> Pour les événements de poussée et d'étiquette, la même structure et les mêmes dépréciations sont suivies que pour les [webhooks de projet et de groupe](../user/project/integrations/webhooks.md). Cependant, les commits ne sont jamais affichés.

## Créer un crochet système {#create-a-system-hook}

{{< history >}}

- Les zones de texte **Nom** et **Description** ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977) dans GitLab 16.9.
- Les zones de texte **Masquage d'URL**, **En-têtes personnalisés** et **Modèle de webhook personnalisé** ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/503457) dans GitLab 19.0.

{{< /history >}}

Prérequis :

- Accès administrateur.

Pour créer un crochet système :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Crochets système**.
1. Sélectionnez **Ajouter un nouveau crochet Web**.
1. Dans **URL**, saisissez l'URL du point de terminaison du webhook. Utilisez l'encodage en pourcentage pour les caractères spéciaux.
1. Facultatif. Dans la zone de texte **Nom**, saisissez un nom pour le webhook.
1. Facultatif. Dans la zone de texte **Description**, saisissez une description pour le webhook.
1. Facultatif. Dans la zone de texte **Jeton secret**, saisissez un jeton secret pour valider les requêtes.

   Le jeton est envoyé avec la requête du webhook dans l'en-tête HTTP `X-Gitlab-Token`. Votre point de terminaison de webhook peut utiliser ce jeton pour vérifier la légitimité de la requête.

1. Facultatif. Pour masquer les parties sensibles de l'URL, sélectionnez **Ajouter le masquage d'URL**. Pour plus d'informations, consultez [masquer les parties sensibles des URL des crochets système](#mask-sensitive-portions-of-system-hook-urls).
1. Facultatif. Pour ajouter des en-têtes d'authentification pour les services externes, sélectionnez **Ajouter un en-tête personnalisé**. Pour plus d'informations, consultez [en-têtes personnalisés](#custom-headers).
1. Dans la section **Déclencheur**, cochez la case pour chaque [événement](#optional-triggers) GitLab que vous souhaitez déclencher avec le crochet.
1. Facultatif. Définissez un **modèle de webhook personnalisé** pour contrôler le corps de la requête. Pour plus d'informations, consultez [modèle de webhook personnalisé](#custom-webhook-template).
1. Facultatif. Décochez la case **Activer la vérification SSL** pour désactiver la [vérification SSL](../user/project/integrations/_index.md#ssl-verification).
1. Sélectionnez **Ajouter un crochet  système**.

### Masquer les parties sensibles des URL des crochets système {#mask-sensitive-portions-of-system-hook-urls}

Le masquage des parties sensibles des URL pour les crochets système fonctionne de la même manière que pour les webhooks de projet et de groupe. Les parties masquées des URL sont :

- Remplacées par des valeurs configurées lors de l'exécution des crochets.
- Non enregistrées.
- Chiffrées au repos dans la base de données.

Pour plus d'informations sur la configuration, consultez la documentation sur les projets et groupes pour [masquer les parties sensibles des URL de webhook](../user/project/integrations/webhooks.md#mask-sensitive-portions-of-webhook-urls).

### En-têtes personnalisés {#custom-headers}

Les en-têtes personnalisés pour les crochets système fonctionnent de la même manière que pour les webhooks de projet et de groupe. Vous pouvez configurer jusqu'à 20 en-têtes personnalisés par crochet. Les en-têtes personnalisés sont affichés dans **Événements récents** avec des valeurs masquées.

Pour les exigences relatives aux en-têtes, consultez la documentation sur les projets et groupes pour [les en-têtes personnalisés](../user/project/integrations/webhooks.md#custom-headers).

### Déclencheurs facultatifs {#optional-triggers}

Les crochets système se déclenchent automatiquement sur les [événements pris en charge](#triggered-events), tels que les modifications du cycle de vie des utilisateurs et des groupes. Vous pouvez également activer ces déclencheurs facultatifs :

| Déclencheur                      | Description |
|:-----------------------------|:------------|
| **Événements de mise à jour du dépôt** | Une poussée qui inclut des étiquettes ou plusieurs branches. |
| **Événements poussés**              | Une poussée vers n'importe quelle branche. |
| **Événements en lien avec les poussées d'étiquette**          | Une étiquette est ajoutée ou supprimée. |
| **Événements en lien avec les requêtes de fusion**     | Un merge request est créé, mis à jour, fusionné ou fermé. |

#### Filtrer les événements de poussée par branche {#filter-push-events-by-branch}

Le filtrage des événements de poussée par branche fonctionne de la même manière que pour les webhooks de projet et de groupe. Pour plus d'informations, consultez la documentation sur les projets et groupes pour [filtrer les événements de poussée par branche](../user/project/integrations/webhooks.md#filter-push-events-by-branch).

### Modèle de webhook personnalisé {#custom-webhook-template}

Les modèles de webhook personnalisés fonctionnent de la même manière que pour les webhooks de projet et de groupe. Pour l'utilisation et des exemples, consultez la documentation sur les projets et groupes pour [le modèle de webhook personnalisé](../user/project/integrations/webhooks.md#custom-webhook-template).

## Limites des crochets système {#system-hook-limits}

Les crochets système sont soumis aux mêmes limites d'événements de poussée que les webhooks de projet. Par défaut, les crochets système ne sont pas déclenchés lorsqu'une seule poussée comprend plus de 3 branches ou étiquettes.

Cette limite est contrôlée par le paramètre `push_event_hooks_limit` (par défaut : `3`). Pour les instances GitLab Self-Managed, les administrateurs peuvent modifier cette limite à l'aide de l'[API des paramètres d'application](../api/settings.md#available-settings).

## Exemple de requête de crochet {#hooks-request-example}

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

Projet créé :

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_create",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

Projet supprimé :

```json
{
            "created_at": "2012-07-21T07:30:58Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_destroy",
                  "name": "Underscore",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "underscore",
   "path_with_namespace": "jsmith/underscore",
            "project_id": 73,
 "project_namespace_id" : 23,
    "project_visibility": "internal"
}
```

Projet renommé :

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_rename",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "jsmith/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

`project_rename` n'est pas déclenché si l'espace de nommage change. Reportez-vous à `group_rename` et `user_rename` dans ce cas.

Projet transféré :

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_transfer",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "scores/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

Projet mis à jour :

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_update",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

Demande d'accès pour le groupe supprimée :

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_revoked_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

Demande d'accès pour le projet supprimée :

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_revoked_for_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

Demande d'accès pour le groupe créée :

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

Demande d'accès pour le projet créée :

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_to_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

Nouveau membre de l'équipe :

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_add_to_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

Membre de l'équipe supprimé :

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_remove_from_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

Membre de l'équipe mis à jour :

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_update_for_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

Utilisateur créé :

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_create",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

Utilisateur supprimé :

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_destroy",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

Échec de connexion de l'utilisateur :

```json
{
  "event_name": "user_failed_login",
  "created_at": "2017-10-03T06:08:48Z",
  "updated_at": "2018-01-15T04:52:06Z",
        "name": "John Smith",
       "email": "user4@example.com",
     "user_id": 26,
    "username": "user4",
       "state": "blocked"
}
```

Si l'utilisateur est bloqué via LDAP, `state` est `ldap_blocked`.

Utilisateur renommé :

```json
{
    "event_name": "user_rename",
    "created_at": "2017-11-01T11:21:04Z",
    "updated_at": "2017-11-01T14:04:47Z",
          "name": "new-name",
         "email": "best-email@example.tld",
       "user_id": 58,
      "username": "new-exciting-name",
  "old_username": "old-boring-name"
}
```

Clé ajoutée :

```json
{
    "event_name": "key_create",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
           "id": 4
}
```

Clé supprimée :

```json
{
    "event_name": "key_destroy",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
            "id": 4
}
```

Groupe créé :

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_create",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

Groupe supprimé :

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_destroy",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

Groupe renommé :

```json
{
     "event_name": "group_rename",
     "created_at": "2017-10-30T15:09:00Z",
     "updated_at": "2017-11-01T10:23:52Z",
           "name": "Better Name",
           "path": "better-name",
      "full_path": "parent-group/better-name",
       "group_id": 64,
       "old_path": "old-name",
  "old_full_path": "parent-group/old-name"
}
```

Nouveau membre du groupe :

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_add_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

Membre du groupe supprimé :

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_remove_from_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

Membre du groupe mis à jour :

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_update_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

## Événements poussés {#push-events}

Déclenché lorsque vous poussez vers le dépôt, sauf lors de la poussée d'étiquettes. Il génère un événement par branche modifiée.

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

Corps de la requête :

```json
{
  "event_name": "push",
  "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
  "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "ref": "refs/heads/master",
  "checkout_sha": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "user_id": 4,
  "user_name": "John Smith",
  "user_email": "john@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 15,
  "project":{
    "name":"Diaspora",
    "description":"",
    "web_url":"http://example.com/mike/diaspora",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "namespace":"Mike",
    "visibility_level":0,
    "path_with_namespace":"mike/diaspora",
    "default_branch":"master",
    "homepage":"http://example.com/mike/diaspora",
    "url":"git@example.com:mike/diaspora.git",
    "ssh_url":"git@example.com:mike/diaspora.git",
    "http_url":"http://example.com/mike/diaspora.git"
  },
  "repository":{
    "name": "Diaspora",
    "url": "git@example.com:mike/diaspora.git",
    "description": "",
    "homepage": "http://example.com/mike/diaspora",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "visibility_level":0
  },
  "commits": [
    {
      "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "message": "Add simple search to projects in public area",
      "timestamp": "2013-05-13T18:18:08+00:00",
      "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "author": {
        "name": "Example User",
        "email": "user@example.com"
      }
    }
  ],
  "total_commits_count": 1
}
```

## Événements d'étiquette {#tag-events}

Déclenché lorsque vous créez (ou supprimez) des étiquettes dans le dépôt. Il génère un événement par étiquette modifiée.

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

Corps de la requête :

```json
{
  "event_name": "tag_push",
  "before": "0000000000000000000000000000000000000000",
  "after": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "ref": "refs/tags/v1.0.0",
  "checkout_sha": "5937ac0a7beb003549fc5fd26fc247adbce4a52e",
  "user_id": 1,
  "user_name": "John Smith",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project":{
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "repository":{
    "name": "Example",
    "url": "ssh://git@example.com/jsmith/example.git",
    "description": "",
    "homepage": "http://example.com/jsmith/example",
    "git_http_url":"http://example.com/jsmith/example.git",
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "visibility_level":0
  },
  "commits": [],
  "total_commits_count": 0
}
```

## Événements en lien avec les requêtes de fusion {#merge-request-events}

Déclenché lorsqu'un nouveau merge request est créé, qu'un merge request existant est mis à jour/fusionné/fermé ou qu'un commit est ajouté dans la branche source.

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project": {
    "id": 1,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "repository": {
    "name": "Gitlab Test",
    "url": "http://example.com/gitlabhq/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlabhq/gitlab-test"
  },
  "object_attributes": {
    "id": 99,
    "target_branch": "master",
    "source_branch": "ms-viewport",
    "source_project_id": 14,
    "author_id": 51,
    "assignee_id": 6,
    "title": "MS-Viewport",
    "created_at": "2013-12-03T17:23:34Z",
    "updated_at": "2013-12-03T17:23:34Z",
    "milestone_id": null,
    "state": "opened",
    "merge_status": "unchecked",
    "target_project_id": 14,
    "iid": 1,
    "description": "",
    "source": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "target": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "last_commit": {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/awesome_space/awesome_project/commits/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      }
    },
    "work_in_progress": false,
    "url": "http://example.com/diaspora/merge_requests/1",
    "action": "open",
    "assignee": {
      "name": "User1",
      "username": "user1",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
    }
  },
  "labels": [{
    "id": 206,
    "title": "API",
    "color": "#ffffff",
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "template": false,
    "description": "API related issues",
    "type": "ProjectLabel",
    "group_id": 41
  }],
  "changes": {
    "updated_by_id": {
      "previous": null,
      "current": 1
    },
    "updated_at": {
      "previous": "2017-09-15 16:50:55 UTC",
      "current":"2017-09-15 16:52:00 UTC"
    },
    "labels": {
      "previous": [{
        "id": 206,
        "title": "API",
        "color": "#ffffff",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "API related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }],
      "current": [{
        "id": 205,
        "title": "Platform",
        "color": "#123123",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "Platform related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }]
    }
  }
}
```

## Événements de mise à jour du dépôt {#repository-update-events}

Déclenché une seule fois lorsque vous poussez vers le dépôt (y compris les étiquettes).

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

Corps de la requête :

```json
{
  "event_name": "repository_update",
  "user_id": 1,
  "user_name": "John Smith",
  "user_email": "admin@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project": {
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "changes": [
    {
      "before":"8205ea8d81ce0c6b90fbe8280d118cc9fdad6130",
      "after":"4045ea7a3df38697b3730a20fb73c8bed8a3e69e",
      "ref":"refs/heads/master"
    }
  ],
  "refs":["refs/heads/master"]
}
```

## Événements d'approbation de membre dans l'abonnement {#events-for-member-approval-in-subscription}

Ces événements sont déclenchés si l'[approbation de l'administrateur pour les promotions de rôle](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée.

En-tête de requête :

```plaintext
X-Gitlab-Event: System Hook
```

Membre mis en file d'attente pour la gestion des promotions :

```json
{
  "object_kind": "gitlab_subscription_member_approval",
  "action": "enqueue",
  "object_attributes": {
    "new_access_level": 30,
    "old_access_level": 10,
    "existing_member_id": 123
  },
  "user_id": 42,
  "requested_by_user_id": 99,
  "promotion_namespace_id": 789,
  "created_at": "2025-04-10T14:00:00Z",
  "updated_at": "2025-04-10T14:05:00Z"
}
```

Utilisateur approuvé pour un rôle facturable par l'administrateur de l'instance :

```json
{
  "object_kind": "gitlab_subscription_member_approvals",
  "action": "approve",
  "object_attributes": {
    "promotion_request_ids_that_failed_to_apply": [],
    "status": "success"
  },
  "reviewed_by_user_id": 101,
  "user_id": 42,
  "updated_at": "2025-04-10T14:10:00Z"
}
```

Utilisateur refusé pour un rôle facturable par l'administrateur de l'instance :

```json
{
"object_kind": "gitlab_subscription_member_approvals",
"action": "deny",
"object_attributes": {
"status": "success"
},
"reviewed_by_user_id": 101,
"user_id": 42,
"updated_at": "2025-04-10T14:12:00Z"
}
```

## Requêtes locales dans les crochets système {#local-requests-in-system-hooks}

Les [requêtes vers le réseau local par les crochets système](../security/webhooks.md) peuvent être autorisées ou bloquées par un administrateur.

## Sujets connexes {#related-topics}

- [Crochets serveur](server_hooks.md)
- [Crochets de fichier](file_hooks.md)
