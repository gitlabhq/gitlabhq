---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Services
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous configurez CI/CD, vous spécifiez une image, qui est utilisée pour créer le conteneur dans lequel vos jobs s'exécutent. Pour spécifier cette image, vous utilisez le mot-clé `image`.

Vous pouvez spécifier une image supplémentaire en utilisant le mot-clé `services`. Cette image supplémentaire est utilisée pour créer un autre conteneur, qui est accessible au premier conteneur. Les deux conteneurs ont accès l'un à l'autre et peuvent communiquer lors de l'exécution du job.

L'image de service peut exécuter n'importe quelle application, mais le cas d'utilisation le plus courant est d'exécuter un conteneur de base de données, par exemple :

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- [GitLab](gitlab.md) comme exemple de microservice offrant une API JSON

> [!warning]
> Pour activer la mise en réseau inter-services, définissez `FF_NETWORK_PER_BUILD` sur `true`. Sans ce flag, les services peuvent ne pas fonctionner correctement. Pour plus d'informations, consultez les [feature flags](https://docs.gitlab.com/runner/configuration/feature-flags).

Supposons que vous développez un système de gestion de contenu qui utilise une base de données pour le stockage. Vous avez besoin d'une base de données pour tester toutes les fonctionnalités de l'application. Exécuter un conteneur de base de données comme image de service est un bon cas d'utilisation dans ce scénario.

Utilisez une image existante et exécutez-la comme conteneur supplémentaire plutôt que d'installer `mysql` à chaque fois que vous compilez un projet.

Vous n'êtes pas limité aux seuls services de base de données. Vous pouvez ajouter autant de services que nécessaire dans `.gitlab-ci.yml` ou modifier manuellement le [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/). Toute image trouvée sur [Docker Hub](https://hub.docker.com/) ou dans votre registre de conteneurs privé peut être utilisée comme service.

Pour plus d'informations sur l'utilisation d'images privées, consultez [Accéder à une image depuis un registre de conteneurs privé](../docker/using_docker_images.md#access-an-image-from-a-private-container-registry).

Les services héritent des mêmes serveurs DNS, domaines de recherche et hôtes supplémentaires que le conteneur CI lui-même.

## Comment les services sont liés au job {#how-services-are-linked-to-the-job}

