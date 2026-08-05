---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Trello Power-Ups
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser les Trello Power-Ups pour GitLab afin d'associer des merge requests GitLab à des cartes Trello.

![GitLab Trello Power-Ups - Carte Trello](img/trello_card_with_gitlab_powerup_v9_4.png)

## Configurer les Power-Ups {#configure-power-ups}

Pour configurer les Power-Ups pour un tableau Trello :

1. Accédez à votre tableau Trello.
1. Sélectionnez **Power-Ups** et trouvez la ligne **GitLab**.
1. Sélectionnez **Activer**.
1. Sélectionnez **Paramètres** (l'icône en forme d'engrenage).
1. Sélectionnez **Authorize Account**.
1. Saisissez l'[URL d'API GitLab](#get-the-api-url) et le [jeton d'accès personnel](../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la **API**.
1. Sélectionnez **Enregistrer**.

## Obtenir l'URL d'API {#get-the-api-url}

Votre URL d'API correspond à l'URL de votre instance GitLab avec `/api/v4` ajouté à la fin de l'URL. Par exemple, si l'URL de votre instance GitLab est `https://gitlab.com`, votre URL d'API est `https://gitlab.com/api/v4`. Si l'URL de votre instance est `https://example.com`, votre URL d'API est `https://example.com/api/v4`.
