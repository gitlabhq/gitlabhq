---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Notes système
description: "Suivez et consultez les notes d'activité générées par le système sur les éléments de travail."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les notes système sont de courtes descriptions qui vous aident à comprendre l'historique des événements survenant au cours du cycle de vie d'un objet GitLab, comme :

- [Alertes](../../operations/incident_management/alerts.md).
- [Designs](issues/design_management.md).
- [Tickets](issues/_index.md).
- [Merge requests](merge_requests/_index.md).
- [Objectifs et résultats clés](../okrs.md) (OKR).
- [Tâches](../tasks.md).

GitLab consigne dans les notes système les informations relatives aux événements déclenchés par Git ou par l'application GitLab. Les notes système utilisent le format `<Author> <action> <time ago>`.

## Afficher ou filtrer les notes système {#show-or-filter-system-notes}

Par défaut, les notes système ne s'affichent pas. Lorsqu'elles sont affichées, elles apparaissent de la plus ancienne à la plus récente. Si vous modifiez les options de filtre ou de tri, votre sélection est mémorisée d'une section à l'autre. Pour tous les types d'éléments à l'exception des merge requests, les options de filtrage sont :

- **Afficher toute l'activité** affiche à la fois les commentaires et l'historique.
- **Afficher uniquement les commentaires** masque les notes système.
- **Afficher uniquement l'historique** masque les commentaires des utilisateurs.

Les merge requests offrent des options de filtrage plus granulaires.

### Sur une epic {#on-an-epic}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. Dans la barre de filtres, sélectionnez le filtre **Type**, l'opérateur **est** et la valeur **Épopée**.
1. Identifiez l'epic souhaitée et sélectionnez son titre.
1. Accédez à la section **Activité**.
1. Pour **Trier ou filtrer**, sélectionnez **Afficher toute l'activité**.

### Sur un ticket {#on-an-issue}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Ticket** et sélectionnez votre ticket.
1. Accédez à **Activité**.
1. Pour **Trier ou filtrer**, sélectionnez **Afficher toute l'activité**.

### Sur une merge request {#on-a-merge-request}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Accédez à **Activité**.
1. Pour **Trier ou filtrer**, sélectionnez **Afficher toute l'activité** pour voir toutes les notes système. Pour affiner les types de notes système retournées, sélectionnez une ou plusieurs des options suivantes :

   - **Approbations**
   - **Personnes assignées et relecteurs**
   - **Commentaires**
   - **Branches et validations**
   - **Modifications**
   - **Labels**
   - **État de verrouillage**
   - **Mentions**
   - **État de la demande de fusion**
   - **Suivi**

## Considérations relatives à la confidentialité {#privacy-considerations}

Vous ne pouvez voir que les notes système liées aux objets auxquels vous avez accès.

Par exemple, si quelqu'un mentionne votre ticket 111 dans un ticket d'un projet privé :

- Les membres du projet voient la note suivante dans le ticket 111 : `Alex Garcia mentioned in agarcia/private-project#222`.
- Les non-membres du projet ne peuvent pas voir la note du tout.

## Sujets connexes {#related-topics}

- [API Notes](../../api/notes.md)
