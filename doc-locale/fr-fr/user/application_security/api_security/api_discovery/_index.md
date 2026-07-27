---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Découverte d'API"
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/9302) dans GitLab 15.9. La fonctionnalité de découverte d'API est en [version bêta](../../../../policy/development_stages_support.md).

{{< /history >}}

La découverte d'API analyse votre application et produit un document OpenAPI décrivant les API web qu'elle expose. Ce document de schéma peut ensuite être utilisé par [l'analyseur de test de sécurité des API](../../api_security_testing/_index.md) ou le [fuzzing d'API](../../api_fuzzing/_index.md) pour effectuer des analyses de sécurité de l'API web.

## Frameworks pris en charge {#supported-frameworks}

- [Java Spring-Boot](#java-spring-boot)

## Quand la découverte d'API s'exécute-t-elle ? {#when-does-api-discovery-run}

La découverte d'API s'exécute en tant que job autonome dans votre pipeline. Le document OpenAPI résultant est capturé en tant qu'artefact de job afin de pouvoir être utilisé par d'autres jobs dans des étapes ultérieures.

La découverte d'API s'exécute dans l'étape `test` par défaut. L'étape `test` a été choisie car elle s'exécute généralement avant les étapes utilisées par d'autres fonctionnalités de sécurité telles que le test de sécurité des API et le fuzzing d'API.

## Exemples de configurations de découverte d'API {#example-api-discovery-configurations}

Les projets suivants illustrent la découverte d'API :

- [Exemple Java Spring Boot v2 Pet Store](https://gitlab.com/gitlab-org/security-products/demos/api-discovery/java-spring-boot-v2-petstore)

## Java Spring-Boot {#java-spring-boot}

[Spring Boot](https://spring.io/projects/spring-boot/) est un framework populaire pour créer des applications Spring autonomes et prêtes pour la production.

### Applications prises en charge {#supported-applications}

- Spring Boot : v2.X (>= 2.1)
- Java :  11, 17 (versions LTS)
- JARs exécutables

La découverte d'API prend en charge Spring Boot version majeure 2, versions mineures 1 et ultérieures. Les versions 2.0.X ne sont pas prises en charge en raison de bogues connus qui affectaient la découverte d'API et ont été corrigés dans la version 2.1.

La prise en charge de la version majeure 3 est prévue à l'avenir. La prise en charge de la version majeure 1 n'est pas prévue.

La découverte d'API est testée avec les versions LTS du runtime Java et les prend officiellement en charge. D'autres versions peuvent également fonctionner, et les rapports de bogues provenant de versions non LTS sont les bienvenus.

Seules les applications conçues comme des [JARs exécutables](https://docs.spring.io/spring-boot/redirect.html?page=executable-jar#appendix.executable-jar.nested-jars.jar-structure) Spring Boot sont prises en charge.

### Configurer en tant que job de pipeline {#configure-as-pipeline-job}

Le moyen le plus simple d'exécuter la découverte d'API est via un job de pipeline basé sur notre modèle CI. Lors de l'exécution avec cette méthode, vous fournissez une image de conteneur sur laquelle les dépendances requises sont installées (comme un runtime Java approprié). Consultez [Exigences relatives aux images](#image-requirements) pour plus d'informations.

1. Une image de conteneur répondant aux [exigences relatives aux images](#image-requirements) est téléversée dans un registre de conteneurs. Si le registre de conteneurs requiert une authentification, consultez [cette section d'aide](../../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry).
1. Dans un job de l'étape `build`, compilez votre application et configurez le JAR exécutable Spring Boot résultant en tant qu'artefact de job.
1. Incluez le modèle de découverte d'API dans votre fichier `.gitlab-ci.yml`.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
   ```

   Seule une instruction `include` unique est autorisée par fichier `.gitlab-ci.yml`. Si vous incluez d'autres fichiers, regroupez-les dans une seule instruction `include`.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
      - template: Security/DAST-API.gitlab-ci.yml
   ```

1. Créez un nouveau job qui étend `.api_discovery_java_spring_boot`. L'étape par défaut est `test` et peut être modifiée en n'importe quelle valeur.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
   ```

1. Configurez le `image` pour le job.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
   ```

1. Fournissez le chemin de classe Java requis par votre application. Cela inclut votre artefact de compilation compatible issu de l'étape 2, ainsi que toutes les dépendances supplémentaires. Pour cet exemple, l'artefact de compilation est `build/libs/spring-boot-app-0.0.0.jar` et contient toutes les dépendances nécessaires. La variable CI/CD `API_DISCOVERY_JAVA_CLASSPATH` est utilisée pour fournir le chemin de classe.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
   ```

1. Facultatif. Si une dépendance requise par la découverte d'API est manquante dans l'image fournie, elle peut être ajoutée à l'aide d'un `before_script`. Dans cet exemple, le conteneur `eclipse-temurin:17-jre-alpine` n'inclut pas `curl`, qui est requis par la découverte d'API. La dépendance peut être installée à l'aide du gestionnaire de paquets Debian `apt` :

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
       before_script:
           - apk add --no-cache curl
   ```

1. Facultatif. Si l'image fournie ne définit pas automatiquement la variable CI/CD d'environnement `JAVA_HOME` ou n'inclut pas `java` dans le chemin, la variable CI/CD `API_DISCOVERY_JAVA_HOME` peut être utilisée.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_JAVA_HOME: /opt/java
   ```

1. Facultatif. Si le registre de paquets à l'adresse `API_DISCOVERY_PACKAGES` n'est pas public, fournissez un jeton disposant d'un accès en lecture à l'API GitLab et au registre à l'aide de la variable CI/CD `API_DISCOVERY_PACKAGE_TOKEN`. Ce n'est pas obligatoire si vous utilisez `gitlab.com` et n'avez pas personnalisé la variable CI/CD `API_DISCOVERY_PACKAGES`. L'exemple suivant utilise une [variable CI/CD personnalisée](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) nommée `GITLAB_READ_TOKEN` pour stocker le jeton.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_PACKAGE_TOKEN: $GITLAB_READ_TOKEN
   ```

Une fois le job de découverte d'API exécuté avec succès, le document OpenAPI est disponible en tant qu'artefact de job appelé `gl-api-discovery-openapi.json`.

#### Exigences relatives aux images {#image-requirements}

- Image de conteneur Linux.
- Les versions Java 11 et 17 sont officiellement prises en charge, mais d'autres versions sont probablement compatibles également.
- La commande `curl`.
- Un shell à `/bin/sh` (comme `busybox`, `sh` ou `bash`).

### Variables CI/CD disponibles {#available-cicd-variables}

| Variable CI/CD                              | Description        |
|---------------------------------------------|--------------------|
| `API_DISCOVERY_DISABLED`                    | Désactive le job de découverte d'API lors de l'utilisation des règles de job de modèle. |
| `API_DISCOVERY_DISABLED_FOR_DEFAULT_BRANCH` | Désactive le job de découverte d'API pour les pipelines de la branche par défaut lors de l'utilisation des règles de job de modèle. |
| `API_DISCOVERY_JAVA_CLASSPATH`              | Chemin de classe Java incluant l'application Spring Boot cible. (`build/libs/sample-0.0.0.jar`) |
| `API_DISCOVERY_JAVA_HOME`                   | Si fourni, est utilisé pour définir `JAVA_HOME`. |
| `API_DISCOVERY_PACKAGES`                    | Préfixe de l'API de paquets du projet GitLab (par défaut : `$CI_API_V4_URL/projects/42503323/packages`). |
| `API_DISCOVERY_PACKAGE_TOKEN`               | Jeton GitLab pour appeler l'API de paquets GitLab. Requis uniquement lorsque `API_DISCOVERY_PACKAGES` est défini sur un projet non public. |
| `API_DISCOVERY_VERSION`                     | Version de découverte d'API à utiliser (par défaut : `1`). Peut être utilisé pour épingler une version en fournissant le numéro de version complet `1.1.0`. |

## Obtenir de l'aide ou demander une amélioration {#get-support-or-request-an-improvement}

Pour obtenir de l'aide concernant votre problème spécifique, utilisez les [canaux d'aide](https://about.gitlab.com/get-help/).

Le [système de suivi des tickets GitLab sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) est l'endroit approprié pour signaler des bogues et proposer des fonctionnalités concernant la découverte d'API. Utilisez le label `~"Category:API Security"` lors de l'ouverture d'un nouveau ticket concernant la découverte d'API pour vous assurer qu'il est rapidement examiné par les bonnes personnes.

[Recherchez dans le système de suivi des tickets](https://gitlab.com/gitlab-org/gitlab/-/issues) des entrées similaires avant de soumettre la vôtre, il y a de bonnes chances que quelqu'un d'autre ait eu le même problème ou la même proposition de fonctionnalité. Montrez votre soutien avec une réaction emoji ou participez à la discussion.

Lorsque vous rencontrez un comportement qui ne fonctionne pas comme prévu, envisagez de fournir des informations contextuelles :

- Version de GitLab si vous utilisez une instance GitLab Self-Managed.
- Définition du job `.gitlab-ci.yml`.
- Sortie complète de la console du job.
- Framework utilisé avec la version (par exemple « Spring Boot v2.3.2 »).
- Runtime du langage avec la version (par exemple « Eclipse Temurin v17.0.1 »).

<!-- - Scanner log file is available as a job artifact named `gl-api-discovery.log`. -->

> [!warning]
> **Anonymiser les données jointes à un ticket d'assistance**. Supprimez les informations sensibles, notamment : les identifiants, les mots de passe, les jetons, les clés et les secrets.
