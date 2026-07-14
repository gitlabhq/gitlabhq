---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Découvrez comment exécuter vos jobs CI/CD dans des conteneurs Docker hébergés sur des serveurs de build CI/CD dédiés ou sur votre machine locale.
title: Exécuter vos jobs CI/CD dans des conteneurs Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez exécuter vos jobs CI/CD dans des conteneurs Docker hébergés sur des serveurs de build CI/CD dédiés ou sur votre machine locale.

Pour exécuter des jobs CI/CD dans un conteneur Docker, vous devez :

1. Enregistrer un runner et le configurer pour utiliser l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/).
1. Spécifier l'image de conteneur dans laquelle vous souhaitez exécuter les jobs CI/CD dans le fichier `.gitlab-ci.yml`.
1. Facultatif. Exécuter d'autres services, comme MySQL, dans des conteneurs. Pour ce faire, spécifiez les [services](../services/_index.md) dans votre fichier `.gitlab-ci.yml`.

## Enregistrer un runner qui utilise l'exécuteur Docker {#register-a-runner-that-uses-the-docker-executor}

Pour utiliser GitLab Runner avec Docker, vous devez [enregistrer un runner](https://docs.gitlab.com/runner/register/) qui utilise l'exécuteur Docker.

Cet exemple montre comment configurer un modèle temporaire pour fournir des services :

```shell
cat > /tmp/test-config.template.toml << EOF
[[runners]]
[runners.docker]
[[runners.docker.services]]
name = "postgres:latest"
[[runners.docker.services]]
name = "mysql:latest"
EOF
```

Utilisez ensuite ce modèle pour enregistrer le runner :

```shell
sudo gitlab-runner register \
  --url "https://gitlab.example.com/" \
  --token "$RUNNER_TOKEN" \
  --description "docker-ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:3.3
```

Le runner enregistré utilise l'image Docker `ruby:2.6` et exécute deux services, `postgres:latest` et `mysql:latest`, tous deux accessibles pendant le processus de build.

## Qu'est-ce qu'une image {#what-is-an-image}

Le mot-clé `image` est le nom de l'image Docker que l'exécuteur Docker utilise pour exécuter les jobs CI/CD.

Par défaut, l'exécuteur extrait les images depuis [Docker Hub](https://hub.docker.com/). Vous pouvez toutefois configurer l'emplacement du registre de conteneurs dans le fichier `gitlab-runner/config.toml`. Par exemple, vous pouvez définir la [politique de pull Docker](https://docs.gitlab.com/runner/executors/docker/#how-pull-policies-work) pour utiliser des images locales.

Pour plus d'informations sur les images et Docker Hub, consultez la [présentation de Docker](https://docs.docker.com/get-started/overview/).

## Prérequis pour les images {#image-requirements}

Toute image utilisée pour exécuter un job CI/CD doit avoir les applications suivantes installées :

- `sh` ou `bash`
- `grep`

## Définir `image` dans le fichier `.gitlab-ci.yml` {#define-image-in-the-gitlab-ciyml-file}

Vous pouvez définir une image utilisée pour tous les jobs, ainsi qu'une liste de services à utiliser pendant l'exécution :

```yaml
default:
  image: ruby:2.6
  services:
    - postgres:16.10
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

Le nom de l'image doit être dans l'un des formats suivants :

- `image: <image-name>` (identique à l'utilisation de `<image-name>` avec le tag `latest`)
- `image: <image-name>:<tag>`
- `image: <image-name>@<digest>`

## Options de configuration Docker étendues {#extended-docker-configuration-options}

{{< history >}}

- Introduit dans GitLab et GitLab Runner 9.4.

{{< /history >}}

Vous pouvez utiliser une chaîne ou une map pour les entrées `image` ou `services` :

- Les chaînes doivent inclure le nom complet de l'image (y compris le registre de conteneurs, si vous souhaitez télécharger l'image depuis un registre autre que Docker Hub).
- Les maps doivent contenir au moins l'option `name`, qui correspond au même nom d'image que celui utilisé pour le paramètre de chaîne.

Par exemple, les deux définitions suivantes sont équivalentes :

- Une chaîne pour `image` et `services` :

  ```yaml
  image: "registry.example.com/my/image:latest"

  services:
    - postgresql:16.10
    - redis:latest
  ```

- Une map pour `image` et `services`. Le `image:name` est obligatoire :

  ```yaml
  image:
    name: "registry.example.com/my/image:latest"

  services:
    - name: postgresql:16.10
    - name: redis:latest
  ```

## Emplacement d'exécution des scripts {#where-scripts-are-executed}

Lorsqu'un job CI s'exécute dans un conteneur Docker, les commandes `before_script`, `script` et `after_script` s'exécutent dans le répertoire `/builds/<project-path>/`. Votre image peut avoir un répertoire `WORKDIR` par défaut différent. Pour accéder à votre `WORKDIR`, enregistrez le `WORKDIR` en tant que variable d'environnement afin de pouvoir y faire référence dans le conteneur pendant l'exécution du job.

### Remplacer le point d'entrée d'une image {#override-the-entrypoint-of-an-image}

{{< history >}}

- Introduit dans GitLab et GitLab Runner 9.4. En savoir plus sur les [options de configuration étendues](using_docker_images.md#extended-docker-configuration-options).

{{< /history >}}

Avant d'expliquer les méthodes disponibles pour remplacer le point d'entrée, décrivons comment le runner démarre. Il utilise une image Docker pour les conteneurs utilisés dans les jobs CI/CD :

1. Le runner démarre un conteneur Docker en utilisant le point d'entrée défini. La valeur par défaut issue du fichier `Dockerfile` peut être remplacée dans le fichier `.gitlab-ci.yml`.
1. Le runner s'attache à un conteneur en cours d'exécution.
1. Le runner prépare un script (la combinaison de [`before_script`](../yaml/_index.md#before_script), [`script`](../yaml/_index.md#script) et [`after_script`](../yaml/_index.md#after_script)).
1. Le runner envoie le script au shell du conteneur via `stdin` et reçoit la sortie.

Pour remplacer le [point d'entrée](https://docs.gitlab.com/runner/executors/docker/#configure-a-docker-entrypoint) d'une image Docker, dans le fichier `.gitlab-ci.yml` :

- Pour Docker 17.06 et versions ultérieures, définissez `entrypoint` sur une valeur vide.
- Pour Docker 17.03 et versions antérieures, définissez `entrypoint` sur `/bin/sh -c`, `/bin/bash -c` ou un shell équivalent disponible dans l'image.

La syntaxe de `image:entrypoint` est similaire à celle du [Dockerfile `ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint).

Supposons que vous disposiez d'une image `super/sql:experimental` contenant une base de données SQL. Vous souhaitez l'utiliser comme image de base pour votre job, car vous voulez exécuter certains tests avec ce binaire de base de données. Supposons également que cette image est configurée avec `/usr/bin/super-sql run` comme point d'entrée. Lorsque le conteneur démarre sans options supplémentaires, il exécute le processus de la base de données. Le runner s'attend à ce que l'image n'ait pas de point d'entrée ou que le point d'entrée soit prêt à démarrer une commande shell.

Avec les options de configuration Docker étendues, au lieu de :

- Créer votre propre image basée sur `super/sql:experimental`.
- Définir le `ENTRYPOINT` sur un shell.
- Utiliser la nouvelle image dans votre job CI.

Vous pouvez désormais définir un `entrypoint` dans le fichier `.gitlab-ci.yml`.

**Pour Docker 17.06 et versions ultérieures** :

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**Pour Docker 17.03 et versions antérieures** :

```yaml
image:
  name: super/sql:experimental
  entrypoint: ["/bin/sh", "-c"]
```

## Définir l'image et les services dans `config.toml` {#define-image-and-services-in-configtoml}

Dans le fichier `config.toml`, vous pouvez définir :

- Dans la section [`[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdocker-section), l'image de conteneur utilisée pour exécuter les jobs CI/CD
- Dans la section [`[[runners.docker.services]]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdockerservices-section), le conteneur de [services](../services/_index.md)

```toml
[runners.docker]
  image = "ruby:latest"
  services = ["mysql:latest", "postgres:latest"]
```

L'image et les services définis de cette façon sont ajoutés à tous les jobs exécutés par ce runner.

## Accéder à une image depuis un registre de conteneurs privé {#access-an-image-from-a-private-container-registry}

Pour accéder aux registres de conteneurs privés, le processus GitLab Runner peut utiliser :

- [Identifiants définis de manière statique](#use-statically-defined-credentials). Un nom d'utilisateur et un mot de passe pour un registre spécifique.
- [Credentials Store](#use-a-credentials-store). Pour plus d'informations, consultez [la documentation Docker pertinente](https://docs.docker.com/reference/cli/docker/login/#credential-stores).
- [Credential Helpers](#use-credential-helpers). Pour plus d'informations, consultez [la documentation Docker pertinente](https://docs.docker.com/reference/cli/docker/login/#credential-helpers).

Lorsque vous utilisez le [GitLab Container Registry](../../user/packages/container_registry/_index.md) sur la même instance GitLab, GitLab fournit des identifiants par défaut pour ce registre de conteneurs. Avec ces identifiants, le `CI_JOB_TOKEN` est utilisé pour l'authentification. Pour utiliser le token de job, l'utilisateur qui démarre le job doit disposer du rôle Developer, Maintainer ou Owner pour le projet où l'image privée est hébergée. Le projet hébergeant l'image privée doit également autoriser l'autre projet à s'authentifier avec le token de job. Cet accès est désactivé par défaut. Pour plus de détails, consultez [le token de job CI/CD](../jobs/ci_job_token.md#control-job-token-access-to-your-project).

Pour définir l'option à utiliser, le processus du runner lit la configuration dans l'ordre suivant :

- Un fichier `config.json` dans le répertoire `/root/.docker`.
- Une [variable CI/CD](../variables/_index.md) `DOCKER_AUTH_CONFIG`.
- Une variable d'environnement `DOCKER_AUTH_CONFIG` définie dans le fichier `config.toml` du runner.
- Un fichier `config.json` dans le répertoire `$HOME/.docker` de l'utilisateur qui exécute le processus. Si le flag `--user` est fourni pour exécuter les processus enfants en tant qu'utilisateur non privilégié, le répertoire personnel de l'utilisateur du processus principal du runner est utilisé.

### Prérequis et limitations {#requirements-and-limitations}

- [Credentials Store](#use-a-credentials-store) et [Credential Helpers](#use-credential-helpers) nécessitent l'ajout de binaires au `$PATH` de GitLab Runner, ainsi que les accès nécessaires pour ce faire. Par conséquent, ces fonctionnalités ne sont pas disponibles sur les runners d'instance, ni sur tout autre runner pour lequel l'utilisateur n'a pas accès à l'environnement où le runner est installé.

### Utiliser des identifiants définis de manière statique {#use-statically-defined-credentials}

Vous pouvez accéder à un registre privé en utilisant deux approches. Ces deux approches nécessitent de définir la variable CI/CD `DOCKER_AUTH_CONFIG` avec les informations d'authentification appropriées.

1. Par job : Pour configurer un job afin d'accéder à un registre privé, ajoutez `DOCKER_AUTH_CONFIG` en tant que [variable CI/CD](../variables/_index.md).
1. Par runner : Pour configurer un runner afin que tous ses jobs puissent accéder à un registre privé, ajoutez `DOCKER_AUTH_CONFIG` en tant que variable d'environnement dans la configuration du runner.

Consultez les sections suivantes pour des exemples de chacune.

#### Déterminer vos données `DOCKER_AUTH_CONFIG` {#determine-your-docker_auth_config-data}

Par exemple, supposons que vous souhaitiez utiliser l'image `registry.example.com:5000/private/image:latest`. Cette image est privée et nécessite de se connecter à un registre de conteneurs privé.

Supposons également que ces identifiants de connexion :

| Clé      | Valeur |
|:---------|:------|
| registre | `registry.example.com:5000` |
| nom d'utilisateur | `my_username` |
| mot de passe | `my_password` |

Utilisez l'une des méthodes suivantes pour déterminer la valeur de `DOCKER_AUTH_CONFIG` :

- Effectuez un `docker login` sur votre machine locale :

  ```shell
  docker login registry.example.com:5000 --username my_username --password my_password
  ```

  Copiez ensuite le contenu de `~/.docker/config.json`.

  Si vous n'avez pas besoin d'accéder au registre depuis votre ordinateur, vous pouvez effectuer un `docker logout` :

  ```shell
  docker logout registry.example.com:5000
  ```

- Dans certaines configurations, il est possible que le client Docker utilise le magasin de clés système disponible pour stocker le résultat de `docker login`. Dans ce cas, il est impossible de lire `~/.docker/config.json`, vous devez donc préparer la version encodée en base64 de `${username}:${password}` et créer manuellement le fichier JSON de configuration Docker. Ouvrez un terminal et exécutez la commande suivante :

  ```shell
  # The use of printf (as opposed to echo) prevents encoding a newline in the password.
  printf "my_username:my_password" | openssl base64 -A

  # Example output to copy
  bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
  ```

  > [!note]
  > Si votre nom d'utilisateur contient des caractères spéciaux comme `@`, vous devez les échapper avec une barre oblique inverse (` \ `) pour éviter des problèmes d'authentification.

  Créez le contenu de configuration JSON Docker comme suit :

  ```json
  {
      "auths": {
          "registry.example.com:5000": {
              "auth": "(Base64 content from above)"
          }
      }
  }
  ```

#### Configurer un job {#configure-a-job}

Pour configurer un seul job avec un accès à `registry.example.com:5000`, suivez ces étapes :

1. Créez une [variable CI/CD](../variables/_index.md) `DOCKER_AUTH_CONFIG` avec le contenu du fichier de configuration Docker comme valeur :

   ```json
   {
       "auths": {
           "registry.example.com:5000": {
               "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
           }
       }
   }
   ```

1. Vous pouvez désormais utiliser n'importe quelle image privée de `registry.example.com:5000` définie dans `image` ou `services` dans votre fichier `.gitlab-ci.yml` :

   ```yaml
   image: registry.example.com:5000/namespace/image:tag
   ```

   Dans l'exemple précédent, GitLab Runner recherche l'image `namespace/image:tag` dans `registry.example.com:5000`.

Vous pouvez ajouter la configuration pour autant de registres que vous le souhaitez, en ajoutant d'autres registres au hash `"auths"` comme décrit précédemment.

La combinaison complète `hostname:port` est requise partout pour que le runner corresponde à `DOCKER_AUTH_CONFIG`. Par exemple, si `registry.example.com:5000/namespace/image:tag` est spécifié dans le fichier `.gitlab-ci.yml`, alors `DOCKER_AUTH_CONFIG` doit également spécifier `registry.example.com:5000`. Spécifier uniquement `registry.example.com` ne fonctionne pas.

### Configuration d'un runner {#configuring-a-runner}

Si vous avez de nombreux pipelines qui accèdent au même registre, vous devez configurer l'accès au registre au niveau du runner. Cela permet aux auteurs de pipelines d'accéder à un registre privé simplement en exécutant un job sur le runner approprié. Cela contribue également à simplifier les changements de registre et la rotation des identifiants.

Cela signifie que tout job exécuté sur ce runner peut accéder au registre avec les mêmes privilèges, même entre différents projets. Si vous devez contrôler l'accès au registre, vous devez vous assurer de contrôler l'accès au runner.

Pour ajouter `DOCKER_AUTH_CONFIG` à un runner :

1. Modifiez le fichier `config.toml` du runner comme suit :

   ```toml
   [[runners]]
     environment = ["DOCKER_AUTH_CONFIG={\"auths\":{\"registry.example.com:5000\":{\"auth\":\"bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=\"}}}"]
   ```

   - Les guillemets doubles inclus dans les données `DOCKER_AUTH_CONFIG` doivent être échappés avec des barres obliques inverses. Cela les empêche d'être interprétés comme du TOML.
   - L'option `environment` est une liste. Votre runner peut avoir des entrées existantes et vous devez ajouter celle-ci à la liste, sans la remplacer.

1. Redémarrez le service du runner.

### Utiliser un Credentials Store {#use-a-credentials-store}

Pour configurer un Credentials Store :

1. Pour utiliser un Credentials Store, vous avez besoin d'un programme d'aide externe pour interagir avec un trousseau de clés ou un store externe spécifique. Assurez-vous que le programme d'aide est disponible dans le `$PATH` de GitLab Runner.

1. Configurez GitLab Runner pour l'utiliser. Pour ce faire, utilisez l'une des options suivantes :

   - Créez une [variable CI/CD](../variables/_index.md) `DOCKER_AUTH_CONFIG` avec le contenu du fichier de configuration Docker comme valeur :

     ```json
       {
         "credsStore": "osxkeychain"
       }
     ```

   - Ou, si vous exécutez des runners auto-gérés, ajoutez le JSON à `${GITLAB_RUNNER_HOME}/.docker/config.json`. GitLab Runner lit ce fichier de configuration et utilise le programme d'aide nécessaire pour ce dépôt spécifique.

`credsStore` est utilisé pour accéder à **l'ensemble** des registres. Si vous utilisez à la fois des images provenant d'un registre privé et des images publiques de Docker Hub, le pull depuis Docker Hub échoue. Le daemon Docker tente d'utiliser les mêmes identifiants pour **l'ensemble** des registres.

### Utiliser des Credential Helpers {#use-credential-helpers}

Par exemple, supposons que vous souhaitiez utiliser l'image `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest`. Cette image est privée et nécessite de se connecter à un registre de conteneurs privé.

Pour configurer l'accès à `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`, suivez ces étapes :

1. Assurez-vous que [`docker-credential-ecr-login`](https://github.com/awslabs/amazon-ecr-credential-helper) est disponible dans le `$PATH` de GitLab Runner.
1. Disposez de l'un des [paramètres d'identifiants AWS](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials) suivants. GitLab Runner Manager acquiert les identifiants et les transmet aux runners. Assurez-vous que GitLab Runner peut accéder aux identifiants.
1. Configurez GitLab Runner pour l'utiliser. Pour ce faire, utilisez l'une des options suivantes :

   - Créez une [variable CI/CD](../variables/_index.md) `DOCKER_AUTH_CONFIG` avec le contenu du fichier de configuration Docker comme valeur :

     ```json
     {
       "credHelpers": {
         "<aws_account_id>.dkr.ecr.<region>.amazonaws.com": "ecr-login"
       }
     }
     ```

     Cela configure Docker pour utiliser le Credential Helper pour un registre spécifique.

     Vous pouvez également configurer Docker pour utiliser le Credential Helper pour tous les registres Amazon Elastic Container Registry (ECR) :

     ```json
     {
       "credsStore": "ecr-login"
     }
     ```

     > [!note]
     > Si vous utilisez `{"credsStore": "ecr-login"}`, définissez explicitement la région dans le fichier de configuration partagée AWS (`~/.aws/config`). La région doit être spécifiée lorsque le ECR Credential Helper récupère le token d'autorisation.

   - Ou, si vous exécutez des runners auto-gérés, ajoutez le JSON précédent à `${GITLAB_RUNNER_HOME}/.docker/config.json`. GitLab Runner lit ce fichier de configuration et utilise le programme d'aide nécessaire pour ce dépôt spécifique.

1. Vous pouvez désormais utiliser n'importe quelle image privée de `<aws_account_id>.dkr.ecr.<region>.amazonaws.com` définie dans `image` et/ou `services` dans votre fichier `.gitlab-ci.yml` :

   ```yaml
   image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest
   ```

   Dans l'exemple, GitLab Runner recherche l'image `private/image:latest` dans `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`.

Vous pouvez ajouter la configuration pour autant de registres que vous le souhaitez, en ajoutant d'autres registres au hash `"credHelpers"`.

### Utiliser une somme de contrôle pour sécuriser votre image {#use-checksum-to-keep-your-image-secure}

Utilisez la somme de contrôle de l'image dans la définition de votre job dans votre fichier `.gitlab-ci.yml` pour vérifier l'intégrité de l'image. Un échec de la vérification de l'intégrité de l'image vous empêche d'utiliser un conteneur modifié.

Pour utiliser la somme de contrôle de l'image, vous devez l'ajouter à la fin :

```yaml
image: ruby:2.6.8@sha256:d1dbaf9665fe8b2175198e49438092fdbcf4d8934200942b94425301b17853c7
```

Pour obtenir la somme de contrôle de l'image, dans l'onglet `TAG` de l'image, consultez la colonne `DIGEST`. Par exemple, consultez l'[image Ruby](https://hub.docker.com/_/ruby?tab=tags). La somme de contrôle est une chaîne aléatoire, comme `6155f0235e95`.

Vous pouvez également obtenir la somme de contrôle de n'importe quelle image sur votre système avec la commande `docker images --digests` :

```shell
❯ docker images --digests
REPOSITORY                                                        TAG       DIGEST                                                                    (...)
gitlab/gitlab-ee                                                  latest    sha256:723aa6edd8f122d50cae490b1743a616d54d4a910db892314d68470cc39dfb24   (...)
gitlab/gitlab-runner                                              latest    sha256:4a18a80f5be5df44cb7575f6b89d1fdda343297c6fd666c015c0e778b276e726   (...)
```

## Créer une image Docker GitLab Runner personnalisée {#creating-a-custom-gitlab-runner-docker-image}

Vous pouvez créer une image Docker GitLab Runner personnalisée pour intégrer AWS CLI et Amazon ECR Credential Helper. Cette configuration facilite des interactions sécurisées et rationalisées avec les services AWS, en particulier pour les applications conteneurisées. Par exemple, utilisez cette configuration pour gérer, déployer et mettre à jour des images Docker sur Amazon ECR. Cette configuration permet d'éviter des configurations chronophages et sujettes aux erreurs, ainsi que la gestion manuelle des identifiants.

1. [Authentifier GitLab avec AWS](../cloud_deployment/_index.md#authenticate-gitlab-with-aws).
1. Créez un fichier `Dockerfile` avec le contenu suivant :

   ```Dockerfile
   # Control package versions
   ARG GITLAB_RUNNER_VERSION=v17.3.0
   ARG AWS_CLI_VERSION=2.17.36

   # AWS CLI and Amazon ECR Credential Helper
   FROM amazonlinux as aws-tools
   RUN set -e \
       && yum update -y \
       && yum install -y --allowerasing git make gcc curl unzip \
       && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip" \
       && unzip awscliv2.zip && ./aws/install -i /usr/local/bin \
       && yum clean all

   # Download and install ECR Credential Helper
   RUN curl --location --output  /usr/local/bin/docker-credential-ecr-login "https://github.com/awslabs/amazon-ecr-credential-helper/releases/latest/download/docker-credential-ecr-login-linux-amd64"
   RUN chmod +x /usr/local/bin/docker-credential-ecr-login

   # Configure the ECR Credential Helper
   RUN mkdir -p /root/.docker
   RUN echo '{ "credsStore": "ecr-login" }' > /root/.docker/config.json

   # Final image based on GitLab Runner
   FROM gitlab/gitlab-runner:${GITLAB_RUNNER_VERSION}

   # Install necessary packages
   RUN apt-get update \
       && apt-get install -y --no-install-recommends jq procps curl unzip groff libgcrypt20 tar gzip less openssh-client \
       && apt-get clean && rm -rf /var/lib/apt/lists/*

   # Copy AWS CLI and Amazon ECR Credential Helper binaries
   COPY --from=aws-tools /usr/local/bin/ /usr/local/bin/

   # Copy ECR Credential Helper Configuration
   COPY --from=aws-tools /root/.docker/config.json /root/.docker/config.json
   ```

1. Pour builder l'image Docker GitLab Runner personnalisée dans un `.gitlab-ci.yml`, incluez l'exemple suivant :

   ```yaml
   variables:
     DOCKER_DRIVER: overlay2
     IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME
     GITLAB_RUNNER_VERSION: v17.3.0
     AWS_CLI_VERSION: 2.17.36

   stages:
     - build

   build-image:
     stage: build
     script:
       - echo "Logging into GitLab container registry..."
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
       - echo "Building Docker image..."
       - docker build --build-arg GITLAB_RUNNER_VERSION=${GITLAB_RUNNER_VERSION} --build-arg AWS_CLI_VERSION=${AWS_CLI_VERSION} -t ${IMAGE_NAME} .
       - echo "Pushing Docker image to GitLab container registry..."
       - docker push ${IMAGE_NAME}
     rules:
       - changes:
           - Dockerfile
   ```

1. [Enregistrer le runner](https://docs.gitlab.com/runner/register/#docker).
