---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Keys
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des informations sur les [clés SSH](../user/ssh.md). Les requêtes sur les empreintes de clé de déploiement récupèrent également des informations sur les projets utilisant cette clé.

Si vous utilisez une empreinte SHA256 dans un appel API, vous devez encoder l'empreinte en URL.

## Récupérer un utilisateur par ID de clé SSH {#retrieve-user-by-ssh-key-id}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Récupère des informations sur un utilisateur propriétaire d'une clé SSH spécifiée.

```plaintext
GET /keys/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | entier | Oui      | ID d'une clé SSH. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `created_at`        | string  | Date et heure de création de la clé SSH au format ISO 8601. |
| `expires_at`        | string  | Date et heure d'expiration de la clé SSH au format ISO 8601. |
| `id`                | entier | ID de la clé SSH. |
| `key`               | string  | Contenu de la clé SSH. |
| `last_used_at`      | string  | Date et heure de dernière utilisation de la clé SSH au format ISO 8601. |
| `title`             | string  | Titre de la clé SSH. |
| `usage_type`        | string  | Type d'utilisation de la clé SSH (par exemple, `auth` ou `auth_and_signing`). |
| `user`              | objet  | Utilisateur associé à la clé SSH. |
| `user.avatar_url`   | string  | URL de l'avatar de l'utilisateur. |
| `user.bio`          | string  | Biographie de l'utilisateur. |
| `user.created_at`   | string  | Date et heure de création du compte utilisateur au format ISO 8601. |
| `user.id`           | entier | ID de l'utilisateur. |
| `user.linkedin`     | string  | URL du profil LinkedIn de l'utilisateur. |
| `user.location`     | string  | Localisation de l'utilisateur. |
| `user.name`         | string  | Nom de l'utilisateur. |
| `user.organization` | string  | Organisation de l'utilisateur. |
| `user.public_email` | string  | Adresse e-mail publique de l'utilisateur. |
| `user.state`        | string  | État de l'utilisateur. |
| `user.twitter`      | string  | URL du profil Twitter de l'utilisateur. |
| `user.username`     | string  | Nom d'utilisateur de l'utilisateur. |
| `user.web_url`      | string  | URL du profil de l'utilisateur. |
| `user.website_url`  | string  | URL du site Web de l'utilisateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Sample key 25",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2015-09-03T07:24:44.627Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "name": "John Smith",
    "username": "john_smith",
    "id": 25,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/cfa35b8cd2ec278026357769582fa563?s=40\u0026d=identicon",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2015-09-03T07:24:01.670Z",
    "bio": null,
    "location": null,
    "public_email": "john@example.com",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2015-09-03T07:24:01.670Z",
    "confirmed_at": "2015-09-03T07:24:01.670Z",
    "last_activity_on": "2015-09-03",
    "email": "john@example.com",
    "theme_id": 2,
    "color_scheme_id": 1,
    "projects_limit": 10,
    "current_sign_in_at": null,
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": null
  }
}
```

## Récupérer un utilisateur par empreinte de clé SSH {#retrieve-user-by-ssh-key-fingerprint}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Récupère des informations sur un utilisateur propriétaire d'une clé SSH spécifiée.

```plaintext
GET /keys
```

Attributs pris en charge :

