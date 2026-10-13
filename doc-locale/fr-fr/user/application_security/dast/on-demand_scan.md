---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créer, afficher, modifier, supprimer et exécuter des analyses DAST à la demande."
title: Analyse DAST à la demande
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> N'exécutez pas d'analyses DAST contre un serveur de production. Non seulement elle peut effectuer toutes les fonctions qu'un utilisateur peut réaliser, comme cliquer sur des boutons ou soumettre des formulaires, mais elle peut également déclencher des bugs, entraînant la modification ou la perte de données de production. Exécutez les analyses DAST uniquement contre un serveur de test.

## Analyses à la demande {#on-demand-scans}

{{< history >}}

- Les analyses DAST à la demande basées sur un navigateur sont disponibles dans GitLab 17.0 et versions ultérieures, car [le DAST basé sur un proxy a été supprimé dans la même version](../../../update/deprecations.md#proxy-based-dast-deprecated).

{{< /history >}}

Une analyse DAST à la demande s'exécute en dehors du cycle de vie DevOps. Les modifications apportées à votre dépôt ne déclenchent pas l'analyse. Vous devez soit la démarrer manuellement, soit la planifier. Pour les analyses DAST à la demande, un [profil de site](profiles.md#site-profile) définit **ce qui** doit être analysé, et un [profil de scanner](profiles.md#scanner-profile) définit **comment** l'application doit être analysée.

Une analyse à la demande peut être exécutée en mode actif ou passif :

- **Passive mode** : le mode par défaut, qui exécute une [analyse passive basée sur un navigateur](browser/_index.md#passive-scans).
- **Active mode** : exécute une [analyse active basée sur un navigateur](browser/_index.md#active-scans) qui peut être potentiellement dangereuse pour le site analysé. Pour minimiser le risque de dommages accidentels, l'exécution d'une analyse active nécessite un [profil de site validé](profiles.md#site-profile-validation).

### Afficher les analyses DAST à la demande {#view-on-demand-dast-scans}

Pour afficher les analyses à la demande :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.

Les analyses à la demande sont regroupées par statut. La bibliothèque de numérisation contient toutes les analyses à la demande disponibles.

### Exécuter une analyse DAST à la demande {#run-an-on-demand-dast-scan}

Prérequis :

- Vous devez disposer de l'autorisation d'exécuter une analyse DAST à la demande contre une branche protégée. La branche par défaut est automatiquement protégée. Pour plus d'informations, consultez [Sécurité des pipelines sur les branches protégées](../../../ci/pipelines/_index.md#pipeline-security-on-protected-branches).

Pour exécuter une analyse à la demande existante :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.
1. Sélectionnez l'onglet **Bibliothèque de numérisation**.
1. Dans la ligne de l'analyse, sélectionnez **Exécuter l'analyse**.

   Si la branche enregistrée dans l'analyse n'existe plus, vous devez :

   1. [Modifier l'analyse](#edit-an-on-demand-scan).
   1. Sélectionner une nouvelle branche.
   1. Enregistrer l'analyse modifiée.

L'analyse DAST à la demande s'exécute et le tableau de bord du projet affiche les résultats.

#### Créer une analyse à la demande {#create-an-on-demand-scan}

Créez une analyse à la demande pour :

- L'exécuter immédiatement.
- L'enregistrer pour une exécution ultérieure.
- La planifier selon un calendrier défini.

Pour créer une analyse DAST à la demande :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.
1. Sélectionnez **Nouvelle analyse**.
1. Renseignez les champs **Nom de l'analyse** et **Description**.
1. Dans la liste déroulante **Branche**, sélectionnez la branche souhaitée.
1. Facultatif. Sélectionnez les tags du runner.
1. Sélectionnez **Sélectionner le profil du scanner** ou **Modifier le profil du scanner** pour ouvrir le panneau, puis :
   - Sélectionnez un profil de scanner dans le panneau, **ou**
   - Sélectionnez **Nouveau profil**, créez un [profil de scanner](profiles.md#scanner-profile), puis sélectionnez **Enregistrer le profil**.
1. Sélectionnez **Sélectionner le profil du site** ou **Modifier le profil du site** pour ouvrir le panneau, puis :
   - Sélectionnez un profil de site dans le panneau **Site profile library**, ou
   - Sélectionnez **Nouveau profil**, créez un [profil de site](profiles.md#site-profile), puis sélectionnez **Enregistrer le profil**.
1. Pour exécuter l'analyse à la demande :

   - Immédiatement, sélectionnez **Enregistrer et exécuter l'analyse**.
   - Ultérieurement, sélectionnez **Enregistrer l'analyse**.
   - Selon une planification :

     - Activez le bouton bascule **Activer la planification d'analyse**.
     - Renseignez les champs de planification.
     - Sélectionnez **Enregistrer l'analyse**.

L'analyse DAST à la demande s'exécute comme spécifié et le tableau de bord du projet affiche les résultats.

### Afficher les détails d'une analyse à la demande {#view-details-of-an-on-demand-scan}

Prérequis :

- Vous devez pouvoir pousser vers la branche associée à l'analyse DAST.

Pour afficher les détails d'une analyse à la demande :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.
1. Sélectionnez l'onglet **Bibliothèque de numérisation**.
1. Dans la ligne de l'analyse enregistrée, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Modifier**.

### Modifier une analyse à la demande {#edit-an-on-demand-scan}

Prérequis :

- Vous devez pouvoir pousser vers la branche associée à l'analyse DAST.

Pour modifier une analyse à la demande :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.
1. Sélectionnez l'onglet **Bibliothèque de numérisation**.
1. Dans la ligne de l'analyse enregistrée, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Modifier**.
1. Modifiez les détails de l'analyse enregistrée.
1. Sélectionnez **Enregistrer l'analyse**.

### Supprimer une analyse à la demande {#delete-an-on-demand-scan}

Pour supprimer une analyse à la demande :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Analyses à la demande**.
1. Sélectionnez l'onglet **Bibliothèque de numérisation**.
1. Dans la ligne de l'analyse enregistrée, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer**.
