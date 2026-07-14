---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab exporter
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Surveillez les métriques de performance de votre instance GitLab avec [GitLab exporter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter). Pour une installation avec le package Linux, GitLab exporter récupère les métriques depuis Redis et la base de données, et fournit des informations sur les goulots d'étranglement, les schémas de consommation des ressources et les domaines potentiels d'optimisation.

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

## Activer GitLab exporter {#enable-gitlab-exporter}

Pour activer GitLab exporter dans une instance du package Linux :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Ajoutez, ou trouvez et décommentez, la ligne suivante, en vous assurant qu'elle est définie sur `true` :

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence automatiquement à collecter les données de performance depuis GitLab exporter exposé sur `localhost:9168`.

## Utiliser un serveur Rack différent {#use-a-different-rack-server}

Par défaut, GitLab exporter s'exécute sur [WEBrick](https://github.com/ruby/webrick), un serveur web Ruby mono-fil de discussion. Vous pouvez choisir un serveur Rack différent qui correspond mieux à vos besoins de performance. Par exemple, dans des configurations multi-nœuds contenant un grand nombre de scrapers Prometheus mais seulement quelques nœuds de surveillance, vous pouvez décider d'exécuter un serveur multi-fils de discussion tel que Puma à la place.

Pour changer le serveur Rack vers Puma :

1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Ajoutez, ou trouvez et décommentez, la ligne suivante, et définissez-la sur `puma` :

   ```ruby
   gitlab_exporter['server_name'] = 'puma'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Les serveurs Rack pris en charge sont `webrick` et `puma`.
