---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exportateur PgBouncer
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'[exportateur PgBouncer](https://github.com/prometheus-community/pgbouncer_exporter) vous permet de mesurer diverses métriques de [PgBouncer](https://www.pgbouncer.org/).

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

Pour activer l'exportateur PgBouncer :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Ajoutez (ou trouvez et décommentez) la ligne suivante, en vous assurant qu'elle est définie sur `true` :

   ```ruby
   pgbouncer_exporter['enable'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence à collecter des données de performance depuis l'exportateur PgBouncer exposé à `localhost:9188`.

L'exportateur PgBouncer est activé par défaut si le rôle [`pgbouncer_role`](https://docs.gitlab.com/omnibus/roles/#postgresql-roles) est activé.
