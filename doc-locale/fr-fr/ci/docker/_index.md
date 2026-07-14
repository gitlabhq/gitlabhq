---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intégration Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez intégrer [Docker](https://www.docker.com) à votre workflow CI/CD de deux façons principales :

- [Exécutez vos jobs CI/CD](using_docker_images.md) dans des conteneurs Docker.

  Créez des jobs pour tester, build ou publier des applications s'exécutant dans des conteneurs Docker. Par exemple, utilisez une image Node depuis Docker Hub pour que votre job s'exécute dans un conteneur avec toutes les dépendances Node dont vous avez besoin.

- Utilisez [Docker Build](using_docker_build.md) ou [BuildKit](using_buildkit.md) pour créer des images Docker.

  Créez des jobs qui créent des images Docker et les publient dans un registre de conteneurs. BuildKit offre plusieurs approches, notamment les builds rootless.
