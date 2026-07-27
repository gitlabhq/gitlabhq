---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisateurs internes
description: Activez les opérations système automatisées via des utilisateurs bots internes pour les fonctionnalités de GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584) dans GitLab 15.4, les bots sont indiqués par un badge dans les listes d'utilisateurs.

{{< /history >}}

GitLab utilise des utilisateurs internes (parfois appelés « bots ») pour effectuer des actions ou des fonctions qui ne peuvent pas être attribuées à un utilisateur ordinaire.

Utilisateurs internes :

- Sont créés automatiquement par GitLab et ne sont pas comptabilisés dans la limite de licence. Vous ne pouvez pas créer d'utilisateurs internes manuellement.
- Sont utilisés lorsqu'un compte utilisateur traditionnel n'est pas applicable. Par exemple, lors de la génération d'alertes ou de retours de révision automatiques.
- Ont un accès réduit et un objectif très spécifique. Ils ne peuvent pas être utilisés pour des actions utilisateur ordinaires, telles que l'authentification ou les requêtes API.
- Ont des adresses e-mail et des noms qui peuvent être attribués aux actions qu'ils effectuent.

Les utilisateurs internes sont parfois créés dans le cadre du développement de fonctionnalités. Par exemple, le GitLab Migration Bot pour [migrer](https://gitlab.com/gitlab-org/gitlab/-/issues/216120) depuis GitLab Snippets vers les [Versioned Snippets](../user/snippets.md#versioned-snippets). GitLab Migration Bot était utilisé comme auteur des snippets lorsque l'auteur original d'un snippet n'était pas disponible. Par exemple, lorsque l'utilisateur était désactivé.

Autres exemples d'utilisateurs internes :

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [Alert Bot](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
- [Utilisateur fictif](../user/import/mapping/post_migration_mapping.md#placeholder-users) créé lors des importations
- Visual Review Bot
- Les jetons d'accès aux ressources, y compris les [jetons d'accès au projet](../user/project/settings/project_access_tokens.md) et les [jetons d'accès aux groupes](../user/group/settings/group_access_tokens.md), qui sont des utilisateurs `project_{project_id}_bot_{random_string}` et `group_{group_id}_bot_{random_string}` avec un `PersonalAccessToken`.

## GitLab Admin Bot {#gitlab-admin-bot}

[GitLab Admin Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104) est un utilisateur interne qui ne peut pas être consulté ou modifié par des utilisateurs ordinaires et qui est responsable de nombreuses tâches, notamment :

- Application des [frameworks de conformité par défaut](../user/compliance/compliance_frameworks/_index.md#default-compliance-frameworks) aux projets.
- [Désactivation automatique des utilisateurs dormants](moderate_users.md#automatically-deactivate-dormant-users).
- [Suppression automatique des utilisateurs non confirmés](moderate_users.md#automatically-delete-unconfirmed-users).
- [Suppression des projets dormants](dormant_project_deletion.md).
- [Verrouillage des utilisateurs](../security/unlock_user.md).

## GitLab Security Bot {#gitlab-security-bot}

GitLab Security Bot est un utilisateur interne chargé de commenter les merge requests qui violent une [politique de sécurité](../user/application_security/policies/_index.md).

## GitLab Security Policy Bot {#gitlab-security-policy-bot}

GitLab Security Policy Bot est un utilisateur interne chargé de déclencher les pipelines planifiés définis dans les [politiques de sécurité](../user/application_security/policies/_index.md#gitlab-security-policy-bot-user). Ce compte est créé dans chaque projet sur lequel une politique de sécurité est appliquée.

Pour les politiques d'exécution de pipeline planifiées, ce bot peut lire la configuration CI/CD depuis des projets privés lorsque les propriétaires du projet autorisent explicitement l'accès.

L'accès du bot est soumis aux limites suivantes :

- Le projet cible doit activer **Accès des bots chargés de la politique de sécurité**.
- Le chemin de fichier demandé doit correspondre aux modèles de fichiers autorisés du projet.
- Le projet du bot doit se trouver dans la hiérarchie de groupes autorisée. Si aucun groupe n'est configuré, GitLab utilise le groupe ancêtre racine.

Pour configurer l'accès de Security Policy Bot, consultez les [politiques d'exécution de pipeline planifiées](../user/application_security/policies/scheduled_pipeline_execution_policies.md#option-2-allow-security-policy-bot-access-to-private-projects).
