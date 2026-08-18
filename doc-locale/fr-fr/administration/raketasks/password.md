---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de maintenance des mots de passe
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour la gestion des mots de passe.

## Réinitialiser les mots de passe {#reset-passwords}

Pour réinitialiser un mot de passe à l'aide d'une tâche Rake, consultez [réinitialiser les mots de passe des utilisateurs](../../security/reset_user_password.md#use-a-rake-task).

## Vérifier les hachages de mots de passe {#check-password-hashes}

À partir de GitLab 17.11, les sels des hachages de mots de passe sur les instances FIPS sont augmentés lorsqu'un utilisateur se connecte.

Les instances non FIPS ont commencé à utiliser un facteur de travail bcrypt mis à jour dans GitLab 17.9.

Vous pouvez vérifier combien d'utilisateurs ont des hachages de mots de passe non migrés :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:password:check_hashes:[true]

# installation from source
bundle exec rake gitlab:password:check_hashes:[true] RAILS_ENV=production
```

> [!note]
> Avant GitLab 18.6, cette tâche était disponible sous le nom `gitlab:password:fips_check_salts` et était limitée à la validation des hachages FIPS/PBKDF2. La tâche a été renommée en `:check_hashes` et vérifie désormais toutes les migrations de mots de passe, tandis que l'ancien nom reste disponible en tant qu'alias.
