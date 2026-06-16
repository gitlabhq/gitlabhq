---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'import et d'export de groupes"
description: "Importez et exportez des groupes avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [migrer la structure d'un groupe](../user/group/import/_index.md). Lorsque vous utilisez cette API avec l'[API d'import et d'export de projets](project_import_export.md), vous pouvez préserver les relations au niveau du groupe, comme les connexions entre les tickets de projet et les epics de groupe.

Les exports de groupe incluent les éléments suivants :

- Jalons de groupe
- Tableaux de groupe
- Labels de groupe
- Badges de groupe
- Membres du groupe
- Événements de groupe
- Wikis de groupe (Premium et Ultimate uniquement)
- Sous-groupes. Chaque sous-groupe inclut toutes les données précédentes de la liste.

Pour préserver les relations au niveau du groupe à partir des projets importés, vous devez d'abord exécuter l'export et l'import du groupe. De cette façon, vous pouvez importer les exports de projets dans la structure de groupe souhaitée.

En raison du [ticket 405168](https://gitlab.com/gitlab-org/gitlab/-/issues/405168), les groupes importés ont un niveau de visibilité `private` sauf si vous les importez dans un groupe parent. Par défaut, si vous importez des groupes dans un groupe parent, les sous-groupes héritent du même niveau de visibilité que le parent.

Pour préserver la liste des membres et leurs autorisations respectives sur les groupes importés, vérifiez les utilisateurs de ces groupes. Assurez-vous que ces utilisateurs existent avant d'importer les groupes souhaités.

## Créer un export de groupe {#create-a-group-export}

Crée un export de groupe pour un groupe spécifié.

```plaintext
POST /groups/:id/export
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | Entier ou chaîne | Oui      | ID du groupe. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export"
```

```json
{
  "message": "202 Accepted"
}
```

## Récupérer un téléchargement d'export de groupe {#retrieve-a-group-export-download}

Récupère l'archive exportée pour un groupe spécifié.

```plaintext
GET /groups/:id/export/download
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | Entier ou chaîne | Oui      | ID du groupe. |

```shell
group=1
token=secret

curl --request GET \
  --header "PRIVATE-TOKEN: ${token}" \
  --output download_group_${group}.tar.gz \
  --url "https://gitlab.example.com/api/v4/groups/${group}/export/download"
```

```shell
ls *export.tar.gz
2020-12-05_22-11-148_namespace_export.tar.gz
```

Le temps consacré à l'export d'un groupe peut varier en fonction de la taille du groupe. Cet endpoint renvoie :

- L'archive exportée (lorsqu'elle est disponible)
- Un message 404

## Créer un import de groupe {#create-a-group-import}

Crée un import de groupe en téléchargeant un fichier.

La taille maximale du fichier d'import peut être définie par l'administrateur sur GitLab Self-Managed (la valeur par défaut est `0` (illimitée)). En tant qu'administrateur, vous pouvez modifier la taille maximale du fichier d'import :

- Dans la [zone **Admin**](../administration/settings/import_and_export_settings.md).
- En utilisant l'option `max_import_size` dans l'[API des paramètres d'application](settings.md#update-application-settings).

Pour obtenir des informations sur la taille maximale des fichiers d'import sur GitLab.com, consultez les [paramètres de compte et de limites](../user/gitlab_com/_index.md#account-and-limit-settings).

```plaintext
POST /groups/import
```

| Attribut   | Type           | Obligatoire | Description |
| ----------- | -------------- | -------- | ----------- |
| `file`      | Chaîne         | Oui      | Le fichier à télécharger. |
| `name`      | Chaîne         | Oui      | Le nom du groupe à importer. |
| `path`      | Chaîne         | Oui      | Nom et chemin du nouveau groupe. |
| `parent_id` | Entier        | Non       | ID d'un groupe parent dans lequel importer le groupe. Correspond par défaut à l'espace de nommage de l'utilisateur actuel si non renseigné. |

Pour télécharger un fichier depuis votre système de fichiers, utilisez l'argument `--form`. Cela amène cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "name=imported-group" \
  --form "path=imported-group" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/groups/import"
```

## Sujets connexes {#related-topics}

- [API d'import et d'export de projets](project_import_export.md)