Pour mieux comprendre le fonctionnement de la liaison de conteneurs, consultez [Linking containers together](https://docs.docker.com/network/links/).

Si vous ajoutez `mysql` comme service à votre application, l'image est utilisée pour créer un conteneur lié au conteneur du job.

Le conteneur de service pour MySQL est accessible sous le nom d'hôte `mysql`. Pour accéder à votre service de base de données, connectez-vous à l'hôte nommé `mysql` plutôt qu'à un socket ou à `localhost`. Pour en savoir plus, consultez [accéder aux services](#accessing-the-services).

## Fonctionnement du contrôle de santé des services {#how-the-health-check-of-services-works}

Les services sont conçus pour fournir des fonctionnalités supplémentaires **network accessible**. Il peut s'agir d'une base de données comme MySQL, ou Redis, et même de `docker:dind` qui vous permet d'utiliser Docker-in-Docker (DinD). Il peut s'agir pratiquement de n'importe quoi qui est requis pour que le job CI/CD se déroule, et qui est accessible via le réseau.

Pour s'assurer que cela fonctionne, le runner :

1. Vérifie quels ports sont exposés par défaut par le conteneur.
1. Démarre un conteneur spécial qui attend que ces ports soient accessibles.

Si la deuxième étape du contrôle échoue, il affiche l'avertissement : `*** WARNING: Service XYZ probably didn't start properly`. Ce problème peut survenir pour les raisons suivantes :

- Aucun port n'est ouvert dans le service.
- Le service n'a pas démarré correctement avant l'expiration du délai, et le port ne répond pas.

Dans la plupart des cas, cela affecte le job, mais il peut arriver que le job réussisse quand même, même si cet avertissement a été affiché. Par exemple :

- Le service a démarré peu après l'émission de l'avertissement, et le job n'utilise pas le service lié depuis le début. Dans ce cas, lorsque le job avait besoin d'accéder au service, celui-ci était peut-être déjà disponible en attente de connexions.
- Le conteneur de service ne fournit aucun service réseau, mais il effectue des opérations sur le répertoire du job (tous les services ont le répertoire du job monté en tant que volume sous `/builds`). Dans ce cas, le service effectue son travail et, comme le job n'essaie pas de s'y connecter, il ne échoue pas.

Si les services démarrent avec succès, ils démarrent avant l'exécution de [`before_script`](../yaml/_index.md#before_script). Cela signifie que vous pouvez écrire un `before_script` qui interroge le service.

Les services s'arrêtent à la fin du job, même si le job échoue.

## Utilisation des logiciels fournis par une image de service {#using-software-provided-by-a-service-image}

Lorsque vous spécifiez le `service`, cela fournit des services **network accessible**. Une base de données est l'exemple le plus simple d'un tel service.

La fonctionnalité de services n'ajoute aucun logiciel provenant des images `services` définies dans le conteneur du job.

Par exemple, si vous avez les `services` suivants définis dans votre job, les commandes `php`, `node` ou `go` ne sont pas disponibles pour votre script, et le job échoue :

```yaml
job:
  services:
    - php:8.4
    - node:latest
    - golang:1.25
  image: alpine:3.23
  script:
    - php -v
    - node -v
    - go version
```

Si vous avez besoin que `php`, `node` et `go` soient disponibles pour votre script, vous devez soit :

- Choisir une image Docker existante qui contient tous les outils nécessaires.
- Créer votre propre image Docker, avec tous les outils requis inclus, et l'utiliser dans votre job.

## Définir `services` dans le fichier `.gitlab-ci.yml` {#define-services-in-the-gitlab-ciyml-file}

Il est également possible de définir différentes images et services par job :

```yaml
default:
  before_script:
    - bundle install

test:4.0:
  image: ruby:4.0
  services:
    - postgres:18
  script:
    - bundle exec rake spec

test:3.4:
  image: ruby:3.4
  services:
    - postgres:17
  script:
    - bundle exec rake spec
```

Ou vous pouvez passer certaines [options de configuration étendues](../docker/using_docker_images.md#extended-docker-configuration-options) pour `image` et `services` :

```yaml
default:
  image:
    name: ruby:4.0
    entrypoint: ["/bin/bash"]
  services:
    - name: my-postgres:18
      alias: db,postgres,pg
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## Accéder aux services {#accessing-the-services}

Si vous ne [spécifiez pas d'alias de service](#available-settings-for-services), vous y avez accès depuis votre conteneur de compilation sous deux noms d'hôte :

- `namespace-projectname`
- `namespace__projectname`

Les noms d'hôte contenant des underscores ne sont pas conformes à la RFC et peuvent causer des problèmes dans des applications tierces.

Les alias par défaut pour le nom d'hôte du service sont créés à partir du nom de son image en suivant ces règles :

- Tout ce qui se trouve après le deux-points (`:`) est supprimé.
- Le slash (`/`) est remplacé par des doubles underscores (`__`) et l'alias principal est créé.
- Le slash (`/`) est remplacé par un tiret simple (`-`) et l'alias secondaire est créé.

Pour remplacer le comportement par défaut, vous pouvez [spécifier un ou plusieurs alias de service](#available-settings-for-services).

### Connexion des services {#connecting-services}

Vous pouvez utiliser des services interdépendants avec des jobs complexes, comme des tests de bout en bout où une API externe doit communiquer avec sa propre base de données.

Par exemple, pour un test de bout en bout d'une application front-end qui utilise une API, et où l'API a besoin d'une base de données :

```yaml
end-to-end-tests:
  image: node:latest
  services:
    - name: selenium/standalone-firefox:${FIREFOX_VERSION}
      alias: firefox
    - name: registry.gitlab.com/organization/private-api:latest
      alias: backend-api
    - name: postgres:18
      alias: db postgres db
  variables:
    FF_NETWORK_PER_BUILD: 1 # activate container-to-container networking
    POSTGRES_PASSWORD: supersecretpassword
    BACKEND_POSTGRES_HOST: postgres
  script:
    - npm install
    - npm test
```

Pour que cette solution fonctionne, vous devez utiliser [le mode réseau qui crée un nouveau réseau pour chaque job](https://docs.gitlab.com/runner/executors/docker/#create-a-network-for-each-job).

## Transmettre des variables CI/CD aux services {#passing-cicd-variables-to-services}

Vous pouvez également transmettre des [variables](../variables/_index.md) CI/CD personnalisées pour affiner vos `images` et `services` Docker directement dans le fichier `.gitlab-ci.yml`. Pour plus d'informations, consultez les [variables définies dans `.gitlab-ci.yml`](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).

```yaml
# The following variables are automatically passed down to the Postgres container
# as well as the Ruby container and available within each.
variables:
  HTTPS_PROXY: "https://10.1.1.1:8090"
  HTTP_PROXY: "https://10.1.1.1:8090"
  POSTGRES_DB: "my_custom_db"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "example"
  PGDATA: "/var/lib/postgresql/data"
  POSTGRES_INITDB_ARGS: "--encoding=UTF8 --data-checksums"

default:
  services:
    - name: postgres:18
      alias: db
      entrypoint: ["docker-entrypoint.sh"]
      command: ["postgres"]
  image:
    name: ruby:4.0
    entrypoint: ["/bin/bash"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## Paramètres disponibles pour `services` {#available-settings-for-services}

Pour des informations détaillées sur les sous-clés de `services:`, consultez la [référence YAML CI/CD](../yaml/_index.md#services).

## Démarrer plusieurs services depuis la même image {#starting-multiple-services-from-the-same-image}

Avant les nouvelles options de configuration Docker étendues, la configuration suivante ne fonctionnerait pas correctement :

```yaml
services:
  - mysql:latest
  - mysql:latest
```

Le runner démarrerait deux conteneurs, chacun utilisant l'image `mysql:latest`. Cependant, les deux seraient ajoutés au conteneur du job avec l'alias `mysql`, en fonction de la [dénomination des noms d'hôte par défaut](#accessing-the-services). Cela aurait pour conséquence que l'un des services ne serait pas accessible.

Avec les nouvelles options de configuration Docker étendues, l'exemple précédent ressemblerait à ceci :

```yaml
services:
  - name: mysql:latest
    alias: mysql-1
  - name: mysql:latest
    alias: mysql-2
```

Le runner démarre toujours deux conteneurs en utilisant l'image `mysql:latest`, mais désormais chacun d'eux est également accessible avec l'alias configuré dans le fichier `.gitlab-ci.yml`.

## Définir une commande pour le service {#setting-a-command-for-the-service}

Supposons que vous disposez d'une image `super/sql:latest` contenant une base de données SQL. Vous souhaitez l'utiliser comme service pour votre job. Supposons également que cette image ne démarre pas le processus de base de données lors du démarrage du conteneur. L'utilisateur doit utiliser manuellement `/usr/bin/super-sql run` comme commande pour démarrer la base de données.

Avant les nouvelles options de configuration Docker étendues, vous deviez :

- Créer votre propre image basée sur l'image `super/sql:latest`.
- Ajouter la commande par défaut.
- Utiliser l'image dans la configuration du job.

  - Dockerfile de l'image `my-super-sql:latest` :

    ```dockerfile
    FROM super/sql:latest
    CMD ["/usr/bin/super-sql", "run"]
    ```

  - Dans le job dans le fichier `.gitlab-ci.yml` :

    ```yaml
    services:
      - my-super-sql:latest
    ```

Avec les nouvelles options de configuration Docker étendues, vous pouvez définir une `command` dans le fichier `.gitlab-ci.yml` à la place :

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

La syntaxe de `command` est similaire à celle de [Dockerfile `CMD`](https://docs.docker.com/reference/dockerfile/#cmd).

## Utilisation des alias comme noms de conteneurs de service pour l'exécuteur Kubernetes {#using-aliases-as-service-container-names-for-the-kubernetes-executor}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421131) dans GitLab et GitLab Runner 17.9.

{{< /history >}}

Vous pouvez utiliser des alias de service comme noms de conteneurs de service pour l'exécuteur Kubernetes. GitLab Runner nomme les conteneurs en fonction des conditions suivantes :

- Lorsque plusieurs alias sont définis pour un service, le conteneur de service est nommé d'après le premier alias qui :
  - N'est pas déjà utilisé par un autre conteneur de service.
  - Respecte les [contraintes Kubernetes pour les noms de labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names).
- Lorsque les alias ne peuvent pas être utilisés pour nommer un conteneur de service, GitLab Runner revient au modèle `svc-i`.

Les exemples suivants illustrent la façon dont les alias sont utilisés pour nommer les conteneurs de service pour l'exécuteur Kubernetes.

### Un alias par service {#one-alias-per-services}

Dans le fichier `.gitlab-ci.yml` suivant :

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine
    - name: mysql:latest
      alias: mysql
```

Le système crée un Pod de job avec des conteneurs nommés `alpine` et `mysql` en plus des conteneurs standard `build` et `helper`. Ces alias sont utilisés car ils :

- Ne sont pas utilisés par un autre conteneur de service.
- Respectent les [contraintes Kubernetes pour les noms de labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names).

Cependant, dans le fichier `.gitlab-ci.yml` suivant :

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: mysql:lts
      alias: mysql
    - name: mysql:latest
      alias: mysql
```

Le système crée deux conteneurs supplémentaires nommés `mysql` et `svc-0` en plus des conteneurs `build` et `helper`. Le conteneur `mysql` correspond à l'image `mysql:lts`, tandis que le conteneur `svc-0` correspond à l'image `mysql:latest`.

### Plusieurs aliases par service {#multiple-aliases-per-services}

Dans le fichier `.gitlab-ci.yml` suivant :

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-latest
    - name: alpine:edge
      alias: alpine,alpine-edge,alpine-latest
```

Le système crée quatre conteneurs supplémentaires en plus des conteneurs `build` et `helper` :

- `alpine` qui devrait correspondre au conteneur avec l'image `alpine:latest`.
- `alpine-edge` qui devrait correspondre au conteneur avec l'image `alpine:edge` (l'alias `alpine` étant déjà utilisé pour le conteneur précédent).

Dans cet exemple, l'alias `alpine-latest` n'est pas utilisé.

Cependant, dans le fichier `.gitlab-ci.yml` suivant :

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-edge
    - name: alpine:edge
      alias: alpine,alpine-edge
    - name: alpine:3.21
      alias: alpine,alpine-edge
```

En plus des conteneurs `build` et `helper`, six autres conteneurs sont créés.

- `alpine` devrait faire référence au conteneur avec l'image `alpine:latest`.
- `alpine-edge` devrait faire référence au conteneur avec l'image `alpine:edge` (l'alias `alpine` étant déjà utilisé pour le conteneur précédent).
- `svc-0` devrait faire référence au conteneur avec l'image `alpine:3.21` (les aliases `alpine` et `alpine-edge` étant déjà utilisés pour les conteneurs précédents).

  - Le `i` dans le modèle `svc-i` n'indique pas la position du service dans la liste fournie. Il représente plutôt la position du service lorsqu'aucun alias disponible n'est trouvé.

  - Lorsqu'un alias invalide est fourni (ne respectant pas les contraintes Kubernetes), le job échoue avec l'erreur suivante (exemple avec l'alias `alpine_edge`). Cet échec se produit car les aliases sont également utilisés pour créer des entrées DNS locales sur le Pod du job.

    ```plaintext
    ERROR: Job failed (system failure): prepare environment: setting up build pod: provided host alias
    alpine_edge for service alpine:edge is invalid DNS. a lowercase RFC 1123 subdomain must consist of lower
    case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g.
    'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*').
    Check https://docs.gitlab.com/runner/shells/index/#shell-profile-loading for more information.
    ```

## Utilisation de `services` avec `docker run` (Docker-in-Docker) côte à côte {#using-services-with-docker-run-docker-in-docker-side-by-side}

Les conteneurs démarrés avec `docker run` peuvent également se connecter aux services fournis par GitLab.

Si le démarrage d'un service est coûteux ou prend du temps, vous pouvez exécuter des tests depuis différents environnements clients, tout en ne démarrant le service testé qu'une seule fois.

```yaml
access-service:
  stage: build
  image: docker:20.10.16
  services:
    - docker:dind                    # necessary for docker run
    - traefik/whoami:latest
  variables:
    FF_NETWORK_PER_BUILD: "true"     # activate container-to-container networking
  script: |
    docker run --rm --name curl \
      --volume  "$(pwd)":"$(pwd)"    \
      --workdir "$(pwd)"             \
      --network=host                 \
      curlimages/curl:latest curl "http://traefik-whoami"
```

Pour que cette solution fonctionne, vous devez :

- Utiliser [le mode réseau qui crée un nouveau réseau pour chaque job](https://docs.gitlab.com/runner/executors/docker/#create-a-network-for-each-job).
- [Ne pas utiliser l'exécuteur Docker avec la liaison de socket Docker](../docker/using_docker_build.md#use-docker-socket-binding). Si vous devez le faire, dans l'exemple précédent, utilisez le nom de réseau dynamique créé pour ce job à la place de `host`.

## Fonctionnement de l'intégration Docker {#how-docker-integration-works}

Voici une vue d'ensemble de haut niveau des étapes effectuées par Docker lors de l'exécution d'un job.

1. Créer tout conteneur de service : `mysql`, `postgresql`, `mongodb`, `redis`.
1. Créer un conteneur de cache pour stocker tous les volumes tels que définis dans `config.toml` et `Dockerfile` de l'image de compilation (`ruby:4.0` comme dans les exemples précédents).
1. Créer un conteneur de compilation et lier tout conteneur de service au conteneur de compilation.
1. Démarrer le conteneur de compilation et envoyer un script de job au conteneur.
1. Exécuter le script du job.
1. Extraire le code dans : `/builds/group-name/project-name/`.
1. Exécuter toute étape définie dans `.gitlab-ci.yml`.
1. Vérifier le statut de sortie du script de compilation.
1. Supprimer le conteneur de compilation et tous les conteneurs de service créés.

## Capture des journaux des conteneurs de service {#capturing-service-container-logs}

Les journaux générés par les applications s'exécutant dans des conteneurs de service peuvent être capturés pour un examen et un débogage ultérieurs. Consultez les journaux des conteneurs de service lorsqu'un conteneur de service démarre avec succès mais provoque des échecs de job en raison d'un comportement inattendu. Les journaux peuvent indiquer une configuration manquante ou incorrecte du service dans le conteneur.

`CI_DEBUG_SERVICES` ne doit être activé que lorsque les conteneurs de service font l'objet d'un débogage actif, car la capture des journaux des conteneurs de service a des conséquences sur le stockage et les performances.

> [!warning]
> L'activation de `CI_DEBUG_SERVICES` peut révéler des variables masquées. Lorsque `CI_DEBUG_SERVICES` est activé, les journaux des conteneurs de service et les journaux du job CI sont diffusés simultanément dans le journal de trace du job. Cela signifie que les journaux des conteneurs de service peuvent être insérés dans un journal masqué du job. Cela contrecarrerait le mécanisme de masquage des variables et entraînerait la révélation de la variable masquée.

Pour activer la journalisation des services, ajoutez la variable CI/CD `CI_DEBUG_SERVICES` au fichier `.gitlab-ci.yml` du projet :

```yaml
variables:
  CI_DEBUG_SERVICES: "true"
```

Les valeurs acceptées sont :

- Activé : `TRUE`, `true`, `True`
- Désactivé : `FALSE`, `false`, `False`

Toute autre valeur entraîne un message d'erreur et désactive effectivement la fonctionnalité.

Lorsqu'il est activé, les journaux de tous les conteneurs de service sont capturés et diffusés simultanément dans le journal de trace des jobs avec les autres journaux. Les journaux de chaque conteneur sont préfixés par les aliases du conteneur et affichés dans une couleur différente.

> [!note]
> Pour diagnostiquer les échecs de job, vous pouvez ajuster le niveau de journalisation dans votre conteneur de service pour lequel vous souhaitez capturer des journaux. Le niveau de journalisation par défaut peut ne pas fournir suffisamment d'informations pour le dépannage.

Consultez [Masquer une variable CI/CD](../variables/_index.md#mask-a-cicd-variable)

## Déboguer un job localement {#debug-a-job-locally}

Les commandes suivantes sont exécutées sans privilèges root. Vérifiez que vous pouvez exécuter des commandes Docker avec votre compte utilisateur.

Commencez par créer un fichier nommé `build_script` :

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make runner-bin-host
EOF
```

Cet exemple utilise le dépôt GitLab Runner qui contient un Makefile, de sorte que l'exécution de `make` exécute la cible définie dans le Makefile. Au lieu de `make runner-bin-host`, vous pouvez exécuter la commande spécifique à votre projet.

Créez ensuite un conteneur de service :

```shell
docker run -d --name service-redis redis:latest
```

La commande précédente crée un conteneur de service nommé `service-redis` en utilisant la dernière image Redis. Le conteneur de service s'exécute en arrière-plan (`-d`).

Enfin, créez un conteneur de compilation en exécutant le fichier `build_script` que vous avez créé précédemment :

```shell
docker run --name build -i --link=service-redis:redis golang:latest /bin/bash < build_script
```

La commande précédente crée un conteneur nommé `build` issu de l'image `golang:latest` et ayant un service lié à lui. Le `build_script` est transmis via `stdin` à l'interpréteur bash qui exécute à son tour le `build_script` dans le conteneur `build`.

Utilisez la commande suivante pour supprimer les conteneurs une fois les tests terminés :

```shell
docker rm -f -v build service-redis
```

Cette commande supprime de force (`-f`) le conteneur `build`, le conteneur de service et tous les volumes (`-v`) créés lors de la création du conteneur.

## Sécurité lors de l'utilisation de conteneurs de service {#security-when-using-services-containers}

Le mode privilégié Docker s'applique aux services. Cela signifie que le conteneur de l'image de service peut accéder au système hôte. Vous devez utiliser uniquement des images de conteneurs provenant de sources fiables.

## Répertoire `/builds` partagé {#shared-builds-directory}

Le répertoire de compilation est monté en tant que volume sous `/builds` et est partagé entre le job et les services. Le job extrait le projet dans `/builds/$CI_PROJECT_PATH` une fois les services en cours d'exécution. Votre service peut avoir besoin d'accéder aux fichiers du projet ou de stocker des artefacts. Si c'est le cas, attendez que le répertoire existe et que `$CI_COMMIT_SHA` soit extrait. Toute modification effectuée avant que le job termine son processus d'extraction est supprimée par le processus d'extraction.

Le service doit détecter quand le répertoire du job est rempli et prêt à être traité. Par exemple, attendez qu'un fichier spécifique soit disponible.

Les services qui commencent à fonctionner immédiatement après leur lancement risquent d'échouer, car les données du job peuvent ne pas encore être disponibles. Par exemple, les conteneurs utilisent la commande `docker build` pour établir une connexion réseau avec le service DinD. Le service demande à son API de démarrer la compilation d'une image de conteneur. Le Docker Engine doit avoir accès aux fichiers que vous référencez dans votre Dockerfile. Par conséquent, vous avez besoin d'accéder au `CI_PROJECT_DIR` dans le service. Cependant, Docker Engine n'essaie pas d'y accéder avant que la commande `docker build` soit appelée dans un job. À ce moment, le répertoire `/builds` est déjà rempli de données. Le service qui tente d'écrire dans `CI_PROJECT_DIR` immédiatement après son démarrage peut échouer avec une erreur `No such file or directory`.

Dans les scénarios où des services interagissant avec les données du job ne sont pas contrôlés par le job lui-même, consultez le [workflow de l'exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/#docker-executor-workflow).
