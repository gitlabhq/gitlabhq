---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Modifier les mots de passe des utilisateurs via l'interface utilisateur, les tâches Rake, la console Rails ou l'API."
title: Réinitialiser les mots de passe des utilisateurs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez réinitialiser les mots de passe des utilisateurs via l'interface utilisateur, une tâche Rake, une console Rails ou l'[API Users](../api/users.md#modify-a-user).

## Prérequis {#prerequisites}

- Vous devez être administrateur de l'instance.
- Le mot de passe doit respecter toutes les [exigences relatives aux mots de passe](../user/profile/user_passwords.md#password-requirements).

## Utiliser l'interface utilisateur {#use-the-ui}

Pour réinitialiser le mot de passe d'un utilisateur via l'interface utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Identifiez un compte utilisateur à mettre à jour, puis sélectionnez **Éditer**.
1. Dans la section **Mot de passe**, saisissez et confirmez un nouveau mot de passe.
1. Sélectionnez **Enregistrer les modifications**.

GitLab met à jour le mot de passe de l'utilisateur.

## Utiliser une tâche Rake {#use-a-rake-task}

Pour réinitialiser le mot de passe d'un utilisateur avec une tâche Rake :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake "gitlab:password:reset"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake "gitlab:password:reset"
```

{{< /tab >}}

{{< /tabs >}}

GitLab demande un nom d'utilisateur, un mot de passe et la confirmation du mot de passe. Une fois l'opération terminée, le mot de passe de l'utilisateur est mis à jour.

La tâche Rake peut accepter un nom d'utilisateur comme argument. Par exemple, pour réinitialiser le mot de passe de l'utilisateur avec le nom d'utilisateur `sidneyjones` :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

  ```shell
  sudo gitlab-rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

  ```shell
  bundle exec rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< /tabs >}}

## Utiliser une console Rails {#use-a-rails-console}

Pour réinitialiser le mot de passe d'un utilisateur depuis une console Rails :

Prérequis :

- Vous devez connaître le nom d'utilisateur, l'identifiant utilisateur ou l'adresse e-mail associés.

1. Démarrez une [session de console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Trouvez l'utilisateur :

   - Par nom d'utilisateur :

     ```ruby
     user = User.find_by_username 'exampleuser'
     ```

   - Par identifiant utilisateur :

     ```ruby
     user = User.find(123)
     ```

   - Par adresse e-mail :

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. Réinitialisez le mot de passe en définissant une valeur pour `user.password` et `user.password_confirmation`. Par exemple, pour définir un nouveau mot de passe aléatoire :

   ```ruby
   new_password = ::User.random_password
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

   Pour définir une valeur spécifique pour le nouveau mot de passe :

   ```ruby
   new_password = 'examplepassword'
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

1. Facultatif. Informez l'utilisateur qu'un administrateur a modifié son mot de passe :

   ```ruby
   user.send_only_admin_changed_your_password_notification!
   ```

1. Enregistrez les modifications :

   ```ruby
   user.save!
   ```

1. Quittez la console :

   ```ruby
   exit
   ```

## Réinitialiser le mot de passe root {#reset-the-root-password}

Vous pouvez réinitialiser le mot de passe root via les processus [Tâche Rake](#use-a-rake-task) ou [Console Rails](#use-a-rails-console) décrits précédemment.

- Si le nom du compte root n'a pas changé, utilisez le nom d'utilisateur `root`.
- Si le nom du compte root a changé et que vous ne connaissez pas le nouveau nom d'utilisateur, vous pourriez utiliser une console Rails avec l'identifiant utilisateur `1`. Dans presque tous les cas, le premier utilisateur est le compte administrateur par défaut.

## Dépannage {#troubleshooting}

Utilisez les informations suivantes pour résoudre les problèmes liés à la réinitialisation d'un mot de passe utilisateur.

### Problèmes de confirmation par e-mail {#email-confirmation-issues}

Si le nouveau mot de passe ne fonctionne pas, il peut s'agir d'un problème de confirmation par e-mail. Vous pouvez tenter de résoudre ce problème dans une console Rails. Par exemple, si un nouveau mot de passe `root` ne fonctionne pas :

1. Démarrez une [console Rails](../administration/operations/rails_console.md).
1. Trouvez l'utilisateur et ignorez la reconfirmation :

   ```ruby
   user = User.find(1)
   user.skip_reconfirmation!
   ```

1. Tentez de vous reconnecter.

### Exigences relatives aux mots de passe non respectées {#unmet-password-requirements}

Le mot de passe est peut-être trop court, trop faible ou ne respecte pas les exigences de complexité. Assurez-vous que le mot de passe que vous tentez de définir respecte toutes les [exigences relatives aux mots de passe](../user/profile/user_passwords.md#password-requirements).

### Mot de passe expiré {#expired-password}

Si le mot de passe d'un utilisateur a précédemment expiré, vous devrez peut-être mettre à jour la date d'expiration du mot de passe. Pour plus d'informations, consultez [Erreur de mot de passe expiré lors d'un Git fetch avec SSH pour un utilisateur LDAP](../topics/git/troubleshooting_git.md#your-password-expired-error-on-git-fetch-with-ssh-for-ldap-user).
