---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Les administrateurs d'instance peuvent configurer un modèle de fermeture de ticket personnalisé pour leur instance GitLab."
title: Modèle de fermeture de ticket
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Pour la documentation utilisateur sur les modèles de fermeture de tickets, voir [Fermeture automatique des tickets](../user/project/issues/managing_issues.md#closing-issues-automatically).

Lorsqu'un commit ou un merge request résout un ou plusieurs tickets, GitLab peut fermer ces tickets lorsque le commit ou le merge request est intégré à la branche par défaut du projet. Le [modèle de fermeture de ticket par défaut](../user/project/issues/managing_issues.md#default-closing-pattern) couvre un large éventail de mots, et les administrateurs peuvent configurer la liste de mots selon leurs besoins.

## Modifier le modèle de fermeture de ticket {#change-the-issue-closing-pattern}

Pour modifier le modèle de fermeture de ticket par défaut selon vos besoins :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et changez la valeur `gitlab_rails['gitlab_issue_closing_pattern']` :

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` et changez la valeur `issueClosingPattern` :

   ```yaml
   global:
     appConfig:
       issueClosingPattern: "<regular_expression>"
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` et changez la valeur `gitlab_rails['gitlab_issue_closing_pattern']` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et changez la valeur `issue_closing_pattern` :

   ```yaml
   production: &base
     gitlab:
       issue_closing_pattern: "<regular_expression>"
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

Pour tester le modèle de fermeture de ticket, utilisez [Rubular](https://rubular.com). Rubular ne comprend pas `%{issue_ref}`. Lorsque vous testez vos modèles, remplacez cette chaîne par `#\d+`, qui correspond uniquement aux références de tickets locaux comme `#123`.
