---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâche Rake de référence keep-around orpheline
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Améliorations apportées à la tâche Rake [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/475246) dans GitLab 18.4.

{{< /history >}}

`gitlab:keep_around:orphaned` génère un rapport CSV de chaque référence keep-around dans le dépôt du projet et de chaque référence de base de données à un commit Git.

Le rapport CSV comporte trois colonnes :

- Le type de référence. Soit `keep` pour une référence keep-around, soit `usage` pour une référence de base de données.
- L'ID du commit Git.
- La source de la référence, si elle est connue. Par exemple, `Pipeline`.

## Exécuter le rapport de référence orpheline {#run-orphaned-reference-report}

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:keep_around:orphaned PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:keep_around:orphaned RAILS_ENV=production PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< /tabs >}}
