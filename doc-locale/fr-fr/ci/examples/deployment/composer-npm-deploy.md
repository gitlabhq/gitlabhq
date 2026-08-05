---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exécution de scripts Composer et npm avec déploiement via SCP dans GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce guide traite de la construction des dépendances d'un projet PHP tout en compilant des ressources via un script npm à l'aide de [GitLab CI/CD](../../_index.md).

Il est possible de créer votre propre image avec des versions personnalisées de PHP et de Node.js. Par souci de concision, ce guide utilise une [image Docker](https://hub.docker.com/r/tetraweb/php/) existante avec PHP et Node.js installés.

```yaml
image: tetraweb/php
```

L'étape suivante consiste à installer les paquets zip/unzip et à rendre composer disponible. Placez ces éléments dans la section `before_script` :

```yaml
before_script:
  - apt-get update
  - apt-get install zip unzip
  - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  - php composer-setup.php
  - php -r "unlink('composer-setup.php');"
```

Cela garantit que toutes les conditions requises sont prêtes. Ensuite, exécutez `composer install` pour récupérer toutes les dépendances PHP et `npm install` pour charger les paquets Node.js. Puis exécutez le script `npm`. Ajoutez les commandes à la section `before_script` :

```yaml
before_script:
  # ...
  - php composer.phar install
  - npm install
  - npm run deploy
```

Dans ce cas particulier, le script `npm deploy` est un script Gulp qui effectue les opérations suivantes :

1. Compiler CSS & JS
1. Créer des sprites
1. Copier diverses ressources (images, polices)
1. Remplacer certaines chaînes de caractères

Toutes ces opérations placent l'ensemble des fichiers dans un dossier `build`, prêt à être déployé sur un serveur en production.

## Comment transférer des fichiers vers un serveur en production {#how-to-transfer-files-to-a-live-server}

Vous disposez de plusieurs options telles que rsync, SCP ou SFTP. Pour l'instant, utilisez SCP.

Pour que cela fonctionne, vous devez ajouter une variable CI/CD GitLab (accessible sur `gitlab.example/your-project-name/variables`). Nommez cette variable CI/CD `STAGING_PRIVATE_KEY` et définissez-la sur la clé SSH **privée** de votre serveur.

### Conseil de sécurité {#security-tip}

Créez un utilisateur qui a accès **uniquement** au dossier qui doit être mis à jour.

Une fois cette variable créée, assurez-vous que la clé est ajoutée au conteneur Docker lors de l'exécution :

```yaml
before_script:
  # - ....
  - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
  - mkdir -p ~/.ssh
  - eval $(ssh-agent -s)
  - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
```

Ce script effectue les actions suivantes :

1. Vérifier si `ssh-agent` est disponible et l'installer dans le cas contraire.
1. Créer le dossier `~/.ssh`.
1. S'assurer que l'environnement d'exécution du script utilise bash.
1. Désactiver la vérification de l'hôte. Chaque connexion s'effectue dans un nouvel environnement ; la désactivation de la vérification de l'hôte garantit que GitLab ne demande pas à l'utilisateur de vérifier et d'accepter l'identité du serveur avant chaque connexion.

C'est essentiellement tout ce dont vous avez besoin dans la section `before_script`.

## Comment déployer {#how-to-deploy}

Pour déployer le dossier `build` depuis l'image Docker vers votre serveur, créez un nouveau job :

```yaml
stage_deploy:
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```

Voici le détail :

1. `rules:if: $CI_COMMIT_BRANCH == "dev"` signifie que cette build ne s'exécute que lorsqu'un élément est poussé vers la branche `dev`. Vous pouvez supprimer ce bloc entièrement et faire en sorte que tout s'exécute à chaque push (mais ce n'est probablement pas ce que vous souhaitez).
1. `ssh-add ...` ajoute la clé privée que vous avez ajoutée dans l'interface web au conteneur Docker.
1. Se connecter via `ssh` et créer un nouveau dossier `_tmp`.
1. Se connecter via `scp` et téléverser le dossier `build` (généré par un script `npm`) dans le dossier `_tmp` créé précédemment.
1. Se connecter à nouveau via `ssh` et déplacer le dossier `live` vers un dossier `_old`, puis déplacer `_tmp` vers `live`.
1. Se connecter via SSH et supprimer le dossier `_old`.

La section `artifacts` indique à GitLab CI/CD de conserver le répertoire `build` (vous pourrez le télécharger ultérieurement si nécessaire).

### Pourquoi procéder ainsi {#why-do-it-this-way}

Si vous utilisez ceci uniquement pour un serveur de recette, vous pouvez le faire en deux étapes :

```yaml
- ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/live/*"
- scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/live
```

Le problème est qu'il existe une courte période pendant laquelle l'application n'est pas disponible sur votre serveur.

Par conséquent, pour un environnement de production, les étapes supplémentaires garantissent qu'une application fonctionnelle est disponible à tout moment.

## Où aller ensuite {#where-to-go-next}

Comme il s'agissait d'un projet WordPress, il inclut de vrais extraits de code. Voici quelques idées supplémentaires que vous pouvez explorer :

- Un script légèrement différent pour la branche par défaut vous permet de déployer sur un serveur de production depuis cette branche et sur un serveur de recette depuis n'importe quelle autre branche.
- Au lieu de le pousser en production, vous pouvez le pousser vers le dépôt officiel WordPress.
- Vous pouvez générer des domaines de texte i18n à la volée.

---

Le fichier `.gitlab-ci.yml` final ressemble à ceci :

```yaml
stage_deploy:
  image: tetraweb/php
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  before_script:
    - apt-get update
    - apt-get install zip unzip
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php
    - php -r "unlink('composer-setup.php');"
    - php composer.phar install
    - npm install
    - npm run deploy
    - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
    - mkdir -p ~/.ssh
    - eval $(ssh-agent -s)
    - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```
