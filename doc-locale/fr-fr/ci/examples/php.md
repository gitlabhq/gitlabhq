---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tester des projets PHP
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce guide couvre les instructions de base pour la construction de projets PHP.

Deux scénarios de test sont abordés : l'utilisation de l'exécuteur Docker et l'utilisation de l'exécuteur Shell.

## Tester des projets PHP avec l'exécuteur Docker {#test-php-projects-using-the-docker-executor}

Bien qu'il soit possible de tester des applications PHP sur n'importe quel système, cela nécessiterait une configuration manuelle de la part du développeur. Vous pouvez contourner cela en utilisant l'[image PHP Docker](https://hub.docker.com/_/php) officielle disponible sur Docker Hub.

Cela vous permet de tester des projets PHP avec différentes versions de PHP. Cependant, vous devez encore configurer certaines choses manuellement.

Comme pour chaque job, vous devez créer un fichier `.gitlab-ci.yml` valide décrivant l'environnement de build.

Tout d'abord, spécifiez l'image PHP utilisée pour le processus du job. (Pour en savoir plus sur la signification d'une image dans le jargon du runner, consultez [Utilisation des images Docker](../docker/using_docker_images.md#what-is-an-image).)

Commencez par ajouter l'image à votre `.gitlab-ci.yml` :

```yaml
image: php:5.6
```

Les images officielles sont excellentes, mais elles manquent de quelques outils de test. Vous devez d'abord préparer l'environnement de build. Pour ce faire, créez un script qui installe tous les prérequis avant le début des tests proprement dits.

Créez un fichier `ci/docker_install.sh` dans le répertoire racine de votre dépôt avec le contenu suivant :

```shell
#!/bin/bash

# You need to install dependencies only for Docker
[[ ! -e /.dockerenv ]] && exit 0

set -xe

# Install git (the php image doesn't have it) which is required by composer
apt-get update -yqq
apt-get install git -yqq

# Install phpunit, the tool that you will use for testing
curl --location --output /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar"
chmod +x /usr/local/bin/phpunit

# Install mysql driver
# Here you can install any other extension that you need
docker-php-ext-install pdo_mysql
```

Vous vous demandez peut-être ce qu'est `docker-php-ext-install`. En bref, c'est un script fourni par l'image PHP Docker officielle que vous pouvez utiliser pour installer des extensions. Pour plus d'informations, consultez [la documentation](https://hub.docker.com/_/php).

Maintenant que vous avez créé le script avec les prérequis pour votre environnement de build, vous pouvez l'ajouter à `.gitlab-ci.yml` :

```yaml
before_script:
  - bash ci/docker_install.sh > /dev/null
```

Dernière étape : exécutez les tests réels à l'aide de `phpunit` :

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

Enfin, effectuez un commit de vos fichiers et poussez-les vers GitLab pour voir votre build réussir (ou échouer).

Le fichier `.gitlab-ci.yml` final devrait ressembler à ceci :

```yaml
default:
  # Select image from https://hub.docker.com/_/php
  image: php:5.6
  before_script:
    # Install dependencies
    - bash ci/docker_install.sh > /dev/null

test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

### Tester différentes versions de PHP dans les builds Docker {#test-against-different-php-versions-in-docker-builds}

Tester plusieurs versions de PHP est très simple. Il suffit d'ajouter un autre job avec une version d'image Docker différente et le runner fait le reste :

```yaml
default:
  before_script:
    # Install dependencies
    - bash ci/docker_install.sh > /dev/null

# Test PHP5.6
test:5.6:
  image: php:5.6
  script:
    - phpunit --configuration phpunit_myapp.xml

# Test PHP7.0 (good luck with that)
test:7.0:
  image: php:7.0
  script:
    - phpunit --configuration phpunit_myapp.xml
```

### Configuration PHP personnalisée dans les builds Docker {#custom-php-configuration-in-docker-builds}

Il arrive que vous ayez besoin de personnaliser votre environnement PHP en plaçant votre fichier `.ini` dans `/usr/local/etc/php/conf.d/`. À cet effet, ajoutez une action `before_script` :

```yaml
before_script:
  - cp my_php.ini /usr/local/etc/php/conf.d/test.ini
```

Bien entendu, `my_php.ini` doit être présent dans le répertoire racine de votre dépôt.

## Tester des projets PHP avec l'exécuteur Shell {#test-php-projects-using-the-shell-executor}

L'exécuteur Shell exécute votre job dans une session de terminal sur votre serveur. Pour tester vos projets, vous devez d'abord vous assurer que toutes les dépendances sont installées.

Par exemple, sur une VM exécutant Debian 8, commencez par mettre à jour le cache, puis installez `phpunit` et `php5-mysql` :

```shell
sudo apt-get update -y
sudo apt-get install -y phpunit php5-mysql
```

Ensuite, ajoutez l'extrait suivant à votre `.gitlab-ci.yml` :

```yaml
test:app:
  script:
    - phpunit --configuration phpunit_myapp.xml
```

Enfin, poussez vers GitLab et laissez les tests commencer !

### Tester différentes versions de PHP dans les builds Shell {#test-against-different-php-versions-in-shell-builds}

Le projet [phpenv](https://github.com/phpenv/phpenv) vous permet de gérer différentes versions de PHP, chacune avec sa propre configuration. C'est particulièrement utile lors du test de projets PHP avec l'exécuteur Shell.

Vous devez l'installer sur votre machine de build sous l'utilisateur `gitlab-runner` en suivant [le guide d'installation upstream](https://github.com/phpenv/phpenv#installation).

L'utilisation de phpenv vous permet également de configurer l'environnement PHP avec :

```shell
phpenv config-add my_config.ini
```

**Important note** : Il semble que `phpenv/phpenv` [soit abandonné](https://github.com/phpenv/phpenv/issues/57). Il existe une duplication sur [`madumlao/phpenv`](https://github.com/madumlao/phpenv) qui tente de redonner vie au projet. [`CHH/phpenv`](https://github.com/CHH/phpenv) semble également être une bonne alternative. L'utilisation de l'un des outils mentionnés fonctionne avec les commandes phpenv de base. Vous guider dans le choix du bon phpenv dépasse le cadre de ce tutoriel.*

### Installer des extensions personnalisées {#install-custom-extensions}

Étant donné qu'il s'agit d'une installation assez minimale de l'environnement PHP, vous pouvez avoir besoin de certaines extensions qui ne sont pas actuellement présentes sur la machine de build.

Pour installer des extensions supplémentaires, exécutez :

```shell
pecl install <extension>
```

Il n'est pas conseillé d'ajouter cela à `.gitlab-ci.yml`. Vous devez exécuter cette commande une seule fois, uniquement pour configurer l'environnement de build.

## Étendre vos tests {#extend-your-tests}

### Utiliser `atoum` {#using-atoum}

Au lieu de PHPUnit, vous pouvez utiliser n'importe quel autre outil pour exécuter des tests unitaires. Par exemple, vous pouvez utiliser [`atoum`](https://github.com/atoum/atoum) :

```yaml
test:atoum:
  before_script:
    - wget http://downloads.atoum.org/nightly/mageekguy.atoum.phar
  script:
    - php mageekguy.atoum.phar
```

### Utiliser Composer {#using-composer}

La majorité des projets PHP utilisent Composer pour gérer leurs packages PHP. Pour exécuter Composer avant de lancer vos tests, ajoutez ce qui suit à votre `.gitlab-ci.yml` :

```yaml
# Composer stores all downloaded packages in the vendor/ directory.
# Do not use the following if the vendor/ directory is committed to
# your git repository.
default:
  cache:
    paths:
      - vendor/
  before_script:
    # Install composer dependencies
    - wget https://composer.github.io/installer.sig -O - -q | tr -d '\n' > installer.sig
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php -r "if (hash_file('SHA384', 'composer-setup.php') === file_get_contents('installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    - php composer-setup.php
    - php -r "unlink('composer-setup.php'); unlink('installer.sig');"
    - php composer.phar install
```

## Accéder aux packages ou dépendances privés {#access-private-packages-or-dependencies}

Si votre suite de tests doit accéder à un dépôt privé, vous devez configurer les [clés SSH](../jobs/ssh_keys.md) pour pouvoir le cloner.

## Utiliser des bases de données ou d'autres services {#use-databases-or-other-services}

La plupart du temps, vous avez besoin d'une base de données en cours d'exécution pour que vos tests puissent s'exécuter. Si vous utilisez l'exécuteur Docker, vous pouvez tirer parti de Docker pour créer des liens vers d'autres conteneurs. Avec GitLab Runner, cela peut être réalisé en définissant un `service`.

Cette fonctionnalité est couverte dans la documentation [des services CI](../services/_index.md).

## Exemple de projet {#example-project}

Pour votre commodité, il existe un [exemple de projet PHP](https://gitlab.com/gitlab-examples/php) qui s'exécute sur [GitLab.com](https://gitlab.com) en utilisant des [runners d'instance](../runners/_index.md) disponibles publiquement.

Vous souhaitez le modifier ? Dupliquez-le, effectuez un commit et poussez vos modifications. En quelques instants, les modifications sont récupérées par un runner public et le job commence.
