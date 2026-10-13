---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Signaler un abus
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez signaler des abus d'autres utilisateurs GitLab aux administrateurs GitLab.

Un administrateur GitLab [peut alors choisir](../administration/review_abuse_reports.md) de :

- Supprimer l'utilisateur, ce qui le supprime de l'instance.
- Bloquer l'utilisateur, ce qui lui refuse l'accès à l'instance.
- Ou supprimer le signalement, ce qui conserve l'accès de l'utilisateur à l'instance.

Vous pouvez signaler un utilisateur via :

- [Profil](#report-abuse-from-the-users-profile-page)
- [Commentaires](#report-abuse-from-a-users-comment)
- [Les tickets](#report-abuse-from-an-issue)
- [Tâches](#report-abuse-from-a-task)
- [Objectif](#report-abuse-from-an-objective)
- [Résultat clé](#report-abuse-from-a-key-result)
- [Les merge requests](#report-abuse-from-a-merge-request)
- [les snippets ;](snippets.md#mark-snippet-as-spam)

Vous pouvez également signaler un abus provenant d'un agent ou d'un flow.

## Signaler un abus depuis la page de profil de l'utilisateur {#report-abuse-from-the-users-profile-page}

Pour signaler un abus depuis la page de profil d'un utilisateur :

1. Depuis n'importe où dans GitLab, sélectionnez le nom de l'utilisateur.
1. Dans le coin supérieur droit du profil de l'utilisateur, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis le commentaire d'un utilisateur {#report-abuse-from-a-users-comment}

Pour signaler un abus depuis le commentaire d'un utilisateur :

1. Dans le commentaire, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

> [!note]
> Une URL vers le commentaire de l'utilisateur signalé est préremplie dans le champ **Message** du signalement d'abus.

## Signaler un abus depuis un ticket {#report-abuse-from-an-issue}

1. Sur le ticket, dans le coin supérieur droit, sélectionnez **Actions du ticket** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis une tâche {#report-abuse-from-a-task}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) dans GitLab 17.3.

{{< /history >}}

1. Sur la tâche, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis un objectif {#report-abuse-from-an-objective}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) dans GitLab 17.3.

{{< /history >}}

1. Sur l'objectif, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis un résultat clé {#report-abuse-from-a-key-result}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/461848) dans GitLab 17.3.

{{< /history >}}

1. Sur le résultat clé, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler l'utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis une merge request {#report-abuse-from-a-merge-request}

1. Sur la merge request, dans le coin supérieur droit, sélectionnez **Actions de requête de fusion** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler un abus**.
1. Sélectionnez une raison pour signaler cet utilisateur.
1. Complétez un signalement d'abus.
1. Sélectionnez **Envoyer le rapport**.

## Signaler un abus depuis un agent {#report-abuse-from-an-agent}

Prérequis :

- Être connecté à GitLab.
- Appartenir à un groupe auquel [l'accès à la GitLab Duo Agent Platform a été accordé](../administration/gitlab_duo/configure/access_control.md).
- Un administrateur doit avoir configuré un [e-mail de notification des signalements d'abus](../administration/review_abuse_reports.md) pour l'instance.

Pour signaler un abus depuis un agent :

1. Dans la vue détaillée de l'agent, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler à l'admin**.
1. Sélectionnez une raison pour signaler cet agent.
1. Facultatif. Ajoutez des informations supplémentaires.
1. Sélectionnez **Envoyer**.

## Signaler un abus depuis un flow {#report-abuse-from-a-flow}

Prérequis :

- Être connecté à GitLab.
- Appartenir à un groupe auquel [l'accès à la GitLab Duo Agent Platform a été accordé](../administration/gitlab_duo/configure/access_control.md).
- Un administrateur doit avoir configuré un [e-mail de notification des signalements d'abus](../administration/review_abuse_reports.md) pour l'instance.

Pour signaler un abus depuis un flow :

1. Dans la vue détaillée du flow, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Signaler à l'admin**.
1. Sélectionnez une raison pour signaler ce flow.
1. Facultatif. Ajoutez des informations supplémentaires.
1. Sélectionnez **Envoyer**.

## Sujets connexes {#related-topics}

- [Documentation d'administration des signalements d'abus](../administration/review_abuse_reports.md)
