---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des clés de déploiement
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [clés de déploiement](../user/project/deploy_keys/_index.md).

## Empreintes des clés de déploiement {#deploy-key-fingerprints}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91302) l'attribut `fingerprint_sha256` dans GitLab 15.2.

{{< /history >}}

Certains points de terminaison renvoient des empreintes de clé publique dans la réponse. Vous pouvez utiliser ces empreintes pour identifier l'utilisateur qui a créé la clé de déploiement. Pour plus d'informations, voir [obtenir un utilisateur par empreinte de clé de déploiement](keys.md#retrieve-user-by-deploy-key-fingerprint).

Les attributs suivants contiennent l'empreinte de la clé de déploiement :

- `fingerprint` : Utilise un hachage MD5. Non disponible sur les systèmes compatibles FIPS.
- `fingerprint_sha256` : Utilise un hachage SHA256.

## Lister toutes les clés de déploiement {#list-all-deploy-keys}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `projects_with_readonly_access` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119147) dans GitLab 16.0.

{{< /history >}}

Récupère la liste de toutes les clés de déploiement dans tous les projets de l'instance GitLab. Ce point de terminaison nécessite un accès administrateur et n'est pas disponible sur GitLab.com.

```plaintext
GET /deploy_keys
```

Attributs pris en charge :

| Attribut   | Type     | Obligatoire | Description           |
|:------------|:---------|:---------|:----------------------|
| `public` | boolean | Non | Ne renvoie que les clés de déploiement qui sont publiques. La valeur par défaut est `false`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_keys?public=true"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [
      {
        "id": 73,
        "description": null,
        "name": "project2",
        "name_with_namespace": "Sidney Jones / project2",
        "path": "project2",
        "path_with_namespace": "sidney_jones/project2",
        "created_at": "2021-10-25T18:33:17.550Z"
      },
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ],
    "projects_with_readonly_access": []
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [],
    "projects_with_readonly_access": [
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ]
  }
]
```

## Ajouter une clé de déploiement {#add-deploy-key}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/478476) dans GitLab 17.5.

{{< /history >}}

Crée une clé de déploiement pour l'instance GitLab. Ce point de terminaison nécessite un accès administrateur.

```plaintext
POST /deploy_keys
```

Attributs pris en charge :

| Attribut     | Type     | Obligatoire | Description                                                                                                                       |
|:--------------|:---------|:---------|:----------------------------------------------------------------------------------------------------------------------------------|
| `key`         | string   | oui      | Nouvelle clé de déploiement                                                                                                                    |
| `title`       | string   | oui      | Titre de la nouvelle clé de déploiement                                                                                                            |
| `expires_at`  | datetime | non       | Date d'expiration de la clé de déploiement. N'expire pas si aucune valeur n'est fournie. Format ISO 8601 attendu (`2024-12-31T08:00:00Z`) |

Exemple de requête :

```shell
curl --request POST \ --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "expired_at": "2024-12-31T08:00:00Z"}" \
     --url "https://gitlab.example.com/api/v4/deploy_keys/"
```

Exemple de réponse :

```json
{
  "id": 5,
  "title": "My deploy key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "usage_type": "auth_and_signing",
  "created_at": "2024-10-03T01:32:21.992Z",
  "expires_at": "2024-12-31T08:00:00.000Z"
}
```

## Lister les clés de déploiement d'un projet {#list-deploy-keys-for-project}

Récupère la liste des clés de déploiement d'un projet.

```plaintext
GET /projects/:id/deploy_keys
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "can_push": false
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "can_push": false
  }
]
```

## Lister les clés de déploiement de projet pour un utilisateur {#list-project-deploy-keys-for-user}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88917) dans GitLab 15.1.

{{< /history >}}

Récupère la liste des [clés de déploiement de projet](../user/project/deploy_keys/_index.md#scope) communes à un utilisateur spécifié (destinataire) et à l'utilisateur authentifié (demandeur). Elle répertorie uniquement les **clés de projet activées issues des projets communs au demandeur et au destinataire de la demande**.

```plaintext
GET /users/:id_or_username/project_deploy_keys
```

Paramètres :

| Attribut          | Type   | Obligatoire | Description                                                        |
|------------------- |--------|----------|------------------------------------------------------------------- |
| `id_or_username`   | string | oui      | L'identifiant ou le nom d'utilisateur de l'utilisateur pour lequel récupérer les clés de déploiement de projet. |

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": null,
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  },
  {
    "id": 2,
    "title": "Key B",
    "created_at": "2022-05-30T13:34:56.219Z",
    "expires_at": null,
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU"
  }
]
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/20/project_deploy_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": "2022-10-30T12:28:27.855Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  }
]
```

