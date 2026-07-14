---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exportateur de Registry
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'exportateur de Registry vous permet de mesurer diverses métriques de Registry. Pour l'activer :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb` et activez le [mode debug](https://docs.docker.com/registry/#debug) pour le Registry :

   ```ruby
   registry['debug_addr'] = "localhost:5001"  # localhost:5001/metrics
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence automatiquement à collecter des données de performance à partir de l'exportateur de Registry exposé sous `localhost:5001/metrics`.

[← Retour à la page principale de Prometheus](_index.md)
