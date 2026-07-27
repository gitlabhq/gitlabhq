---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de Redis
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

De nombreuses applications dépendent de Redis en tant que magasin clé-valeur, vous devez donc l'utiliser pour exécuter vos tests.

## Utiliser Redis avec l'exécuteur Docker {#use-redis-with-the-docker-executor}

Si vous utilisez [GitLab Runner](../runners/_index.md) avec l'exécuteur Docker, tout est déjà configuré.

Tout d'abord, dans votre `.gitlab-ci.yml`, ajoutez :

```yaml
services:
  - redis:latest
```

Vous devez ensuite configurer votre application pour utiliser la base de données Redis, par exemple :

```yaml
Host: redis
```

Et voilà. Redis est désormais disponible pour être utilisé dans votre framework de test.

Vous pouvez également utiliser toute autre image Docker disponible sur [Docker Hub](https://hub.docker.com/_/redis). Par exemple, pour utiliser Redis 6.0, le service devient `redis:6.0`.

## Utiliser Redis avec l'exécuteur Shell {#use-redis-with-the-shell-executor}

Redis peut également être utilisé sur des serveurs configurés manuellement qui utilisent GitLab Runner avec l'exécuteur Shell.

Sur votre machine de build, installez le serveur Redis :

```shell
sudo apt-get install redis-server
```

Vérifiez que vous pouvez vous connecter au serveur avec l'utilisateur `gitlab-runner` :

```shell
# Try connecting the Redis server
sudo -u gitlab-runner -H redis-cli

# Quit the session
127.0.0.1:6379> quit
```

Enfin, configurez votre application pour utiliser la base de données, par exemple :

```yaml
Host: localhost
```

## Exemple de projet {#example-project}

Nous avons mis en place un [exemple de projet Redis](https://gitlab.com/gitlab-examples/redis) pour votre commodité, qui s'exécute sur [GitLab.com](https://gitlab.com) en utilisant nos [runners d'instance](../runners/_index.md) disponibles publiquement.

Vous souhaitez le modifier ? Dupliquez-le (dupliquer), committez et poussez vos modifications. En quelques instants, les modifications sont récupérées par un runner public et le job commence.
