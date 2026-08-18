---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Effectuez des opérations en masse sur les utilisateurs et gérez les paramètres d'authentification à l'aide de tâches Rake."
title: Tâches Rake de gestion des utilisateurs
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour gérer les utilisateurs. Les administrateurs peuvent également utiliser la zone **Admin** pour [gérer les utilisateurs](../admin_area.md#administering-users).

## Ajouter un utilisateur en tant que développeur à tous les projets {#add-user-as-a-developer-to-all-projects}

Pour ajouter un utilisateur en tant que développeur à tous les projets, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## Ajouter tous les utilisateurs à tous les projets {#add-all-users-to-all-projects}

Pour ajouter tous les utilisateurs à tous les projets, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

Les administrateurs sont ajoutés en tant que responsables et tous les autres utilisateurs sont ajoutés en tant que développeurs.

## Ajouter un utilisateur en tant que développeur à tous les groupes {#add-user-as-a-developer-to-all-groups}

Pour ajouter un utilisateur en tant que développeur à tous les groupes, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## Ajouter tous les utilisateurs à tous les groupes {#add-all-users-to-all-groups}

Pour ajouter tous les utilisateurs à tous les groupes, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

Les administrateurs sont ajoutés en tant que propriétaires afin qu'ils puissent ajouter des utilisateurs supplémentaires au groupe.

## Mettre à jour tous les utilisateurs d'un groupe donné vers `project_limit:0` et `can_create_group: false` {#update-all-users-in-a-given-group-to-project_limit0-and-can_create_group-false}

Pour mettre à jour tous les utilisateurs d'un groupe donné vers `project_limit: 0` et `can_create_group: false`, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:user_management:disable_project_and_group_creation\[:group_id\]

# installation from source
bundle exec rake gitlab:user_management:disable_project_and_group_creation\[:group_id\] RAILS_ENV=production
```

Cette opération met à jour tous les utilisateurs du groupe donné, de ses sous-groupes et des projets dans cet espace de nommage de groupe, avec les limites indiquées.

## Contrôler le nombre d'utilisateurs facturables {#control-the-number-of-billable-users}

Activez ce paramètre pour que les nouveaux utilisateurs restent bloqués jusqu'à ce qu'ils aient été validés par l'administrateur. La valeur par défaut est `false` :

```plaintext
block_auto_created_users: false
```

## Désactiver l'authentification à deux facteurs pour tous les utilisateurs {#disable-two-factor-authentication-for-all-users}

Cette tâche désactive l'authentification à deux facteurs (2FA) pour tous les utilisateurs qui l'ont activée. Cela peut être utile si le fichier `config/secrets.yml` de GitLab a été perdu et que les utilisateurs ne peuvent pas se connecter, par exemple.

Pour désactiver l'authentification à deux facteurs pour tous les utilisateurs, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## Faire pivoter la clé de chiffrement de l'authentification à deux facteurs {#rotate-two-factor-authentication-encryption-key}

GitLab stocke les données secrètes requises pour l'authentification à deux facteurs (2FA) dans une colonne de base de données chiffrée. La clé de chiffrement de ces données est désignée par `otp_key_base` et est stockée dans `config/secrets.yml`.

Si ce fichier est divulgué, mais que les secrets 2FA individuels ne l'ont pas été, il est possible de re-chiffrer ces secrets avec une nouvelle clé de chiffrement. Cela vous permet de modifier la clé divulguée sans obliger tous les utilisateurs à modifier leurs informations 2FA.

Pour faire pivoter la clé de chiffrement de l'authentification à deux facteurs :

1. Recherchez l'ancienne clé dans le fichier `config/secrets.yml`, mais **assurez-vous que vous travaillez avec la section en production**. La ligne qui vous intéresse ressemble à ceci :

   ```yaml
   production:
     otp_key_base: fffffffffffffffffffffffffffffffffffffffffffffff
   ```

1. Générez un nouveau secret :

   ```shell
   # omnibus-gitlab
   sudo gitlab-rake secret

   # installation from source
   bundle exec rake secret RAILS_ENV=production
   ```

1. Arrêtez le serveur GitLab, sauvegardez le fichier de secrets existant et mettez à jour la base de données :

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl stop
   sudo cp config/secrets.yml config/secrets.yml.bak
   sudo gitlab-rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key>

   # installation from source
   sudo /etc/init.d/gitlab stop
   cp config/secrets.yml config/secrets.yml.bak
   bundle exec rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key> RAILS_ENV=production
   ```

   La valeur `<old key>` peut être lue depuis `config/secrets.yml` (`<new key>` a été générée précédemment). Les valeurs **chiffrées** des secrets 2FA des utilisateurs sont écrites dans le `filename` spécifié. Vous pouvez l'utiliser pour effectuer une restauration en cas d'erreur.

1. Modifiez `config/secrets.yml` pour définir `otp_key_base` sur `<new key>` et redémarrez. Assurez-vous à nouveau d'opérer dans la section de **production**.

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl start

   # installation from source
   sudo /etc/init.d/gitlab start
   ```

En cas de problème (peut-être en utilisant une mauvaise valeur pour `old_key`), vous pouvez restaurer votre sauvegarde de `config/secrets.yml` et annuler les modifications :

```shell
# omnibus-gitlab
sudo gitlab-ctl stop
sudo gitlab-rake gitlab:two_factor:rotate_key:rollback filename=backup.csv
sudo cp config/secrets.yml.bak config/secrets.yml
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
bundle exec rake gitlab:two_factor:rotate_key:rollback filename=backup.csv RAILS_ENV=production
cp config/secrets.yml.bak config/secrets.yml
sudo /etc/init.d/gitlab start

```

## Attribuer des utilisateurs en masse à GitLab Duo {#bulk-assign-users-to-gitlab-duo}

Vous pouvez attribuer des utilisateurs en masse à GitLab Duo à l'aide d'un fichier CSV contenant les noms des utilisateurs. Le fichier CSV doit avoir un en-tête nommé `username`, suivi des noms d'utilisateur sur chaque ligne suivante.

```plaintext
username
user1
user2
user3
user4
```

### GitLab Duo Pro {#gitlab-duo-pro}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142189) dans GitLab 16.9.

{{< /history >}}

Pour effectuer une attribution d'utilisateurs en masse pour GitLab Duo Pro, vous pouvez utiliser la tâche Rake suivante :

```shell
bundle exec rake duo_pro:bulk_user_assignment DUO_PRO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

Si vous préférez utiliser des crochets dans le chemin du fichier, vous pouvez les échapper ou utiliser des guillemets doubles :

```shell
bundle exec rake duo_pro:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "duo_pro:bulk_user_assignment[path/to/your/file.csv]"
```

### GitLab Duo Pro et Enterprise {#gitlab-duo-pro-and-enterprise}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187230) dans GitLab 18.0.

{{< /history >}}

#### GitLab Self-Managed {#gitlab-self-managed}

Cette tâche Rake attribue en masse des sièges GitLab Duo Pro ou Enterprise au niveau de l'instance à une liste d'utilisateurs à partir d'un fichier CSV, en fonction du module complémentaire acheté disponible.

Pour effectuer une attribution d'utilisateurs en masse pour une instance GitLab Self-Managed :

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

Si vous préférez utiliser des crochets dans le chemin du fichier, vous pouvez les échapper ou utiliser des guillemets doubles :

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv]"
```

#### GitLab.com {#gitlabcom}

Les administrateurs de GitLab.com peuvent également utiliser cette tâche Rake pour attribuer en masse des sièges GitLab Duo Pro ou Enterprise pour les groupes GitLab.com, en fonction du module complémentaire acheté disponible pour ce groupe.

Pour effectuer une attribution d'utilisateurs en masse pour un groupe GitLab.com :

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv NAMESPACE_ID=<namespace_id>
```

