---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Surveiller et gérer l'activité utilisateur signalée comme spam."
gitlab_dedicated: yes
title: Examiner les journaux de spam
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab suit l'activité des utilisateurs et signale certains comportements comme du spam potentiel.

Dans la zone **Admin**, un administrateur GitLab peut consulter et résoudre les journaux de spams.

## Gérer les journaux de spams {#manage-spam-logs}

{{< history >}}

- **Faire confiance à l'utilisateur** [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812) dans GitLab 16.5.

{{< /history >}}

Consultez et résolvez les journaux de spams pour modérer l'activité des utilisateurs dans votre instance.

Pour consulter les journaux de spams :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Journaux de spams**.
1. Facultatif. Pour résoudre un journal de spam, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis **Supprimer l'utilisateur**, **Bloquer l'utilisateur**, **Supprimer les journaux** ou **Faire confiance à l'utilisateur**.

### Résolution des journaux de spams {#resolving-spam-logs}

Vous pouvez résoudre un journal de spam avec l'un des effets suivants :

| Option | Description |
|---------|-------------|
| **Supprimer l'utilisateur** | L'utilisateur est [supprimé](../user/profile/account/delete_account.md) de l'instance. |
| **Bloquer l'utilisateur** | L'utilisateur est bloqué depuis l'instance. Le journal de spam reste dans la liste. |
| **Supprimer les journaux** | Le journal de spam est supprimé de la liste. |
| **Faire confiance à l'utilisateur** | L'utilisateur est approuvé et peut créer des tickets, des notes, des extraits de code et des merge requests sans être bloqué pour spam. Les journaux de spams ne sont pas créés pour les utilisateurs approuvés. |

## Sujets connexes {#related-topics}

- [Modérer les utilisateurs (administration)](moderate_users.md)
- [Examiner les rapports d'abus](review_abuse_reports.md)
