---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tâches Rake d'import et d'export de projets"
description: "Tâches Rake pour l'import et l'export de grands projets."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour [l'import et l'export de projets](../../user/project/settings/import_export.md).

Vous ne pouvez importer qu'à partir d'une instance GitLab [compatible](../../user/project/settings/import_export.md#compatibility).

## Importer des projets volumineux {#import-large-projects}

La [tâche Rake](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/import_export/import.rake) est utilisée pour importer des exports de projets GitLab volumineux.

Dans le cadre de cette tâche, nous désactivons également le téléversement direct. Cela évite de téléverser une archive volumineuse vers GCS, ce qui peut entraîner des délais d'expiration de transaction inactive.

Nous pouvons exécuter cette tâche depuis le terminal :

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `username`      | string | oui | Nom d'utilisateur |
| `namespace_path` | string | oui | Chemin de l'espace de nommage |
| `project_path` | string | oui | Chemin du projet |
| `archive_path` | string | oui | Chemin vers le tarball du projet exporté que vous souhaitez importer |

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Exporter des projets volumineux {#export-large-projects}

Vous pouvez utiliser une tâche Rake pour exporter un projet volumineux.

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `username`      | string | oui | Nom d'utilisateur |
| `namespace_path` | string | oui | Chemin de l'espace de nommage |
| `project_path` | string | oui | Nom du projet |
| `archive_path` | string | oui | Chemin vers le fichier pour stocker le tarball du projet exporté |

```shell
gitlab-rake "gitlab:import_export:export[username, namespace_path, project_path, archive_path]"
```