| Attribut     | Type   | Obligatoire | Description                    |
|---------------|--------|----------|--------------------------------|
| `fingerprint` | string | Oui      | Empreinte d'une clé SSH. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                 | Type    | Description |
|---------------------------|---------|-------------|
| `created_at`              | string  | Date et heure de création de la clé SSH au format ISO 8601. |
| `expires_at`              | string  | Date et heure d'expiration de la clé SSH au format ISO 8601. |
| `id`                      | entier | ID de la clé SSH. |
| `key`                     | string  | Contenu de la clé SSH. |
| `last_used_at`            | string  | Date et heure de dernière utilisation de la clé SSH au format ISO 8601. |
| `title`                   | string  | Titre de la clé SSH. |
| `usage_type`              | string  | Type d'utilisation de la clé SSH (par exemple, `auth` ou `auth_and_signing`). |
| `user`                    | objet  | Utilisateur associé à la clé SSH. |
| `user.avatar_url`         | string  | URL de l'avatar de l'utilisateur. |
| `user.bio`                | string  | Biographie de l'utilisateur. |
| `user.can_create_group`   | boolean | Si `true`, l'utilisateur peut créer des groupes. |
| `user.can_create_project` | boolean | Si `true`, l'utilisateur peut créer des projets. |
| `user.color_scheme_id`    | entier | ID du jeu de couleurs de l'utilisateur. |
| `user.confirmed_at`       | string  | Date et heure de confirmation de l'utilisateur au format ISO 8601. |
| `user.created_at`         | string  | Date et heure de création du compte utilisateur au format ISO 8601. |
| `user.current_sign_in_at` | string  | Date et heure de connexion actuelle de l'utilisateur au format ISO 8601. |
| `user.email`              | string  | Adresse e-mail de l'utilisateur. |
| `user.external`           | boolean | Si `true`, l'utilisateur est externe. |
| `user.id`                 | entier | ID de l'utilisateur. |
| `user.identities`         | tableau   | Identités associées à l'utilisateur. |
| `user.last_activity_on`   | string  | Date de dernière activité de l'utilisateur. |
| `user.last_sign_in_at`    | string  | Date et heure de dernière connexion de l'utilisateur au format ISO 8601. |
| `user.linkedin`           | string  | URL du profil LinkedIn de l'utilisateur. |
| `user.location`           | string  | Localisation de l'utilisateur. |
| `user.name`               | string  | Nom de l'utilisateur. |
| `user.organization`       | string  | Organisation de l'utilisateur. |
| `user.private_profile`    | boolean | Si `true`, le profil de l'utilisateur est privé. |
| `user.projects_limit`     | entier | Limite de projets de l'utilisateur. |
| `user.public_email`       | string  | Adresse e-mail publique de l'utilisateur. |
| `user.state`              | string  | État du compte utilisateur. |
| `user.theme_id`           | entier | ID de thème de l'utilisateur. |
| `user.twitter`            | string  | URL du profil Twitter de l'utilisateur. |
| `user.two_factor_enabled` | boolean | Si `true`, l'authentification à deux facteurs est activée pour l'utilisateur. |
| `user.username`           | string  | Nom d'utilisateur de l'utilisateur. |
| `user.web_url`            | string  | URL du profil de l'utilisateur. |
| `user.website_url`        | string  | URL du site Web de l'utilisateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  }
}
```

## Récupérer un utilisateur par empreinte de clé de déploiement {#retrieve-user-by-deploy-key-fingerprint}

Récupère des informations sur un utilisateur et les projets utilisant une empreinte de clé de déploiement spécifiée. Les clés de déploiement sont liées à l'utilisateur qui les a créées.

```plaintext
GET /keys
```

Attributs pris en charge :

| Attribut     | Type   | Obligatoire | Description                        |
|---------------|--------|----------|------------------------------------|
| `fingerprint` | string | Oui      | Empreinte d'une clé de déploiement.   |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                 | Type    | Description |
|-------------------------------------------|---------|-------------|
| `created_at`                              | string  | Date et heure de création de la clé de déploiement au format ISO 8601. |
| `deploy_keys_projects`                    | tableau   | Informations sur les projets de la clé de déploiement. |
| `deploy_keys_projects[].can_push`         | boolean | Si `true`, la clé de déploiement peut pousser vers le projet. |
| `deploy_keys_projects[].created_at`       | string  | Date et heure de création au format ISO 8601. |
| `deploy_keys_projects[].deploy_key_id`    | entier | ID de la clé de déploiement. |
| `deploy_keys_projects[].id`               | entier | ID de la relation entre la clé de déploiement et le projet. |
| `deploy_keys_projects[].project_id`       | entier | ID du projet. |
| `deploy_keys_projects[].updated_at`       | string  | Date et heure de dernière mise à jour au format ISO 8601. |
| `expires_at`                              | string  | Date et heure d'expiration de la clé de déploiement au format ISO 8601. |
| `id`                                      | entier | ID de la clé de déploiement. |
| `key`                                     | string  | Contenu de la clé de déploiement. |
| `last_used_at`                            | string  | Date et heure de dernière utilisation de la clé de déploiement au format ISO 8601. |
| `title`                                   | string  | Titre de la clé de déploiement. |
| `usage_type`                              | string  | Type d'utilisation de la clé de déploiement (par exemple, `auth` ou `auth_and_signing`). |
| `user`                                    | objet  | Utilisateur associé à la clé de déploiement. |
| `user.avatar_url`                         | string  | URL de l'avatar de l'utilisateur. |
| `user.bio`                                | string  | Biographie de l'utilisateur. |
| `user.can_create_group`                   | boolean | Si `true`, l'utilisateur peut créer des groupes. |
| `user.can_create_project`                 | boolean | Si `true`, l'utilisateur peut créer des projets. |
| `user.color_scheme_id`                    | entier | ID du jeu de couleurs de l'utilisateur. |
| `user.confirmed_at`                       | string  | Date et heure de confirmation de l'utilisateur au format ISO 8601. |
| `user.created_at`                         | string  | Date et heure de création du compte utilisateur au format ISO 8601. |
| `user.current_sign_in_at`                 | string  | Date et heure de connexion actuelle de l'utilisateur au format ISO 8601. |
| `user.email`                              | string  | Adresse e-mail de l'utilisateur. |
| `user.external`                           | boolean | Si `true`, l'utilisateur est externe. |
| `user.extra_shared_runners_minutes_limit` | entier | Limite de minutes de runners partagés supplémentaires de l'utilisateur. |
| `user.id`                                 | entier | ID de l'utilisateur. |
| `user.identities`                         | tableau   | Identités associées à l'utilisateur. |
| `user.last_activity_on`                   | string  | Date de dernière activité de l'utilisateur. |
| `user.last_sign_in_at`                    | string  | Date et heure de dernière connexion de l'utilisateur au format ISO 8601. |
| `user.linkedin`                           | string  | URL du profil LinkedIn de l'utilisateur. |
| `user.location`                           | string  | Localisation de l'utilisateur. |
| `user.name`                               | string  | Nom de l'utilisateur. |
| `user.organization`                       | string  | Organisation de l'utilisateur. |
| `user.private_profile`                    | boolean | Si `true`, le profil de l'utilisateur est privé. |
| `user.projects_limit`                     | entier | Limite de projets de l'utilisateur. |
| `user.public_email`                       | string  | Adresse e-mail publique de l'utilisateur. |
| `user.shared_runners_minutes_limit`       | entier | Limite de minutes de runners partagés de l'utilisateur. |
| `user.state`                              | string  | État du compte utilisateur. |
| `user.theme_id`                           | entier | ID de thème de l'utilisateur. |
| `user.twitter`                            | string  | URL du profil Twitter de l'utilisateur. |
| `user.two_factor_enabled`                 | boolean | Si `true`, l'authentification à deux facteurs est activée pour l'utilisateur. |
| `user.username`                           | string  | Nom d'utilisateur de l'utilisateur. |
| `user.web_url`                            | string  | URL du profil de l'utilisateur. |
| `user.website_url`                        | string  | URL du site Web de l'utilisateur. |

Exemple de requête avec empreinte MD5 :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

Exemple de requête avec empreinte SHA256 (encodée en URL) :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=SHA256%3AnUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo%2FlCg"
```

Dans l'exemple SHA256, `/` est représenté par `%2F` et `:` est représenté par `%3A`.

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  "deploy_keys_projects": [
    {
      "id": 1,
      "deploy_key_id": 1,
      "project_id": 1,
      "created_at": "2020-01-09T07:32:52.453Z",
      "updated_at": "2020-01-09T07:32:52.453Z",
      "can_push": false
    }
  ]
}
```
