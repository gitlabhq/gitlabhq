---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Connecteur Jira DVCS
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le connecteur Jira DVCS (système de contrôle de version distribué) si vous hébergez vous-même votre instance Jira avec Jira Data Center ou Jira Server et souhaitez utiliser le [panneau de développement Jira](../development_panel.md). Le connecteur Jira DVCS est développé et maintenu par Atlassian.

Pour configurer le connecteur Jira DVCS, consultez [l'intégration avec les outils de développement à l'aide de DVCS](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html). Vous pouvez uniquement utiliser le connecteur Jira DVCS avec Jira Data Center ou Jira Server dans Jira 8.14 et versions ultérieures.

Jira crée un webhook dans le projet GitLab pour fournir des mises à jour en temps réel. Pour configurer ce webhook, vous devez disposer du rôle Maintainer ou Owner pour le projet. Pour plus d'informations, consultez [la configuration de la sécurité des webhooks](https://confluence.atlassian.com/adminjiraserver/configuring-webhook-security-1299913153.html).

Le connecteur Jira DVCS pour Jira Cloud a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126) dans GitLab 16.0. Utilisez plutôt l'[application GitLab pour Jira Cloud](../connect-app.md). Pour plus d'informations, consultez [installer l'application GitLab pour Jira Cloud](../connect-app.md#install-the-gitlab-for-jira-cloud-app).

## Actualiser les données importées dans Jira {#refresh-data-imported-to-jira}

Par défaut, Jira importe les commits et les branches des projets GitLab toutes les 60 minutes. Pour actualiser les données manuellement dans Jira :

1. Connectez-vous à votre instance Jira en tant qu'utilisateur avec lequel vous avez configuré l'intégration.
1. Dans la barre supérieure, dans le coin supérieur droit, sélectionnez **Administration** ({{< icon name="settings" >}}) > **Applications**.
1. Dans la barre latérale gauche, sélectionnez **DVCS accounts**.
1. Pour actualiser un ou plusieurs dépôts dans un compte DVCS :
   - **For all repositories**, à côté du compte, sélectionnez le bouton représentant des points de suspension ({{< icon name="ellipsis_h" >}}) > **Refresh repositories**.
   - **For a single repository** :
     1. Sélectionnez le compte.
     1. Survolez le dépôt que vous souhaitez actualiser et, dans la colonne **Dernière activité**, sélectionnez **Click to sync repository** ({{< icon name="retry" >}}).
