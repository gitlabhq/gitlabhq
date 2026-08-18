---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser PostgreSQL
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

De nombreuses applications dépendent de PostgreSQL en tant que base de données ; vous devez donc l'utiliser pour exécuter vos tests.

## Utiliser PostgreSQL avec l'exécuteur Docker {#use-postgresql-with-the-docker-executor}

Pour transmettre les variables CI/CD définies dans l'interface utilisateur GitLab aux conteneurs de services, vous devez [définir les variables](../variables/_index.md#define-a-cicd-variable-in-the-ui). Vous devez définir vos variables en tant que variables de groupe ou de projet, puis appeler les variables dans votre job comme illustré dans la solution de contournement suivante.

Postgres 15.4 et les versions ultérieures ne substituent pas les noms de schémas ou de propriétaires dans les scripts d'extension s'ils contiennent des guillemets ("), des barres obliques inverses (\\) ou des symboles dollar ($). Si les variables CI/CD ne sont pas configurées, la valeur utilise le nom de la variable d'environnement comme chaîne de caractères à la place. Par exemple, `POSTGRES_USER: $USER` entraîne la définition de la variable `POSTGRES_USER` sur '$USER', ce qui amène Postgres à afficher l'erreur suivante :

```shell
Fatal: invalid character in extension
```

La solution de contournement consiste à définir vos variables dans les [variables CI/CD GitLab](../variables/_index.md) ou à définir les variables sous forme de chaîne :

1. [Définissez les variables Postgres dans GitLab](../variables/_index.md#for-a-project). Les variables définies dans l'interface utilisateur GitLab ne sont pas transmises aux conteneurs de services.
1. Dans le fichier `.gitlab-ci.yml`, spécifiez une image Postgres :

   ```yaml
   default:
      services:
        - postgres
   ```

1. Dans le fichier `.gitlab-ci.yml`, ajoutez vos variables définies :

   ```yaml
   variables:
     POSTGRES_DB: $POSTGRES_DB
     POSTGRES_USER: $POSTGRES_USER
     POSTGRES_PASSWORD: $POSTGRES_PASSWORD
     POSTGRES_HOST_AUTH_METHOD: trust
   ```

   Pour plus d'informations sur l'utilisation de `postgres` pour le `Host`, consultez [Comment les services sont liés au job](_index.md#how-services-are-linked-to-the-job).

1. Configurez votre application pour utiliser la base de données, par exemple :

   ```yaml
   Host: postgres
   User: $POSTGRES_USER
   Password: $POSTGRES_PASSWORD
   Database: $POSTGRES_DB
   ```

Vous pouvez également définir des variables sous forme de chaîne dans le fichier `.gitlab-ci.yml` :

```yaml
variables:
  POSTGRES_DB: DB_name
  POSTGRES_USER: username
  POSTGRES_PASSWORD: password
  POSTGRES_HOST_AUTH_METHOD: trust
```

Vous pouvez utiliser n'importe quelle autre image Docker disponible sur [Docker Hub](https://hub.docker.com/_/postgres). Par exemple, pour utiliser PostgreSQL 16.10, le service devient `postgres:16.10`.

L'image `postgres` peut accepter certaines variables d'environnement. Pour plus d'informations, consultez la documentation sur [Docker Hub](https://hub.docker.com/_/postgres).

## Utiliser PostgreSQL avec l'exécuteur Shell {#use-postgresql-with-the-shell-executor}

Vous pouvez également utiliser PostgreSQL sur des serveurs configurés manuellement qui utilisent GitLab Runner avec l'exécuteur Shell.

Commencez par installer le serveur PostgreSQL :

```shell
sudo apt-get install -y postgresql postgresql-client libpq-dev
```

L'étape suivante consiste à créer un utilisateur ; connectez-vous donc à PostgreSQL :

```shell
sudo -u postgres psql -d template1
```

Créez ensuite un utilisateur (dans notre cas `runner`) qui sera utilisé par votre application. Remplacez `$password` dans la commande suivante par un mot de passe fort.

> [!note]
> Veillez à ne pas saisir `template1=#` dans les commandes suivantes, car cela fait partie de l'invite PostgreSQL.

```shell
template1=# CREATE USER runner WITH PASSWORD '$password' CREATEDB;
```

L'utilisateur créé dispose du privilège pour créer des bases de données (`CREATEDB`). Les étapes suivantes décrivent comment créer une base de données explicitement pour cet utilisateur. Les privilèges permettent à votre framework de test de créer et de supprimer des bases de données selon les besoins.

Créez la base de données et accordez-lui tous les privilèges pour l'utilisateur `runner` :

```shell
template1=# CREATE DATABASE nice_marmot OWNER runner;
```

Si tout s'est bien passé, vous pouvez maintenant quitter la session de base de données :

```shell
template1=# \q
```

À présent, essayez de vous connecter à la base de données nouvellement créée avec l'utilisateur `runner` pour vérifier que tout est en place.

```shell
psql -U runner -h localhost -d nice_marmot -W
```

Cette commande indique explicitement à `psql` de se connecter à localhost pour utiliser l'authentification md5. Si vous omettez cette étape, l'accès vous sera refusé.

Enfin, configurez votre application pour utiliser la base de données, par exemple :

```yaml
Host: localhost
User: runner
Password: $password
Database: nice_marmot
```

## Exemple de projet {#example-project}

Nous avons mis en place un [exemple de projet PostgreSQL](https://gitlab.com/gitlab-examples/postgres) pour votre commodité, qui s'exécute sur [GitLab.com](https://gitlab.com) à l'aide de nos [runners d'instance](../runners/_index.md) disponibles publiquement.

Vous souhaitez le modifier ? Dupliquez-le, effectuez un commit et poussez vos modifications. En quelques instants, les modifications sont prises en charge par un runner public et le job commence.