Si vous préférez utiliser des crochets dans le chemin du fichier, vous pouvez les échapper ou utiliser des guillemets doubles :

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv','<namespace_id>'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv,<namespace_id>]"
```

## Dépannage {#troubleshooting}

### Erreurs lors de l'attribution d'utilisateurs en masse {#errors-during-bulk-user-assignment}

Lorsque vous utilisez la tâche Rake pour l'attribution d'utilisateurs en masse, vous pouvez rencontrer les erreurs suivantes :

- `User is not found` : L'utilisateur spécifié n'a pas été trouvé. Veuillez vous assurer que le nom d'utilisateur fourni correspond à un utilisateur existant.
- `ERROR_NO_SEATS_AVAILABLE` : Il n'y a plus de sièges disponibles pour l'attribution d'utilisateurs. Veuillez consulter comment [afficher les utilisateurs GitLab Duo attribués](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) pour vérifier les attributions de sièges actuelles.
- `ERROR_INVALID_USER_MEMBERSHIP` : L'utilisateur n'est pas éligible à l'attribution car il est inactif, un bot ou un fantôme. Veuillez vous assurer que l'utilisateur est actif et, s'il est sur GitLab.com, membre de l'espace de nommage fourni.

## Sujets connexes {#related-topics}

- [Réinitialiser les mots de passe des utilisateurs](../../security/reset_user_password.md#use-a-rake-task)
