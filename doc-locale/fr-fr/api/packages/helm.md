---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Helm
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [clients de packages Helm](../../user/packages/helm_repository/_index.md).

> [!warning]
> Cette API est utilisée par les clients de packages liés à Helm tels que [Helm](https://helm.sh/) et [`helm-push`](https://github.com/chartmuseum/helm-push/#readme), et n'est généralement pas destinée à une utilisation manuelle.

Ces endpoints ne suivent pas les méthodes d'authentification API standard. Consultez la [documentation du registre Helm](../../user/packages/helm_repository/_index.md) pour plus de détails sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Télécharger un index de chart {#download-a-chart-index}

> [!note]
> Pour garantir des URL de téléchargement de charts cohérentes, le champ `contextPath` dans les réponses `index.yaml` utilise toujours l'ID de projet numérique, que vous accédiez à l'API avec l'ID de projet ou le chemin complet du projet.

Télécharge un index de chart spécifié pour un projet.

```plaintext
GET projects/:id/packages/helm/:channel/index.yaml
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID ou le chemin complet du projet. |
| `channel` | string | oui      | Canal du dépôt Helm. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml"
```

Écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml" \
     --remote-name
```

## Télécharger un chart {#download-a-chart}

Télécharge un chart spécifié pour un projet.

```plaintext
GET projects/:id/packages/helm/:channel/charts/:file_name.tgz
```

| Attribut   | Type   | Obligatoire | Description |
| ----------- | ------ | -------- | ----------- |
| `id`        | string | oui      | L'ID ou le chemin complet du projet. |
| `channel`   | string | oui      | Canal du dépôt Helm. |
| `file_name` | string | oui      | Nom de fichier du chart. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/charts/mychart.tgz" \
     --remote-name
```

## Téléverser un chart {#upload-a-chart}

Téléverse un chart spécifié pour un projet.

```plaintext
POST projects/:id/packages/helm/api/:channel/charts
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID ou le chemin complet du projet. |
| `channel` | string | oui      | Canal du dépôt Helm. |
| `chart`   | fichier   | oui      | Chart (en tant que `multipart/form-data`). |

```shell
curl --request POST \
     --form 'chart=@mychart.tgz' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts"
```
