---
stage: Plan
group: Portfolio Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créer, modifier et maintenir des objectifs et des résultats clés (OKR)."
title: Objectifs et résultats clés (OKR)
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103355) dans GitLab 15.6 [avec un feature flag](../administration/feature_flags/_index.md) nommé `okrs_mvc`. Fonctionnalité désactivée par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

[Les objectifs et résultats clés](https://en.wikipedia.org/wiki/OKR) (OKR) constituent un cadre de définition et de suivi des objectifs alignés sur la stratégie et la vision globales de votre organisation.

L'objectif et le résultat clé dans GitLab partagent de nombreuses fonctionnalités. Dans la documentation, le terme **OKR** désigne à la fois les objectifs et les résultats clés.

Les OKR sont un type d'élément de travail, une étape vers les [types de tickets par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/323404) dans GitLab. Pour le roadmap de migration des [tickets](project/issues/_index.md) et des [epics](group/epics/_index.md) vers les éléments de travail et l'ajout de types d'éléments de travail personnalisés, consultez l'[epic 6033](https://gitlab.com/groups/gitlab-org/-/work_items/6033) ou la [page de direction Plan](https://about.gitlab.com/direction/plan/).

## Concevoir des OKR efficaces {#designing-effective-okrs}

Utilisez les objectifs et les résultats clés pour aligner votre personnel vers des objectifs communs et suivre la progression. Définissez un grand objectif et utilisez les [objectifs enfants et résultats clés](#child-objectives-and-key-results) pour mesurer l'avancement de cet objectif.

Les objectifs sont des buts ambitieux à atteindre et définissent ce que vous cherchez à accomplir. Ils montrent comment le travail d'un individu, d'une équipe ou d'un département influence la direction générale de l'organisation en reliant leur travail à la stratégie globale de l'entreprise.

**Les résultats clés** sont des mesures de progression par rapport aux objectifs alignés. Ils expriment comment vous savez si vous avez atteint votre objectif. En atteignant un résultat spécifique (résultat clé), vous créez de la progression pour l'objectif lié.

Pour vérifier si votre OKR est cohérent, vous pouvez utiliser cette phrase :

<!-- vale gitlab_base.FutureTense = NO -->
> Je/nous accomplirons (objectif) d'ici (date) en atteignant et réalisant les métriques suivantes (résultats clés).
<!-- vale gitlab_base.FutureTense = YES -->

Pour apprendre à créer de meilleurs OKR et découvrir comment nous les utilisons chez GitLab, consultez la [page du manuel Objectifs et résultats clés](https://handbook.gitlab.com/handbook/company/okrs/).

## Créer un objectif {#create-an-objective}

Pour créer un objectif :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. Dans le coin supérieur droit, sélectionnez **Nouvel élément**.
1. Pour **Type**, sélectionnez **Objectif**.
1. Saisissez le titre de l'objectif.
1. Sélectionnez **Créer un objectif**.

Pour créer un résultat clé, [ajoutez-le en tant qu'enfant](#add-a-child-key-result) à un objectif existant.

## Afficher un objectif {#view-an-objective}

Pour afficher un objectif :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. [Filtrez la liste des éléments de travail](project/issues/managing_issues.md#filter-the-list-of-issues) pour `Type = Objective`.
1. Sélectionnez le titre d'un objectif dans la liste.

## Afficher un résultat clé {#view-a-key-result}

Pour afficher un résultat clé :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. [Filtrez la liste des éléments de travail](project/issues/managing_issues.md#filter-the-list-of-issues) pour `Type = Key Result`.
1. Sélectionnez le titre d'un résultat clé dans la liste.

Vous pouvez également accéder à un résultat clé depuis la section **Éléments enfants** dans l'objectif parent.

## Modifier le titre et la description {#edit-title-and-description}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour modifier un OKR :

1. [Ouvrez l'objectif](#view-an-objective) ou le [résultat clé](#view-a-key-result) que vous souhaitez modifier.
1. Facultatif. Pour modifier le titre, sélectionnez-le, apportez vos modifications, puis sélectionnez n'importe quelle zone en dehors du champ de texte du titre.
1. Facultatif. Pour modifier la description, sélectionnez l'icône de modification ({{< icon name="pencil" >}}), apportez vos modifications, puis sélectionnez **Sauvegarder**.

## Empêcher la troncature des descriptions avec **En savoir plus** {#prevent-truncating-descriptions-with-read-more}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) dans GitLab 17.10.

{{< /history >}}

Si la description d'un OKR est longue, GitLab n'en affiche qu'une partie. Pour afficher la description complète, vous devez sélectionner **En savoir plus**. Cette troncature facilite la recherche d'autres éléments sur la page sans avoir à faire défiler un texte long.

Pour modifier la troncature des descriptions :

1. Sur un objectif ou un résultat clé, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Voir les options**.
1. Activez ou désactivez **Tronquer les descriptions** selon vos préférences.

Ce paramètre est mémorisé et s'applique à tous les tickets, tâches, epics, objectifs et résultats clés.

## Masquer la barre latérale droite {#hide-the-right-sidebar}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) dans GitLab 17.10.

{{< /history >}}

Les attributs sont affichés dans une barre latérale à droite de la description lorsque l'espace le permet. Pour masquer la barre latérale et augmenter l'espace disponible pour la description :

1. Sur un objectif ou un résultat clé, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Voir les options**.
1. Sélectionnez **Masquer la barre latérale**.

Ce paramètre est mémorisé et s'applique à tous les tickets, tâches, epics, objectifs et résultats clés.

Pour afficher à nouveau la barre latérale :

- Répétez les étapes précédentes et sélectionnez **Afficher la barre latérale**.

## Afficher les notes système des OKR {#view-okr-system-notes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) dans GitLab 15.7 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_items_mvc_2`. Fonctionnalité désactivée par défaut.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/378949) vers le feature flag nommé `work_items_mvc` dans GitLab 15.8. Fonctionnalité désactivée par défaut.
- Feature flag [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144141) de `work_items_mvc` à `work_items_beta` dans GitLab 16.10.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.
- Feature flag `work_items_beta` [supprimé](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549) dans GitLab 18.6.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Vous pouvez afficher toutes les [notes système](project/system_notes.md) relatives à l'OKR. Par défaut, elles sont triées par **Plus ancien en premier**. Vous pouvez toujours modifier l'ordre de tri en **Plus récent en premier**, ce paramètre étant mémorisé entre les sessions.

## Commentaires et fils de discussion {#comments-and-threads}

Vous pouvez ajouter des [commentaires](discussions/_index.md) et répondre à des fils de discussion dans les OKR.

## Assigner des utilisateurs {#assign-users}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Pour indiquer qui est responsable d'un OKR, vous pouvez y assigner des utilisateurs.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour modifier la personne assignée à un OKR :

1. [Ouvrez l'objectif](#view-an-objective) ou le [résultat clé](#view-a-key-result) que vous souhaitez modifier.
1. À côté de **Personnes assignées**, sélectionnez **Ajouter des personnes assignées**.
1. Dans la liste déroulante, sélectionnez les utilisateurs à ajouter en tant que personne assignée.
1. Sélectionnez n'importe quelle zone en dehors de la liste déroulante.

## Assigner des labels {#assign-labels}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Utilisez des [labels](project/labels.md) pour organiser les OKR entre les équipes.

Pour ajouter des labels à un OKR :

1. [Ouvrez l'objectif](#view-an-objective) ou le [résultat clé](#view-a-key-result) que vous souhaitez modifier.
1. À côté de **Labels**, sélectionnez **Ajouter des labels**.
1. Dans la liste déroulante, sélectionnez les labels à ajouter.
1. Sélectionnez n'importe quelle zone en dehors de la liste déroulante.

## Ajouter un objectif à un jalon {#add-an-objective-to-a-milestone}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Vous pouvez ajouter un objectif à un [jalon](project/milestones/_index.md). Vous pouvez voir le titre du jalon lorsque vous affichez un objectif.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour ajouter un objectif à un jalon :

1. [Ouvrez l'objectif](#view-an-objective) que vous souhaitez modifier.
1. À côté de **Jalon**, sélectionnez **Ajouter au jalon**. Si un objectif appartient déjà à un jalon, la liste déroulante affiche le jalon actuel.
1. Dans la liste déroulante, sélectionnez le jalon à associer à l'objectif.

## Définir la progression {#set-progress}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Indiquez quelle part du travail nécessaire à l'atteinte d'un objectif est terminée.

Vous pouvez définir la progression manuellement sur les objectifs et les résultats clés.

Lorsque vous saisissez la progression d'un élément enfant, la progression de tous les éléments parents dans la hiérarchie est mise à jour avec la moyenne de la progression des éléments enfants. Vous pouvez remplacer la progression à n'importe quel niveau et saisir une valeur manuellement, mais lorsque la valeur de progression d'un élément enfant est mise à jour, l'automatisation met à jour tous les parents pour afficher la moyenne.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour définir la progression d'un objectif ou d'un résultat clé :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. [Filtrez la liste des éléments de travail](project/issues/managing_issues.md#filter-the-list-of-issues) pour `Type = Objective` ou `Type = Key Result` et sélectionnez votre élément.
1. À côté de **Progression**, sélectionnez le champ de texte.
1. Saisissez un nombre compris entre 0 et 100.

## Définir l'état de santé {#set-health-status}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Pour mieux suivre le risque lié à l'atteinte de vos objectifs, vous pouvez attribuer un [état de santé](project/issues/managing_issues.md#health-status) à chaque objectif et résultat clé. Vous pouvez utiliser l'état de santé pour indiquer aux autres membres de votre organisation si les OKR progressent comme prévu ou nécessitent une attention particulière pour rester dans les délais.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour définir l'état de santé d'un OKR :

1. [Ouvrez le résultat clé](#view-a-key-result) que vous souhaitez modifier.
1. À côté de **État de santé**, sélectionnez la liste déroulante et choisissez l'état de santé souhaité.

## Promouvoir un résultat clé en objectif {#promote-a-key-result-to-an-objective}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour promouvoir un résultat clé :

1. [Ouvrez le résultat clé](#view-a-key-result).
1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Définir comme objectif**.

Vous pouvez également utiliser la [quick action `/promote_to objective`](project/quick_actions.md#promote_to).

## Convertir un OKR en un autre type d'élément {#convert-an-okr-to-another-item-type}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385131) dans GitLab 17.8 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_items_beta`. Fonctionnalité désactivée par défaut.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/385131) [vers le flag](../administration/feature_flags/_index.md) nommé `okrs_mvc`. Pour connaître l'état actuel du flag, consultez le haut de cette page.

{{< /history >}}

Convertissez un objectif ou un résultat clé en un autre type d'élément, tel que :

- Ticket
- Tâche
- Objectif
- Résultat clé

> [!warning]
> La modification du type peut entraîner une perte de données si le type cible ne prend pas en charge tous les champs du type d'origine.

Prérequis :

- L'OKR que vous souhaitez convertir ne doit pas avoir d'élément parent assigné.
- L'OKR que vous souhaitez convertir ne doit pas avoir d'éléments enfants.

Pour convertir un OKR en un autre type d'élément :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis sélectionnez votre ticket pour l'afficher.
1. Dans la liste, trouvez votre objectif ou résultat clé et sélectionnez-le.
1. Dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Changer de type**.
1. Sélectionnez le type d'élément souhaité.
1. Si toutes les conditions sont remplies, sélectionnez **Changer de type**.

Vous pouvez également utiliser la [quick action `/type`](project/quick_actions.md#type), suivie de `issue`, `task`, `objective` ou `key result` dans un commentaire.

## Copier la référence d'un objectif ou d'un résultat clé {#copy-objective-or-key-result-reference}

Pour faire référence à un objectif ou à un résultat clé ailleurs dans GitLab, vous pouvez utiliser son URL complète ou une référence courte, qui ressemble à `namespace/project-name#123`, où `namespace` est soit un groupe, soit un nom d'utilisateur.

Pour copier la référence de l'objectif ou du résultat clé dans votre presse-papiers :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis sélectionnez votre objectif ou résultat clé pour l'afficher.
1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Copier la référence**.

Vous pouvez maintenant coller la référence dans une autre description ou un commentaire.

Pour en savoir plus sur les références d'objectifs ou de résultats clés, consultez le [Markdown spécifique à GitLab](markdown.md#gitlab-specific-references).

## Copier l'adresse e-mail d'un objectif ou d'un résultat clé {#copy-objective-or-key-result-email-address}

Vous pouvez créer un commentaire dans un objectif ou un résultat clé en envoyant un e-mail. L'envoi d'un e-mail à cette adresse crée un commentaire contenant le corps de l'e-mail.

Pour plus d'informations sur la création de commentaires par e-mail et la configuration nécessaire, consultez [Répondre à un commentaire par e-mail](discussions/_index.md#reply-to-a-comment-by-sending-email).

Pour copier l'adresse e-mail de l'objectif ou du résultat clé :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis sélectionnez votre objectif pour l'afficher.
1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Copier l'adresse e-mail de l'objectif** ou **Copier l'adresse e-mail du résultat clé**.

## Fermer un OKR {#close-an-okr}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Lorsqu'un OKR est atteint, vous pouvez le fermer. L'OKR est marqué comme fermé mais n'est pas supprimé.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour fermer un OKR :

1. [Ouvrez l'objectif](#view-an-objective) que vous souhaitez modifier.
1. À côté de **Statut**, sélectionnez **Fermé**.

Vous pouvez rouvrir un OKR fermé de la même manière.

## Objectifs enfants et résultats clés {#child-objectives-and-key-results}

Dans GitLab, les objectifs sont similaires aux résultats clés. Dans votre workflow, utilisez les résultats clés pour mesurer l'objectif décrit dans l'objectif parent.

Vous pouvez ajouter des objectifs enfants jusqu'à 9 niveaux au total. Un objectif peut avoir jusqu'à 100 OKR enfants. Les résultats clés sont des enfants des objectifs et ne peuvent pas avoir d'éléments enfants eux-mêmes.

Les objectifs enfants et les résultats clés sont disponibles dans la section **Éléments enfants** sous la description d'un objectif.

### Ajouter un objectif enfant {#add-a-child-objective}

{{< history >}}

- Possibilité de sélectionner le projet dans lequel créer l'objectif [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/436255) dans GitLab 17.1.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour ajouter un nouvel objectif à un objectif :

1. Dans un objectif, dans la section **Éléments enfants**, sélectionnez **Ajouter**, puis sélectionnez **Nouvel objectif**.
1. Saisissez un titre pour le nouvel objectif.
1. Sélectionnez un [projet](project/organize_work_with_projects.md) dans lequel créer le nouvel objectif.
1. Sélectionnez **Créer un objectif**.

Pour ajouter un objectif existant à un objectif :

1. Dans un objectif, dans la section **Éléments enfants**, sélectionnez **Ajouter**, puis sélectionnez **Objectif existant**.
1. Recherchez l'objectif souhaité en saisissant une partie de son titre, puis sélectionnez la correspondance souhaitée.

   Pour ajouter plusieurs objectifs, répétez cette étape.
1. Sélectionnez **Ajouter un objectif**.

### Ajouter un résultat clé enfant {#add-a-child-key-result}

{{< history >}}

- Possibilité de sélectionner le projet dans lequel créer le résultat clé [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/436255) dans GitLab 17.1.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour ajouter un nouveau résultat clé à un objectif :

1. Dans un objectif, dans la section **Éléments enfants**, sélectionnez **Ajouter**, puis sélectionnez **Nouveau résultat clé**.
1. Saisissez un titre pour le nouveau résultat clé.
1. Sélectionnez un [projet](project/organize_work_with_projects.md) dans lequel créer le nouveau résultat clé.
1. Sélectionnez **Créer un résultat clé**.

Pour ajouter un résultat clé existant à un objectif :

1. Dans un objectif, dans la section **Éléments enfants**, sélectionnez **Ajouter**, puis sélectionnez **Résultat clé existant**.
1. Recherchez l'OKR souhaité en saisissant une partie de son titre, puis sélectionnez la correspondance souhaitée.

   Pour ajouter plusieurs objectifs, répétez cette étape.
1. Sélectionnez **Ajouter un résultat clé**.

### Réorganiser les éléments enfants des objectifs et résultats clés {#reorder-objective-and-key-result-children}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Par défaut, les OKR enfants sont ordonnés par date de création. Pour les réorganiser, faites-les glisser.

### Planifier des rappels de check-in OKR {#schedule-okr-check-in-reminders}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/422761) dans GitLab 16.4 [avec le feature flag](../administration/feature_flags/_index.md) `okr_checkin_reminders`. Fonctionnalité désactivée par défaut.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Planifiez des rappels de check-in pour inviter votre équipe à fournir des mises à jour de statut sur les résultats clés qui vous importent. Les rappels sont envoyés à toutes les personnes assignées aux objets descendants et aux résultats clés sous forme de notifications par e-mail et d'éléments de la liste de tâches. Les utilisateurs ne peuvent pas se désabonner des notifications par e-mail, mais les rappels de check-in peuvent être désactivés. Les rappels sont envoyés le mardi.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.
- Il doit y avoir au moins un objectif avec au moins un résultat clé dans le projet.
- Vous pouvez planifier des rappels uniquement pour les objectifs de premier niveau. La planification d'un rappel de check-in pour des objectifs enfants n'a aucun effet. Le paramètre de l'objectif de premier niveau est hérité par tous les objectifs enfants.

Pour planifier un rappel récurrent pour un objectif, utilisez la [quick action `/checkin_reminder`](project/quick_actions.md#checkin_reminder) dans un nouveau commentaire.

## Définir un objectif comme parent {#set-an-objective-as-a-parent}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.
- L'objectif parent et l'OKR enfant doivent appartenir au même projet.

Pour définir un objectif comme parent d'un OKR :

1. [Ouvrez l'objectif](#view-an-objective) ou le [résultat clé](#view-a-key-result) que vous souhaitez modifier.
1. À côté de **Parent**, dans la liste déroulante, sélectionnez le parent à ajouter.
1. Sélectionnez n'importe quelle zone en dehors de la liste déroulante.

Pour supprimer le parent de l'objectif ou du résultat clé, à côté de **Parent**, sélectionnez la liste déroulante, puis sélectionnez **Annuler l'assignation**.

## OKR confidentiels {#confidential-okrs}

Les OKR confidentiels sont des OKR visibles uniquement par les membres d'un projet disposant des [permissions suffisantes](#who-can-see-confidential-okrs). Vous pouvez utiliser les OKR confidentiels pour garder les vulnérabilités de sécurité privées ou empêcher des surprises de filtrer.

### Rendre un OKR confidentiel {#make-an-okr-confidential}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Par défaut, les OKR sont publics. Vous pouvez rendre un OKR confidentiel lors de sa création ou de sa modification.

#### Dans un nouvel OKR {#in-a-new-okr}

Lorsque vous créez un nouvel objectif, une case à cocher juste en dessous de la zone de texte permet de marquer l'OKR comme confidentiel.

Cochez cette case, puis sélectionnez **Créer un objectif** ou **Créer un résultat clé** pour créer l'OKR.

#### Dans un OKR existant {#in-an-existing-okr}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.
- Un **objectif confidentiel** ne peut avoir que des [objectifs enfants ou des résultats clés](#child-objectives-and-key-results) confidentiels :
  - Pour rendre un objectif confidentiel : s'il possède des objectifs enfants ou des résultats clés, vous devez d'abord les rendre tous confidentiels ou les supprimer.
  - Pour rendre un objectif non confidentiel : s'il possède des objectifs enfants ou des résultats clés, vous devez d'abord les rendre tous non confidentiels ou les supprimer.
  - Pour ajouter des objectifs enfants ou des résultats clés à un objectif confidentiel, vous devez d'abord les rendre confidentiels.

Pour modifier la confidentialité d'un OKR existant :

1. [Ouvrez l'objectif](#view-an-objective) ou le [résultat clé](#view-a-key-result).
1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Activer la confidentialité** ou **Désactiver la confidentialité**.

### Qui peut voir les OKR confidentiels {#who-can-see-confidential-okrs}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Lorsqu'un OKR est rendu confidentiel, seuls les utilisateurs disposant du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet ont accès à l'OKR. Les utilisateurs avec les rôles Invité ou [Minimal](permissions.md#users-with-minimal-access) ne peuvent pas accéder à l'OKR, même s'ils y participaient activement avant le changement.

Cependant, un utilisateur avec le rôle Invité peut créer des OKR confidentiels, mais ne peut voir que ceux qu'il a créés lui-même.

Les utilisateurs avec le rôle Invité ou les non-membres peuvent lire l'OKR confidentiel s'ils y sont assignés. Lorsqu'un utilisateur Invité ou un non-membre est désassigné d'un OKR confidentiel, il ne peut plus le consulter.

Les OKR confidentiels sont masqués dans les résultats de recherche pour les utilisateurs ne disposant pas des permissions nécessaires.

### Indicateurs des OKR confidentiels {#confidential-okr-indicators}

Les OKR confidentiels sont visuellement différents des OKR ordinaires à plusieurs égards. Partout où les OKR sont listés, vous pouvez voir l'icône confidentiel ({{< icon name="eye-slash" >}}) à côté des OKR marqués comme confidentiels.

Si vous ne disposez pas des [permissions suffisantes](#who-can-see-confidential-okrs), vous ne pouvez pas voir les OKR confidentiels du tout.

De même, lorsque vous êtes dans un OKR, vous pouvez voir l'icône confidentiel ({{< icon name="eye-slash" >}}) juste à côté du fil d'Ariane.

Chaque changement de régulier à confidentiel et vice versa est indiqué par une note système dans les commentaires de l'OKR, par exemple :

- {{< icon name="eye-slash" >}} Jo Garcia a rendu le ticket confidentiel il y a 5 minutes
- {{< icon name="eye" >}} Jo Garcia a rendu le ticket visible pour tout le monde à l'instant

## Verrouiller la discussion {#lock-discussion}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/398649) dans GitLab 16.9 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_items_beta`. Fonctionnalité désactivée par défaut.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.
- Feature flag `work_items_beta` [supprimé](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549) dans GitLab 18.6.

{{< /history >}}

Vous pouvez empêcher les commentaires publics dans un OKR. Dans ce cas, seuls les membres du projet peuvent ajouter et modifier des commentaires.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire.

Pour verrouiller un OKR :

1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Verrouiller la discussion**.

Une note système est ajoutée aux détails de la page.

Si un OKR est fermé avec une discussion verrouillée, vous ne pouvez pas le rouvrir tant que la discussion n'est pas déverrouillée.

## Éléments liés dans les OKR {#linked-items-in-okrs}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/416558) dans GitLab 16.5 [avec le feature flag](../administration/feature_flags/_index.md) `linked_work_items`. Activés par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139394) dans GitLab 16.7.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150148) dans GitLab 17.0. Le feature flag `linked_work_items` a été supprimé.
- [Modification](https://gitlab.com/groups/gitlab-org/-/work_items/10267) du rôle minimum requis de Reporter (si vrai) à Invité dans GitLab 17.0.

{{< /history >}}

Les éléments liés constituent une relation bidirectionnelle et apparaissent dans un bloc sous les objectifs enfants et les résultats clés. Vous pouvez lier un objectif, un résultat clé ou une tâche du même projet entre eux.

La relation n'apparaît dans l'interface utilisateur que si l'utilisateur peut voir les deux éléments.

### Ajouter un élément lié {#add-a-linked-item}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Pour lier un élément à un objectif ou à un résultat clé :

1. Dans la section **Éléments liés** d'un objectif ou d'un résultat clé, sélectionnez **Ajouter**.
1. Sélectionnez la relation entre les deux éléments. L'une ou l'autre des options :
   - **Associé à**
   - **Bloque**
   - **Est bloqué par**
1. Saisissez le texte de recherche de l'élément, l'URL ou son identifiant de référence.
1. Lorsque vous avez ajouté tous les éléments à lier, sélectionnez **Ajouter** sous la zone de recherche.

Lorsque vous avez terminé d'ajouter tous les éléments liés, vous pouvez les voir classés pour mieux comprendre visuellement leurs relations.

![Éléments de travail liés classés comme bloquants, bloqués par ou associés à, avec des indicateurs de statut pour visualiser la progression et les dépendances.](img/linked_items_list_v16_5.png)

### Supprimer un élément lié {#remove-a-linked-item}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Développeur, Mainteneur ou Propriétaire pour le projet.

Dans la section **Éléments liés** d'un objectif ou d'un résultat clé, à côté de chaque élément, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.

En raison de la relation bidirectionnelle, la relation n'apparaît plus dans aucun des deux éléments.
