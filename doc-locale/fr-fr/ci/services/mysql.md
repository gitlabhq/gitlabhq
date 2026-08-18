---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser MySQL
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

De nombreuses applications dépendent de MySQL comme base de données, et vous pourriez en avoir besoin pour exécuter vos tests.

## Utiliser MySQL avec l'exécuteur Docker {#use-mysql-with-the-docker-executor}

Si vous souhaitez utiliser un conteneur MySQL, vous pouvez utiliser [GitLab Runner](../runners/_index.md) avec l'exécuteur Docker.

Cet exemple vous montre comment définir un nom d'utilisateur et un mot de passe que GitLab utilise pour accéder au conteneur MySQL. Si vous ne définissez pas de nom d'utilisateur et de mot de passe, vous devez utiliser `root`.

> [!note]
> Les variables définies dans l'interface utilisateur de GitLab ne sont pas transmises aux conteneurs de service. Pour plus d'informations, consultez [les variables CI/CD GitLab](../variables/_index.md).

1. Pour spécifier une image MySQL, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

   ```yaml
   services:
     - mysql:latest
   ```

   - Vous pouvez utiliser n'importe quelle image Docker disponible sur [Docker Hub](https://hub.docker.com/_/mysql/). Par exemple, pour utiliser MySQL 5.5, utilisez `mysql:5.5`.
   - L'image `mysql` peut accepter des variables d'environnement. Pour plus d'informations, consultez la [documentation Docker Hub](https://hub.docker.com/_/mysql/).

1. Pour inclure le nom de la base de données et le mot de passe, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

   ```yaml
   variables:
     # Configure mysql environment variables (https://hub.docker.com/_/mysql/)
     MYSQL_DATABASE: $MYSQL_DB
     MYSQL_ROOT_PASSWORD: $MYSQL_PASS
   ```

   Le conteneur MySQL utilise `MYSQL_DATABASE` et `MYSQL_ROOT_PASSWORD` pour se connecter à la base de données. Transmettez ces valeurs en utilisant les [variables CI/CD GitLab](../variables/_index.md) (`$MYSQL_DB` et `$MYSQL_PASS` dans l'exemple ci-dessus), [plutôt que de les appeler directement](https://gitlab.com/gitlab-org/gitlab/-/issues/30178).

1. Configurez votre application pour utiliser la base de données, par exemple :

   ```yaml
   Host: mysql
   User: runner
   Password: <your_mysql_password>
   Database: <your_mysql_database>
   ```

   Dans cet exemple, l'utilisateur est `runner`. Vous devez utiliser un utilisateur disposant des autorisations nécessaires pour accéder à votre base de données.

## Utiliser MySQL avec l'exécuteur Shell {#use-mysql-with-the-shell-executor}

Vous pouvez également utiliser MySQL sur des serveurs configurés manuellement qui utilisent GitLab Runner avec l'exécuteur Shell.

1. Installez le serveur MySQL :

   ```shell
   sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
   ```

1. Choisissez un mot de passe root MySQL et saisissez-le deux fois lorsqu'on vous le demande.

   > [!note]
   > Par mesure de sécurité, vous pouvez exécuter `mysql_secure_installation` pour supprimer les utilisateurs anonymes, supprimer la base de données de test et désactiver les connexions distantes de l'utilisateur root.

1. Créez un utilisateur en vous connectant à MySQL en tant que root :

   ```shell
   mysql -u root -p
   ```

1. Créez un utilisateur (dans ce cas, `runner`) utilisé par votre application. Remplacez `$password` dans la commande par un mot de passe fort.

   À l'invite `mysql>`, saisissez :

   ```sql
   CREATE USER 'runner'@'localhost' IDENTIFIED BY '$password';
   ```

1. Créez la base de données :

   ```sql
   CREATE DATABASE IF NOT EXISTS `<your_mysql_database>` DEFAULT CHARACTER SET `utf8` \
   COLLATE `utf8_unicode_ci`;
   ```

1. Accordez les autorisations nécessaires sur la base de données :

   ```sql
   GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `<your_mysql_database>`.* TO 'runner'@'localhost';
   ```

1. Si tout s'est bien passé, vous pouvez quitter la session de base de données :

   ```shell
   \q
   ```

1. Connectez-vous à la base de données nouvellement créée pour vérifier que tout est en place :

   ```shell
   mysql -u runner -p -D <your_mysql_database>
   ```

1. Configurez votre application pour utiliser la base de données, par exemple :

   ```shell
   Host: localhost
   User: runner
   Password: $password
   Database: <your_mysql_database>
   ```

## Exemple de projet {#example-project}

Pour consulter un exemple MySQL, créez une duplication de cet [exemple de projet](https://gitlab.com/gitlab-examples/mysql). Ce projet utilise des [runners d'instance](../runners/_index.md) disponibles publiquement sur [GitLab.com](https://gitlab.com). Mettez à jour le fichier README.md, commitez vos modifications et consultez le pipeline CI/CD pour le voir en action.
