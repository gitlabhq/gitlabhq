---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisateurs auditeurs
description: "Fournir un accès en lecture seule pour l'audit et la surveillance de la conformité sur toutes les ressources."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs auditeurs ont un accès en lecture seule à tous les groupes, projets et autres ressources de l'instance.

Les utilisateurs auditeurs :

- Ont un accès en lecture seule à tous les groupes et projets.
  - En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/542815), les utilisateurs doivent avoir le rôle Reporter, Developer, Maintainer ou Owner pour effectuer des tâches en lecture seule.
- Peuvent avoir des [permissions](../user/permissions.md) supplémentaires sur les groupes et les projets en fonction de leur rôle attribué.
- Peuvent créer des groupes, des projets ou des extraits de code dans leur espace de nommage personnel.
- Ne peuvent pas consulter la zone d'administration ni effectuer d'actions d'administration.
- Ne peuvent pas accéder aux paramètres du groupe ou des projets.
- Ne peuvent pas consulter les job logs lorsque la [journalisation de débogage](../ci/variables/variables_troubleshooting.md#enable-debug-logging) est activée.
- Ne peuvent pas accéder aux zones conçues pour la modification, notamment l'[éditeur de pipeline](../ci/pipeline_editor/_index.md).

Les utilisateurs auditeurs sont parfois utilisés dans les situations suivantes :

- Une organisation doit tester la conformité aux politiques de sécurité sur l'ensemble d'une instance GitLab. Un utilisateur auditeur peut le faire sans être ajouté à chaque projet ni disposer d'un accès administrateur.
- Un utilisateur spécifique doit consulter un grand nombre de projets dans l'instance GitLab. Au lieu d'ajouter manuellement l'utilisateur à chaque projet, vous pouvez créer un utilisateur auditeur qui peut accéder automatiquement à chaque projet.

> [!note]
> Un utilisateur auditeur est comptabilisé comme un utilisateur facturable et consomme un siège de licence.

## Créer un utilisateur auditeur {#create-an-auditor-user}

Prérequis :

- Accès administrateur.

Pour créer un nouvel utilisateur auditeur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez **Nouvel utilisateur**.
1. Dans la section **Compte**, saisissez les informations de compte requises.
1. Pour **Type d'utilisateur/utilisatrice**, sélectionnez **Auditeur**.
1. Sélectionnez **Créer un utilisateur**.

Vous pouvez également créer des utilisateurs auditeurs avec :

- [Groupes SAML](../integration/saml.md#auditor-groups).
- L'[API utilisateurs](../api/users.md).
