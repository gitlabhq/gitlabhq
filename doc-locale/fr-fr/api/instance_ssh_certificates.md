---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des certificats SSH d'instance"
description: "API REST pour lister, ajouter et supprimer les clés publiques d'autorité de certification SSH d'instance."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/611314) dans GitLab 19.5 [avec un feature flag](../administration/feature_flags/_index.md) nommé `instance_ssh_certificates`. Fonctionnalité désactivée par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Utilisez cette API pour gérer les clés publiques d'autorité de certification (CA) SSH auxquelles une instance fait confiance. GitLab stocke chaque clé publique de CA dans la base de données et lui fait confiance à l'échelle de l'instance, ce qui vous permet de faire une rotation de CA via un appel d'API plutôt qu'en modifiant `sshd_config` ou le fichier de configuration `gitlab-sshd`. Pour les alternatives basées sur des fichiers, consultez [les certificats SSH au niveau de l'instance avec `gitlab-sshd`](../administration/operations/gitlab_sshd_ssh_certificates.md).

L'attribut `key` contient une clé publique de CA, et non une clé privée ou un certificat utilisateur signé.

## Authentification et disponibilité {#authentication-and-availability}

Tous les endpoints nécessitent une authentification administrateur via l'[API REST](rest/authentication.md). Si le mode Admin est activé pour l'instance, les [exigences du mode Admin](../administration/settings/sign_in_restrictions.md#admin-mode) existantes s'appliquent, notamment la portée `admin_mode` pour les jetons d'accès personnels ou les jetons OAuth.

GitLab vérifie l'authentification et l'accès administrateur avant la disponibilité des fonctionnalités. Les erreurs suivantes s'appliquent à tous les endpoints, même lorsque le feature flag est désactivé :

| Statut | Description |
|--------|-------------|
| `401 Unauthorized` | La requête n'est pas authentifiée. |
| `403 Forbidden` | L'utilisateur authentifié ne dispose pas des droits d'administrateur. |
| `404 Not Found` | L'utilisateur dispose des droits d'administrateur, mais la fonctionnalité n'est pas disponible. |

## Lister tous les certificats SSH d'instance {#list-all-instance-ssh-certificates}

Liste tous les enregistrements de clés publiques de CA SSH d'instance par ordre d'ID décroissant.

```plaintext
GET /admin/ssh_certificates
```

Cet endpoint prend en charge la [pagination](rest/_index.md#offset-based-pagination) standard.

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `page` | Entier | Non | Page à récupérer. Par défaut : `1`. |
| `per_page` | Entier | Non | Nombre d'enregistrements par page. Par défaut : `20`. Maximum : `100`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et un tableau d'objets avec les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `created_at` | Chaîne | Date et heure de création de l'enregistrement, au format ISO 8601. |
| `fingerprint` | Chaîne | Empreinte SHA256 de la clé publique de CA SSH. |
| `id` | Entier | ID de l'enregistrement du certificat SSH d'instance. |
| `key` | Chaîne | Clé publique de CA SSH. |
| `title` | Chaîne | Titre de l'enregistrement. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates?page=1&per_page=20"
```

Exemple de réponse (`<ca_public_key>` représente la clé publique de CA SSH complète) :

```json
[
  {
    "id": 2,
    "title": "Engineering CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T12:39:00.172Z"
  },
  {
    "id": 1,
    "title": "Operations CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T11:30:00.000Z"
  }
]
```

Un résultat vide renvoie `[]`.

## Ajouter un certificat SSH d'instance {#add-an-instance-ssh-certificate}

Ajoute un enregistrement de clé publique de CA SSH d'instance.

```plaintext
POST /admin/ssh_certificates
```

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `key` | Chaîne | Oui | Clé publique de CA SSH. Ne doit pas être vide. Maximum : 5 000 caractères. |
| `title` | Chaîne | Oui | Titre de l'enregistrement. Ne doit pas être vide. Maximum : 255 caractères. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `created_at` | Chaîne | Date et heure de création de l'enregistrement, au format ISO 8601. |
| `fingerprint` | Chaîne | Empreinte SHA256 de la clé publique de CA SSH. |
| `id` | Entier | ID de l'enregistrement du certificat SSH d'instance. |
| `key` | Chaîne | Clé publique de CA SSH. |
| `title` | Chaîne | Titre de l'enregistrement. |

Exemple de requête, avec la clé publique de CA dans `/path/to/ca_key.pub` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Engineering CA" \
  --data-urlencode "key@/path/to/ca_key.pub" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Engineering CA",
  "key": "<ca_public_key>",
  "fingerprint": "<ca_public_key_fingerprint>",
  "created_at": "2026-09-08T12:39:00.172Z"
}
```

En plus des erreurs d'authentification et de disponibilité partagées, cet endpoint peut renvoyer :

| Statut | Description |
|--------|-------------|
| `400 Bad Request` | Un paramètre obligatoire est manquant, ou `title` ou `key` dépasse sa longueur maximale. |
| `422 Unprocessable Entity` | Une valeur est vide ou invalide. Également renvoyé pour une empreinte de clé dupliquée, ou pour une clé rejetée par les [restrictions de clés SSH](../security/ssh_keys_restrictions.md) ou les restrictions FIPS (Federal Information Processing Standards). |

## Supprimer un certificat SSH d'instance {#delete-an-instance-ssh-certificate}

Supprime un enregistrement de clé publique de CA SSH d'instance spécifié.

```plaintext
DELETE /admin/ssh_certificates/:id
```

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `id` | Entier | Oui | ID de l'enregistrement du certificat SSH d'instance. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes) avec un corps de réponse vide et aucun attribut de réponse.

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates/2"
```

En plus des erreurs d'authentification et de disponibilité partagées, cet endpoint peut renvoyer :

| Statut | Description |
|--------|-------------|
| `404 Not Found` | Aucun enregistrement de certificat SSH d'instance ne correspond à l'ID spécifié. |
| `422 Unprocessable Entity` | GitLab n'a pas pu supprimer l'enregistrement. |
