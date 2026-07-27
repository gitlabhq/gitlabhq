---
stage: None
group: Unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Intervalle du cache de l'application"
description: "Gérer le cache de l'application GitLab."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Par défaut, GitLab met en cache les paramètres de l'application pendant 60 secondes. Il peut arriver que vous deviez augmenter cet intervalle afin d'introduire un délai plus important entre les modifications des paramètres de l'application et le moment où les utilisateurs remarquent ces changements dans l'application.

Nous vous recommandons de définir cette valeur à plus de `0` secondes. Si vous la définissez à `0`, la table `application_settings` se chargera à chaque requête. Cela entraîne une charge supplémentaire pour Redis et PostgreSQL.

## Modifier l'intervalle d'expiration du cache applicatif {#change-the-expiration-interval-for-application-cache}

Pour modifier la valeur d'expiration :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. Enregistrez le fichier, puis reconfigurez et redémarrez GitLab pour que les modifications prennent effet :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Self-compiled (Source)" >}}

1. Modifiez `config/gitlab.yml` :

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. Enregistrez le fichier, puis [redémarrez](restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}
