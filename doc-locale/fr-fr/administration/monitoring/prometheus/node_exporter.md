---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Node exporter
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le [node exporter](https://github.com/prometheus/node_exporter) vous permet de mesurer diverses ressources machine telles que la mémoire, le disque et l'utilisation du CPU.

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

Pour activer le node exporter :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb`.
1. Ajoutez (ou trouvez et décommentez) la ligne suivante, en vous assurant qu'elle est définie sur `true` :

   ```ruby
   node_exporter['enable'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence à collecter des données de performance à partir du node exporter exposé à `localhost:9100`.
