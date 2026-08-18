---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser GitLab comme microservice
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

De nombreuses applications doivent accéder à des API JSON, de sorte que les tests d'application peuvent également nécessiter un accès aux API. L'exemple suivant montre comment utiliser GitLab comme microservice pour donner aux tests accès à l'API GitLab.

1. Configurez un [runner](../runners/_index.md) avec l'exécuteur Docker ou Kubernetes.
1. Dans votre `.gitlab-ci.yml`, ajoutez :

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

> [!note]
> Les variables CI/CD définies dans l'interface utilisateur GitLab ne sont pas transmises aux conteneurs de service. Pour plus d'informations, consultez [les variables CI/CD GitLab](../variables/_index.md).

Ensuite, les commandes des sections `script` de votre fichier `.gitlab-ci.yml` peuvent accéder à l'API à l'adresse `http://gitlab/api/v4`.

Pour plus d'informations sur la raison pour laquelle `gitlab` est utilisé pour le `Host`, consultez [Comment les services sont liés au job](../docker/using_docker_images.md#extended-docker-configuration-options).

Vous pouvez également utiliser n'importe quelle autre image Docker disponible sur [Docker Hub](https://hub.docker.com/u/gitlab).

L'image `gitlab` peut accepter des variables d'environnement. Pour plus de détails, consultez la [documentation du package Linux](../../install/_index.md).
