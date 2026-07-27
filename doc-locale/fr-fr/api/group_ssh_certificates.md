---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des certificats SSH de groupe
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421915) dans GitLab 16.4 [avec un indicateur](../administration/feature_flags/_index.md) nommé `ssh_certificates_rest_endpoints`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) dans GitLab 16.9.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) dans GitLab 17.7. L'indicateur de fonctionnalité `ssh_certificates_rest_endpoints` a été supprimé.

{{< /history >}}

Utilisez cette API pour gérer les [certificats SSH pour les groupes](../user/group/ssh_certificates.md). Seuls les groupes principaux peuvent stocker des certificats SSH.

Prérequis :

- Vous devez être Propriétaire d'un groupe principal.

## Lister tous les certificats SSH de groupe {#list-all-group-ssh-certificates}

Liste tous les certificats SSH pour un groupe spécifié.

```plaintext
GET /groups/:id/ssh_certificates
```

Paramètres :

| Attribut  | Type   | Obligatoire | Description          |
| ---------- | ------ | -------- |----------------------|
| `id`      | entier | Oui       | L'identifiant du groupe. |

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API REST sont paginés. En savoir plus sur la [pagination](rest/_index.md#pagination).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/90/ssh_certificates"
```

Exemple de réponse :

```json
[
  {
    "id": 12345,
    "title": "SSH Title 1",
    "key": "ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.172Z"
  },
  {
    "id":12346,
    "title":"SSH Title 2",
    "key": "ssh-rsa AAAAB3NzaC1ac2EAAAADAQABAAAAgQDTl/hHfu1F/KlR+QfgM2wUmyxcN5YeiaWluEGIrfXUeJuI+bK6xjpE3+2afHDYtE9VQkeL32KRjefX2d72Jeoa68ewt87Vn8CcGkUTOTpHNzeL8pHMKFs3m7ArSBxNg5vTdgAsq5dbDGNtat7b2WCHTNvtWoON1Jetne30uW2EwQ== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.244Z"
  }
]
```

## Ajouter un certificat SSH de groupe {#add-a-group-ssh-certificate}

Ajoute un certificat SSH de groupe pour un groupe spécifié.

```plaintext
POST /groups/:id/ssh_certificates
```

Paramètres :

| Attribut | Type       | Obligatoire | Description                           |
|-----------|------------| -------- |---------------------------------------|
| `id`      | entier    | Oui       | L'identifiant du groupe.                  |
| `key`     | string     | Oui       | La clé publique du certificat SSH.|
| `title`   | string     | Oui       | Le titre du certificat SSH.     |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates?title=newtitle&key=ssh-rsa+REDACTED+example%40gitlab.com"
```

Exemple de réponse :

```json
{
  "id": 54321,
  "title": "newtitle",
  "key": "ssh-rsa ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
  "created_at": "2023-09-08T12:39:00.172Z"
}
```

## Supprimer un certificat SSH de groupe {#delete-a-group-ssh-certificate}

Supprime un certificat SSH de groupe spécifié.

```plaintext
DELETE /groups/:id/ssh_certificates/:id
```

Paramètres :

| Attribut | Type    | Obligatoire | Description                   |
|-----------|---------| -------- |-------------------------------|
| `id`      | entier | Oui       | L'identifiant du groupe           |
| `id`      | entier | Oui       | L'identifiant du certificat SSH |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates/12345"
```
