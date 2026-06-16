---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Liens de release
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/250819) de l'authentification avec un [jeton de job CI/CD GitLab](../../ci/jobs/ci_job_token.md) dans GitLab 15.1.

{{< /history >}}

Utilisez cette API pour interagir avec les liens vers les [releases](../../user/project/releases/_index.md).

GitLab prend en charge les liens d'assets avec les protocoles suivants :

- `http`
- `https`
- `ftp`

> [!note]
> Pour interagir directement avec les releases de projet, consultez l'[API de release de projet](_index.md).

## Lister tous les liens de release {#list-all-release-links}

Liste tous les assets sous forme de liens depuis une release.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links
```

| Attribut     | Type           | Obligatoire | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | oui      | Le tag associé à la release. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links"
```

Exemple de réponse :

```json
[
   {
      "id":2,
      "name":"awesome-v0.2.msi",
      "url":"http://192.168.10.15:3000/msi",
      "link_type":"other"
   },
   {
      "id":1,
      "name":"awesome-v0.2.dmg",
      "url":"http://192.168.10.15:3000",
      "link_type":"other"
   }
]
```

## Récupérer un lien de release {#retrieve-a-release-link}

Récupère un asset spécifié sous forme de lien depuis une release.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribut     | Type           | Obligatoire | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | oui      | Le tag associé à la release. |
| `link_id`    | entier         | oui      | L'ID du lien. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Exemple de réponse :

```json
{
   "id":1,
   "name":"awesome-v0.2.dmg",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```

## Créer un lien de release {#create-a-release-link}

Crée un lien d'asset pour une release spécifiée.

```plaintext
POST /projects/:id/releases/:tag_name/assets/links
```

| Attribut            | Type           | Obligatoire | Description                                                                                                               |
|----------------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `id`                 | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths).                                        |
| `tag_name`           | string         | oui      | Le tag associé à la release.                                                                                      |
| `name`               | string         | oui      | Le nom du lien. Les noms de lien doivent être uniques dans la release.                                                           |
| `url`                | string         | oui      | L'URL du lien. Les URL de lien doivent être uniques dans la release.                                                             |
| `direct_asset_path`  | string         | non       | Chemin optionnel pour un [lien d'asset direct](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `link_type`          | string         | non       | Le type du lien : `other`, `runbook`, `image`, `package`. La valeur par défaut est `other`.                                        |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data name="hellodarwin-amd64" \
    --data url="https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64" \
    --data direct_asset_path="/bin/hellodarwin-amd64" \
    "https://gitlab.example.com/api/v4/projects/20/releases/v1.7.0/assets/links"
```

Exemple de réponse :

```json
{
   "id":2,
   "name":"hellodarwin-amd64",
   "url":"https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64",
   "direct_asset_url":"https://gitlab.example.com/mynamespace/hello/-/releases/v1.7.0/downloads/bin/hellodarwin-amd64",
   "link_type":"other"
}
```

## Mettre à jour un lien de release {#update-a-release-link}

Met à jour un lien d'asset spécifié pour une release.

```plaintext
PUT /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribut            | Type           | Obligatoire | Description                                                                                                               |
| -------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`           | string         | oui      | Le tag associé à la release. |
| `link_id`            | entier        | oui      | L'ID du lien. |
| `name`               | string         | non       | Le nom du lien. |
| `url`                | string         | non       | L'URL du lien. |
| `direct_asset_path`  | string         | non       | Chemin optionnel pour un [lien d'asset direct](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `link_type`          | string         | non       | Le type du lien : `other`, `runbook`, `image`, `package`. La valeur par défaut est `other`. |

> [!note]
> Vous devez spécifier au moins l'un des champs `name` ou `url`

Exemple de requête :

```shell
curl --request PUT --data name="new name" --data link_type="runbook" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Exemple de réponse :

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"runbook"
}
```

## Supprimer un lien de release {#delete-a-release-link}

Supprime un lien d'asset spécifié depuis une release.

```plaintext
DELETE /projects/:id/releases/:tag_name/assets/links/:link_id
```

| Attribut     | Type           | Obligatoire | Description                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | oui      | Le tag associé à la release. |
| `link_id`    | entier         | oui      | L'ID du lien. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

Exemple de réponse :

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```
