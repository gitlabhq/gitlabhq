---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Systèmes de suivi de tickets externes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab dispose de son propre [système de suivi de tickets](../user/project/issues/_index.md), mais vous pouvez également configurer un système de suivi de tickets externe par projet GitLab. Vous pouvez ensuite utiliser :

- Le système de suivi de tickets externe avec le système de suivi de tickets GitLab
- Uniquement le système de suivi de tickets externe

Avec un système de suivi externe, vous pouvez utiliser le format `CODE-123` pour mentionner des tickets externes dans les merge requests, les commits et les commentaires GitLab, où :

- `CODE` est un code unique pour le système de suivi
- `123` est le numéro du ticket dans le système de suivi

Les références s'affichent sous forme de liens vers les tickets.

## Désactiver le système de suivi de tickets GitLab {#disable-the-gitlab-issue-tracker}

Pour désactiver les éléments de travail d'un projet, y compris le système de suivi de tickets GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Sous **Éléments de travail**, désactivez le bouton bascule.
1. Sélectionnez **Enregistrer les modifications**.

Une fois le paramètre des éléments de travail désactivé, **Éléments de travail** n'est plus visible dans la barre latérale gauche. Si vous avez configuré un [système de suivi de tickets externe](#configure-an-external-issue-tracker), il reste dans la barre latérale gauche.

## Configurer un système de suivi de tickets externe {#configure-an-external-issue-tracker}

Vous pouvez configurer l'un des systèmes de suivi de tickets externes suivants :

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [ClickUp](../user/project/integrations/clickup.md)
- [Système de suivi de tickets personnalisé](../user/project/integrations/custom_issue_tracker.md)
- [Engineering Workflow Management (EWM)](../user/project/integrations/ewm.md)
- [Jira](jira/_index.md)
- [Linear](../user/project/integrations/linear.md)
- [Phorge](../user/project/integrations/phorge.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
