---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Exemples et guides contribués par la communauté pour implémenter GitLab CI/CD dans différents langages, frameworks et cibles de déploiement."
title: Exemples CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez ces exemples pour implémenter [GitLab CI/CD](../_index.md) selon votre cas d'utilisation spécifique.

## Exemples {#examples}

| Cas d'utilisation                      | Ressource |
| ----------------------------- | -------- |
| Déploiement avec Dpl           | [Déployer des applications avec l'outil Dpl](deployment/_index.md) |
| GitLab Pages                  | [Publier des sites web statiques avec déploiement CI/CD automatique](../../user/project/pages/_index.md) |
| Pipeline multi-projets        | [Créer, tester et déployer avec des pipelines multi-projets](https://gitlab.com/gitlab-examples/upstream-project) |
| npm avec semantic-release     | [Publier des paquets npm dans le registre de paquets GitLab](semantic-release.md) |
| Composer et npm avec SCP     | [Déployer des scripts Composer et npm avec SCP](deployment/composer-npm-deploy.md) |
| PHP avec PHPUnit et `atoum`  | [Tester des projets PHP](php.md) |
| Gestion des secrets avec Vault | [S'authentifier et lire des secrets avec HashiCorp Vault](../secrets/hashicorp_vault_tutorial.md) |

## Exemples contribués par la communauté {#community-contributed-examples}

Ces exemples sont maintenus par la communauté et non par GitLab. La plupart des exemples de projets sont hébergés sur GitLab et peuvent être dupliqués et adaptés à vos propres besoins.

| Cas d'utilisation                   | Ressource |
| -------------------------- | -------- |
| Clojure                    | [Tester une application Clojure](https://gitlab.com/gitlab-examples/clojure-web-application) |
| Développement de jeux           | [Configurer CI/CD pour le développement de jeux](https://gitlab.com/gitlab-examples/gitlab-game-demo/) |
| Java avec Maven            | [Déployer des projets Maven vers Artifactory](https://gitlab.com/gitlab-examples/maven/simple-maven-example) |
| Java avec Spring Boot      | [Déployer une application Spring Boot vers Cloud Foundry](https://gitlab.com/gitlab-examples/spring-gitlab-cf-deploy-demo) |
| Tests parallèles Ruby & JS | [Exécuter des tests en parallèle pour Ruby et JavaScript](https://docs.knapsackpro.com/2019/how-to-run-parallel-jobs-for-rspec-tests-on-gitlab-ci-pipeline-and-speed-up-ruby-javascript-testing) |
| Python sur Heroku           | [Tester et déployer une application Python sur Heroku](https://gitlab.com/gitlab-examples/python-getting-started) |
| Environnements éphémères avec NGINX     | [Configurer des environnements éphémères avec NGINX](https://gitlab.com/gitlab-examples/review-apps-nginx/) |
| Ruby sur Heroku             | [Tester et déployer une application Ruby sur Heroku](https://gitlab.com/gitlab-examples/ruby-getting-started) |
| Scala sur Heroku            | [Tester et déployer une application Scala sur Heroku](https://gitlab.com/gitlab-examples/scala-sbt) |

## Exemples de migration CI/CD {#cicd-migration-examples}

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

## Sujets connexes {#related-topics}

- [Catalogue CI/CD](../components/_index.md#cicd-catalog)
- [Tutoriels : Créer votre application](../../tutorials/build_application.md)
- [Exemples de projets](https://gitlab.com/gitlab-examples)