## Récupérer une clé de déploiement {#retrieve-a-deploy-key}

Récupère une clé de déploiement spécifiée.

```plaintext
GET /projects/:id/deploy_keys/:key_id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | oui | L'identifiant de la clé de déploiement |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "created_at": "2013-10-02T10:12:29Z",
  "expires_at": null,
  "can_push": false
}
```

## Ajouter une clé de déploiement pour un projet {#add-a-deploy-key-for-a-project}

Ajoute une clé de déploiement pour un projet spécifié.

Si la clé de déploiement existe déjà dans un autre projet, elle est associée au projet actuel uniquement si l'originale est accessible par le même utilisateur.

```plaintext
POST /projects/:id/deploy_keys
```

| Attribut    | Type | Obligatoire | Description |
| -----------  | ---- | -------- | ----------- |
| `id`         | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `key`        | string   | oui | Nouvelle clé de déploiement |
| `title`      | string   | oui | Titre de la nouvelle clé de déploiement |
| `can_push`   | boolean  | non  | La clé de déploiement peut-elle pousser vers le dépôt du projet |
| `expires_at` | datetime | non | Date d'expiration de la clé de déploiement. N'expire pas si aucune valeur n'est fournie. Format ISO 8601 attendu (`2019-03-15T08:00:00Z`) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
```

Exemple de réponse :

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "can_push": true,
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## Mettre à jour une clé de déploiement {#update-a-deploy-key}

Met à jour une clé de déploiement pour un projet.

```plaintext
PUT /projects/:id/deploy_keys/:key_id
```

| Attribut  | Type | Obligatoire | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `can_push` | boolean | non  | La clé de déploiement peut-elle pousser vers le dépôt du projet |
| `title`    | string  | non | Titre de la nouvelle clé de déploiement |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "New deploy key", "can_push": true}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

Exemple de réponse :

```json
{
  "id": 11,
  "title": "New deploy key",
  "key": "ssh-rsa AAAA...",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null,
  "can_push": true
}
```

## Supprimer une clé de déploiement {#delete-a-deploy-key}

Supprime une clé de déploiement du projet. Si la clé de déploiement n'est utilisée que pour ce projet, elle est supprimée du système.

```plaintext
DELETE /projects/:id/deploy_keys/:key_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | oui | L'identifiant de la clé de déploiement |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## Activer une clé de déploiement {#enable-a-deploy-key}

Active une clé de déploiement pour un projet afin qu'elle puisse être utilisée. Renvoie la clé activée, avec un code de statut 201 en cas de succès.

```plaintext
POST /projects/:id/deploy_keys/:key_id/enable
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | oui | L'identifiant de la clé de déploiement |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/12/enable"
```

Exemple de réponse :

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## Ajouter des clés de déploiement à plusieurs projets {#add-deploy-keys-to-multiple-projects}

Si vous souhaitez ajouter la même clé de déploiement à plusieurs projets du même groupe, cela peut être réalisé via l'API.

Tout d'abord, trouvez l'identifiant des projets qui vous intéressent, soit en listant tous les projets :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects"
```

Soit en trouvant l'identifiant d'un groupe :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups"
```

Puis en listant tous les projets de ce groupe (par exemple, le groupe 1234) :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/1234"
```

Avec ces identifiants, ajoutez la même clé de déploiement à tous :

```shell
for project_id in 321 456 987; do
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
         --header "Content-Type: application/json" \
         --data "{"title": "my key", "key": "ssh-rsa AAAA..."}" \
         "https://gitlab.example.com/api/v4/projects/${project_id}/deploy_keys"
done
```
