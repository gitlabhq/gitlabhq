---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurez les approbations de merge request pour votre instance GitLab.
title: Approbations de merge request
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les règles d'approbation des merge request empêchent les utilisateurs de contourner certains paramètres de projet. Lorsqu'elles sont activées, ces paramètres sont [appliqués à tous les projets et groupes](../user/project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group) de l'instance.

Ces paramètres d'approbation de merge request peuvent être définis pour l'ensemble de l'instance :

- **Empêcher l'approbation des requêtes de fusion par leur auteur ou autrice**. Empêche les mainteneurs de projet d'autoriser les auteurs de merge request à approuver leurs propres merge request.
- **Empêcher les approbations par les utilisateurs qui ajoutent des validations**. Empêche les mainteneurs de projet d'autoriser les utilisateurs à approuver des merge request s'ils ont soumis des commits sur la branche source.
- **Empêcher la modification des règles d'approbation dans les projets et les requêtes de fusion**. Empêche les utilisateurs de modifier la liste des approbateurs dans les paramètres du projet ou dans les merge request individuelles. Contrairement aux paramètres équivalents de groupe et de projet, qui empêchent uniquement les remplacements sur les merge request individuelles, ce paramètre d'instance verrouille également la liste des règles d'approbation dans les paramètres du projet.

Les éléments suivants sont également affectés par les règles définies pour l'ensemble de l'instance :

- [Règles d'approbation des merge requests de projet](../user/project/merge_requests/approvals/_index.md).
- [Paramètres d'approbation des merge requests de groupe](../user/group/manage.md#group-merge-request-approval-settings).

## Activer les paramètres d'approbation de merge request pour une instance {#enable-merge-request-approval-settings-for-an-instance}

Prérequis :

- Accès administrateur.

Pour activer les paramètres d'approbation de merge request :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Règles de poussée**.
1. Développez **Approbations des requêtes de fusion**.
1. Cochez la case correspondant à l'une des règles d'approbation.
1. Sélectionnez **Sauvegarder les modifications**.
