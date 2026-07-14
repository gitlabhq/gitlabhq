---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exportateur Redis
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'[exportateur Redis](https://github.com/oliver006/redis_exporter) vous permet de mesurer diverses métriques [Redis](https://redis.io). Pour plus d'informations sur ce qui est exporté, [lisez la documentation en amont](https://github.com/oliver006/redis_exporter/blob/master/README.md#whats-exported).

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

Pour activer l'exportateur Redis :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Ajoutez (ou trouvez et décommentez) la ligne suivante, en vous assurant qu'elle est définie sur `true` :

   ```ruby
   redis_exporter['enable'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence à collecter des données de performance à partir de l'exportateur Redis exposé à `localhost:9121`.

## Configurer les indicateurs de l'exportateur Redis {#configure-the-redis-exporter-flags}

Vous pouvez utiliser le paramètre `redis_exporter['flags']` pour transmettre des [indicateurs de ligne de commande](https://github.com/oliver006/redis_exporter/blob/master/README.md#command-line-flags) et personnaliser le comportement de l'exportateur Redis selon vos besoins de surveillance.

> [!note]
> `redis.addr` n'est pas utilisable car cette valeur est configurée par les valeurs `gitlab_rails[redis_*]` telles que `gitlab_rails[redis_host]`.

Pour configurer les indicateurs de l'exportateur Redis :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez quelques indicateurs, par exemple :

   ```ruby
   redis_exporter['flags'] = {
     'redis.password' => 'your-redis-password',
     'namespace' => 'redis',
     'web.listen-address' => ':9121',
     'web.telemetry-path' => '/metrics'
   }
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```
