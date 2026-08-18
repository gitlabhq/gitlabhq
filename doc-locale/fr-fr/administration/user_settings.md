---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les paramètres utilisateur à l'échelle de l'instance, comme la création de groupes et les modifications de noms d'utilisateur."
title: Modifier les paramètres utilisateur globaux
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez modifier les paramètres de chaque utilisateur dans votre instance GitLab.

Prérequis :

- Vous devez être un administrateur de l'instance.

## Empêcher les utilisateurs de créer des groupes principaux {#prevent-users-from-creating-top-level-groups}

Vous pouvez empêcher les utilisateurs de créer des groupes principaux.

Lorsque la création de groupe est interdite :

- Les utilisateurs ne peuvent pas créer de groupes principaux.
- Les utilisateurs peuvent créer des sous-groupes dans des groupes où ils ont le rôle Maintainer ou Owner, selon les [autorisations de création de sous-groupes](../user/group/subgroups/_index.md#change-who-can-create-subgroups) pour le groupe.

Pour empêcher les utilisateurs de créer des groupes principaux, utilisez l'une de ces méthodes :

| Méthode        | Pour les nouveaux utilisateurs                                                                                                         | Pour les utilisateurs existants |
| ------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------ |
| Interface utilisateur            | [Paramètres de compte et de limites](settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups) | [Paramètres utilisateur dans la zone d'administration](admin_area.md#prevent-a-user-from-creating-top-level-groups) |
| API           | [API des paramètres d'application](../api/settings.md#update-application-settings) pour modifier le paramètre `can_create_group`   | [API utilisateurs](../api/users.md#modify-a-user) pour modifier le paramètre `can_create_group` |
| Console Rails | Aucune                                                                                                                  | [Utiliser la console Rails](#use-the-rails-console) |

### Utiliser la console Rails {#use-the-rails-console}

Vous pouvez utiliser la console Rails pour empêcher les utilisateurs existants de créer des groupes principaux. Utilisez cette méthode pour effectuer des mises à jour en masse sur plusieurs utilisateurs.

Pour empêcher les utilisateurs existants de créer des groupes principaux :

1. Démarrez une [session de console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez l'une de ces commandes :

   - Pour empêcher la création de groupe pour tous les utilisateurs existants sauf les administrateurs :

     ```ruby
     User.where.not(admin: true).update_all(can_create_group: false)
     ```

   - Pour empêcher la création de groupe pour un utilisateur spécifique :

     ```ruby
     User.find_by(username: 'someuser').update(can_create_group: false)
     ```

1. Quittez la console :

   ```ruby
   exit
   ```

## Empêcher les utilisateurs de modifier leurs noms d'utilisateur {#prevent-users-from-changing-their-usernames}

Par défaut, les utilisateurs peuvent modifier leurs noms d'utilisateur. Pour empêcher les utilisateurs de modifier leurs noms d'utilisateur :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [Reconfigurer et redémarrer GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yml` et décommentez la ligne suivante :

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [Redémarrer GitLab](restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

## Empêcher les utilisateurs Guest d'être promus à un rôle supérieur {#prevent-guest-users-from-promoting-to-a-higher-role}

Sur GitLab Ultimate, les utilisateurs Guest ne sont pas comptabilisés dans les sièges payants. Cependant, lorsqu'un utilisateur Guest crée des projets et des espaces de nommage, il est automatiquement promu à un rôle supérieur à Guest et occupe un siège payant.

Pour empêcher les utilisateurs Guest d'être promus à un rôle supérieur et d'occuper un siège payant, définissez l'utilisateur comme [externe](external_users.md).

Les utilisateurs externes ne peuvent pas créer de projets personnels ni des espaces de nommage. Si un utilisateur avec le rôle Guest est promu à un rôle supérieur par un autre utilisateur, le paramètre d'utilisateur externe doit être supprimé avant qu'il puisse créer des projets personnels ou des espaces de nommage. Pour obtenir la liste complète des restrictions pour les utilisateurs externes, consultez [Utilisateurs externes](external_users.md).
