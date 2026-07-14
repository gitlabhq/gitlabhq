---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Liste d'autorisation IP"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit quelques [endpoints de surveillance](health_check.md) qui donnent des informations sur l'état de santé lors d'une vérification.

Pour contrôler l'accès à ces endpoints via la liste d'autorisation IP, vous pouvez ajouter des hôtes individuels ou utiliser des plages d'IP :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Ouvrez `/etc/gitlab/gitlab.rb` et ajoutez ou décommentez les éléments suivants :

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Vous pouvez définir les IP requises sous la clé `gitlab.webservice.monitoring.ipWhitelist`. Par exemple :

```yaml
gitlab:
   webservice:
      monitoring:
         # Monitoring IP allowlist
         ipWhitelist:
         # Defaults
         - 0.0.0.0/0
         - ::/0
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yml` :

   ```yaml
   monitoring:
     # by default only local IPs are allowed to access monitoring resources
     ip_whitelist:
       - 127.0.0.0/8
       - 192.168.0.1
   ```

1. Enregistrez le fichier et [redémarrez](../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}
