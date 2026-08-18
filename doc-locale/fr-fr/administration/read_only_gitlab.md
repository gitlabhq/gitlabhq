---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Placer GitLab en état lecture seule
description: Placer GitLab en état lecture seule.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> La méthode recommandée pour placer GitLab en état lecture seule est d'activer le [mode maintenance](maintenance_mode/_index.md).

Dans certains cas, vous pouvez souhaiter placer GitLab en état lecture seule. La configuration à effectuer dépend du résultat souhaité.

## Rendre les dépôts en lecture seule {#make-the-repositories-read-only}

La première chose à accomplir est de vous assurer qu'aucune modification ne peut être apportée à vos dépôts. Il existe deux façons d'y parvenir :

- Soit arrêter Puma pour rendre l'API interne inaccessible :

  ```shell
  sudo gitlab-ctl stop puma
  ```

- Ou bien, ouvrir une console Rails :

  ```shell
  sudo gitlab-rails console
  ```

  Et définir les dépôts de tous les projets en lecture seule :

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: true) }
  ```

  Pour définir uniquement un sous-ensemble de dépôts en lecture seule, exécutez la commande suivante :

  ```ruby
  # List of project IDs of projects to set to read-only.
  projects = [1,2,3]

  projects.each do |p|
   project =  Project.find p
   project.update!(repository_read_only: true)
   rescue ActiveRecord::RecordNotFound
   puts "Project ID #{p} not found"

  end
  ```

  Lorsque vous êtes prêt à annuler cette opération, remplacez `repository_read_only` par `false` sur les projets. Par exemple, exécutez la commande suivante :

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: false) }
  ```

## Arrêter l'interface utilisateur GitLab {#shut-down-the-gitlab-ui}

Si l'arrêt de l'interface utilisateur GitLab ne vous pose pas de problème, l'approche la plus simple consiste à arrêter `sidekiq` et `puma`, ce qui permet de s'assurer efficacement qu'aucune modification ne peut être apportée à GitLab :

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

Lorsque vous êtes prêt à annuler cette opération :

```shell
sudo gitlab-ctl start sidekiq
sudo gitlab-ctl start puma
```

## Rendre la base de données en lecture seule {#make-the-database-read-only}

Si vous souhaitez permettre aux utilisateurs d'utiliser l'interface utilisateur GitLab, assurez-vous que la base de données est en lecture seule :

1. Effectuez une [sauvegarde GitLab](backup_restore/_index.md) au cas où les choses ne se passeraient pas comme prévu.
1. Accédez à PostgreSQL sur la console en tant qu'utilisateur administrateur :

   ```shell
   sudo \
       -u gitlab-psql /opt/gitlab/embedded/bin/psql \
       -h /var/opt/gitlab/postgresql gitlabhq_production
   ```

1. Créez l'utilisateur `gitlab_read_only`. Le mot de passe est défini sur `mypassword`, modifiez-le selon vos préférences :

   ```sql
   -- NOTE: Use the password defined earlier
   CREATE USER gitlab_read_only WITH password 'mypassword';
   GRANT CONNECT ON DATABASE gitlabhq_production to gitlab_read_only;
   GRANT USAGE ON SCHEMA public TO gitlab_read_only;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO gitlab_read_only;
   GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO gitlab_read_only;

   -- Tables created by "gitlab" should be made read-only for "gitlab_read_only"
   -- automatically.
   ALTER DEFAULT PRIVILEGES FOR USER gitlab IN SCHEMA public GRANT SELECT ON TABLES TO gitlab_read_only;
   ALTER DEFAULT PRIVILEGES FOR USER gitlab IN SCHEMA public GRANT SELECT ON SEQUENCES TO gitlab_read_only;
   ```

1. Obtenez le mot de passe haché de l'utilisateur `gitlab_read_only` et copiez le résultat :

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_read_only
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez le mot de passe de l'étape précédente :

   ```ruby
   postgresql['sql_user_password'] = 'a2e20f823772650f039284619ab6f239'
   postgresql['sql_user'] = "gitlab_read_only"
   ```

1. Reconfigurez GitLab et redémarrez PostgreSQL :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

Lorsque vous êtes prêt à annuler l'état lecture seule, supprimez les lignes ajoutées dans `/etc/gitlab/gitlab.rb`, puis reconfigurez GitLab et redémarrez PostgreSQL :

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart postgresql
```

Après avoir vérifié que tout fonctionne comme prévu, supprimez l'utilisateur `gitlab_read_only` de la base de données.
