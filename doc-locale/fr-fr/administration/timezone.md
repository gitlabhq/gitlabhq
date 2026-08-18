---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Modifier votre fuseau horaire
description: "Modifier le fuseau horaire d'une instance."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Les utilisateurs peuvent définir leur [fuseau horaire dans leur profil](../user/profile/_index.md#set-your-time-zone). Les nouveaux utilisateurs n'ont pas de fuseau horaire par défaut et doivent le définir explicitement avant qu'il s'affiche sur leur profil. Sur GitLab.com, le fuseau horaire par défaut est UTC.

Le fuseau horaire par défaut dans GitLab est UTC, mais vous pouvez le modifier selon vos préférences.

Pour mettre à jour le fuseau horaire de votre instance GitLab :

1. Le fuseau horaire spécifié doit être au [format tz](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Vous pouvez utiliser la commande `timedatectl` pour afficher les fuseaux horaires disponibles :

   ```shell
   timedatectl list-timezones
   ```

1. Modifiez le fuseau horaire, par exemple en `America/New_York`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. Enregistrez le fichier, puis reconfigurez et redémarrez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     time_zone: 'America/New_York'
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     gitlab:
       time_zone: 'America/New_York'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
