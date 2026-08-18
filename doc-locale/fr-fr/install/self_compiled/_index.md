---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Installez GitLab depuis les sources sur Debian ou Ubuntu en compilant et en configurant chaque composant manuellement.
title: Installation auto-compilée
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Voici le guide d'installation officiel pour configurer un serveur GitLab de production à partir des fichiers sources. Il a été créé pour et testé sur les systèmes d'exploitation **Debian/Ubuntu**. Consultez [requirements.md](../requirements.md) pour connaître les exigences matérielles et relatives au système d'exploitation. Si vous souhaitez procéder à l'installation sur RHEL/CentOS, vous devez utiliser les [packages Linux](https://about.gitlab.com/install/). Pour de nombreuses autres options d'installation, consultez la [page principale d'installation](_index.md).

Ce guide est long car il couvre de nombreux cas et inclut toutes les commandes dont vous avez besoin. Les étapes suivantes ont été éprouvées. **Use caution when you deviate** de ce guide. Assurez-vous de ne pas enfreindre les hypothèses que GitLab émet sur son environnement. Par exemple, de nombreuses personnes rencontrent des problèmes de permissions parce qu'elles ont modifié l'emplacement des répertoires ou exécuté des services en tant que le mauvais utilisateur.

Si vous trouvez un bug/une erreur dans ce guide, **submit a merge request** en suivant le [guide de contribution](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CONTRIBUTING.md).

## Envisager l'installation par package Linux {#consider-the-linux-package-installation}

Étant donné qu'une installation auto-compilée représente beaucoup de travail et est sujette aux erreurs, nous recommandons vivement la [installation par package Linux](https://about.gitlab.com/install/) (deb/rpm), rapide et fiable.

L'une des raisons pour lesquelles le package Linux est plus fiable est son utilisation de runit pour redémarrer les processus GitLab en cas de plantage. Sur les instances GitLab très sollicitées, l'utilisation mémoire du worker en arrière-plan Sidekiq augmente avec le temps. Les packages Linux résolvent ce problème en [permettant à Sidekiq de se terminer correctement](../../administration/sidekiq/sidekiq_memory_killer.md) s'il utilise trop de mémoire. Après cette interruption, runit détecte que Sidekiq ne fonctionne pas et le redémarre. Étant donné que les installations auto-compilées n'utilisent pas runit pour la supervision des processus, Sidekiq ne peut pas être interrompu et son utilisation mémoire augmente avec le temps.

## Sélectionner une version à installer {#select-a-version-to-install}

Assurez-vous de consulter [ce guide d'installation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/install/self_compiled/_index.md) depuis la branche (version) de GitLab que vous souhaitez installer (par exemple, `16-0-stable`). Vous pouvez sélectionner la branche dans la liste déroulante des versions dans le coin supérieur gauche de GitLab (sous la barre de menu).

Si la branche stable au numéro le plus élevé n'est pas claire, consultez le [blog GitLab](https://about.gitlab.com/blog/) pour trouver des liens vers les guides d'installation par version.

## Prérequis logiciels {#software-requirements}

| Logiciel                | Version minimale | Notes                                                                                                                                                                                                                                                                                  |
|:------------------------|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Ruby](#2-ruby)         | `3.2.x`         | De GitLab 16.7 à 17.4, Ruby 3.1 est requis. Dans GitLab 17.5 et versions ultérieures, Ruby 3.2 est requis. Vous devez utiliser l'implémentation standard MRI de Ruby. Nous aimons [JRuby](https://www.jruby.org/) et [Rubinius](https://github.com/rubinius/rubinius#the-rubinius-language-platform), mais GitLab nécessite plusieurs Gems dotés d'extensions natives. |
| [RubyGems](#3-rubygems) | `3.5.x`         | Une version spécifique de RubyGems n'est pas requise, mais vous devriez effectuer une mise à jour pour bénéficier de certaines améliorations de performances connues. |
| [Go](#4-go)             | `1.22.x`        | Dans GitLab 17.1 et versions ultérieures, Go 1.22 ou une version ultérieure est requis.                                                                                                                                                                                                                                        |
| [Git](#git)             | `2.47.x`        | Dans GitLab 17.7 et versions ultérieures, Git 2.47.x et versions ultérieures est requis. Vous devriez utiliser la [version Git fournie par Gitaly](#git).                                                                                                                                                   |
| [Node.js](#5-node)      | `20.13.x`       | Dans GitLab 17.0 et versions ultérieures, Node.js 20.13 ou une version ultérieure est requis.                                                                                                                                                                                                                                  |
| [PostgreSQL](#7-database) | `16.x`          | Dans GitLab 18.0 et versions ultérieures, PostgreSQL 16 ou une version ultérieure est requis.                                                                                                                                                                                                                                  |

## Structure des répertoires GitLab {#gitlab-directory-structure}

Les répertoires suivants sont créés au fur et à mesure des étapes d'installation :

```plaintext
|-- home
|   |-- git
|       |-- .ssh
|       |-- gitlab
|       |-- gitlab-shell
|       |-- repositories
```

- `/home/git/.ssh` - Contient les paramètres OpenSSH. Plus précisément, le fichier `authorized_keys` géré par GitLab Shell.
- `/home/git/gitlab` - Logiciel principal de GitLab.
- `/home/git/gitlab-shell` - Composant complémentaire principal de GitLab. Gère le clonage SSH et d'autres fonctionnalités.
- `/home/git/repositories` - Dépôts nus pour tous les projets organisés par espace de nommage. Ce répertoire est l'endroit où les dépôts Git qui sont poussés/tirés sont conservés pour tous les projets. **Cette zone contient des données critiques pour les projets. [Conservez une sauvegarde](../../administration/backup_restore/_index.md)**.

Les emplacements par défaut des dépôts peuvent être configurés dans `config/gitlab.yml` de GitLab et `config.yml` de GitLab Shell.

Il n'est pas nécessaire de créer ces répertoires manuellement maintenant, et le faire peut provoquer des erreurs plus tard lors de l'installation.

## Workflow d'installation {#installation-workflow}

L'installation de GitLab consiste à configurer les composants suivants :

1. [Packages et dépendances](#1-packages-and-dependencies)
1. [Ruby](#2-ruby)
1. [RubyGems](#3-rubygems)
1. [Go](#4-go)
1. [Node](#5-node)
1. [Utilisateurs système](#6-system-users)
1. [Base de données](#7-database)
1. [Redis](#8-redis)
1. [GitLab](#9-gitlab)
1. [NGINX](#10-nginx)

## 1\. Packages et dépendances {#1-packages-and-dependencies}

### sudo {#sudo}

`sudo` n'est pas installé sur Debian par défaut. Assurez-vous que votre système est à jour et installez-le.

```shell
# run as root!
apt-get update -y
apt-get upgrade -y
apt-get install sudo -y
```

### Dépendances de compilation {#build-dependencies}

Installez les packages requis (nécessaires pour compiler Ruby et les extensions natives aux gems Ruby) :

```shell
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
  libreadline-dev libncurses5-dev libffi-dev curl openssh-server libxml2-dev libxslt-dev \
  libcurl4-openssl-dev libicu-dev libkrb5-dev logrotate rsync python3-docutils pkg-config cmake \
  runit-systemd
```

> [!note]
> GitLab nécessite OpenSSL version 1.1. Si votre distribution Linux inclut une version différente d'OpenSSL, vous devrez peut-être installer la version 1.1 manuellement.

### Git {#git}

Vous devriez utiliser la [version Git fournie par Gitaly](https://gitlab.com/gitlab-org/gitaly/-/issues/2729) qui :

- Est toujours à la version requise par GitLab.
- Peut contenir des correctifs personnalisés requis pour un fonctionnement correct.

1. Installez les dépendances nécessaires :

   ```shell
   sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential git-core
   ```

1. Clonez le dépôt Gitaly et compilez Git. Remplacez `<X-Y-stable>` par la branche stable qui correspond à la version de GitLab que vous souhaitez installer. Par exemple, si vous souhaitez installer GitLab 16.7, utilisez le nom de branche `16-7-stable` :

   ```shell
   git clone https://gitlab.com/gitlab-org/gitaly.git -b <X-Y-stable> /tmp/gitaly
   cd /tmp/gitaly
   sudo make git GIT_PREFIX=/usr/local
   ```

1. Vous pouvez également supprimer le Git système et ses dépendances :

   ```shell
   sudo apt remove -y git-core
   sudo apt autoremove
   ```

Lors de la [modification de `config/gitlab.yml` plus tard](#configure-it), pensez à changer le chemin Git :

- De :

  ```yaml
  git:
    bin_path: /usr/bin/git
  ```

- Vers :

  ```yaml
  git:
    bin_path: /usr/local/bin/git
  ```

### GraphicsMagick {#graphicsmagick}

Pour que le [Favicon personnalisé](../../administration/appearance.md#customize-the-favicon) fonctionne, GraphicsMagick doit être installé.

```shell
sudo apt-get install -y graphicsmagick
```

### Serveur de messagerie {#mail-server}

Pour recevoir des notifications par e-mail, assurez-vous d'installer un serveur de messagerie. Par défaut, Debian est livré avec `exim4` mais celui-ci [présente des problèmes](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/12754) tandis qu'Ubuntu n'en inclut pas. Le serveur de messagerie recommandé est `postfix` et vous pouvez l'installer avec :

```shell
sudo apt-get install -y postfix
```

Sélectionnez ensuite `Internet Site` et appuyez sur <kbd>Enter</kbd> pour confirmer le nom d'hôte.

### ExifTool {#exiftool}

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse#dependencies) nécessite `exiftool` pour supprimer les données EXIF des images téléversées.

```shell
sudo apt-get install -y libimage-exiftool-perl
```

## 2\. Ruby {#2-ruby}

L'interpréteur Ruby est requis pour exécuter GitLab. Consultez la [section des prérequis](#software-requirements) pour connaître les exigences minimales de Ruby.

Les gestionnaires de versions Ruby tels que RVM, rbenv ou chruby peuvent provoquer des problèmes difficiles à diagnostiquer avec GitLab. Vous devriez plutôt [installer Ruby](https://www.ruby-lang.org/en/documentation/installation/) depuis le code source officiel.

## 3\. RubyGems {#3-rubygems}

Parfois, une version de RubyGems plus récente que celle fournie avec Ruby est requise.

Pour effectuer une mise à jour vers une version spécifique :

```shell
gem update --system 3.4.12
```

Ou la dernière version :

```shell
gem update --system
```

## 4\. Go {#4-go}

GitLab possède plusieurs démons écrits en Go. Pour installer GitLab, vous devez installer un compilateur Go. Les instructions suivantes supposent que vous utilisez Linux 64 bits. Vous pouvez trouver des téléchargements pour d'autres plateformes sur la [page de téléchargement de Go](https://go.dev/dl/).

```shell
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
echo '904b924d435eaea086515bc63235b192ea441bd8c9b198c507e85009e6e4c7f0  go1.22.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.22.5.linux-amd64.tar.gz
```

## 5\. Node {#5-node}

GitLab nécessite l'utilisation de Node pour compiler les ressources JavaScript, et de Yarn pour gérer les dépendances JavaScript. Les exigences minimales actuelles pour ceux-ci sont :

- `node` versions 20.x (v20.13.0 ou ultérieure). [D'autres versions LTS de Node.js](https://github.com/nodejs/release#release-schedule) pourraient être en mesure de compiler les ressources, mais nous garantissons uniquement Node.js 20.x.
- `yarn` = v1.22.x (Yarn 2 n'est pas encore pris en charge)

Dans de nombreuses distributions, les versions fournies par les dépôts de packages officiels sont obsolètes, nous devons donc les installer via les commandes suivantes :

```shell
# install node v20.x
curl --location "https://deb.nodesource.com/setup_20.x" | sudo bash -
sudo apt-get install -y nodejs

npm install --global yarn
```

Consultez les sites officiels de [node](https://nodejs.org/en/download) et de [yarn](https://classic.yarnpkg.com/en/docs/install/) si vous rencontrez des difficultés avec ces étapes.

## 6\. Utilisateurs système {#6-system-users}

Créez un utilisateur `git` pour GitLab :

```shell
sudo adduser --disabled-login --gecos 'GitLab' git
```

## 7\. Base de données {#7-database}

> [!note]
> Seul PostgreSQL est pris en charge. Dans GitLab 18.0 et versions ultérieures, nous [exigeons PostgreSQL 16+](../requirements.md#postgresql).

1. Installez les packages de base de données.

   Pour Ubuntu 22.04 et versions ultérieures :

   ```shell
   sudo apt install -y postgresql postgresql-client libpq-dev postgresql-contrib
   ```

   Pour Ubuntu 20.04 et versions antérieures, la version de PostgreSQL disponible ne répond pas aux exigences de version minimale. Vous devez ajouter le dépôt de PostgreSQL :

   ```shell
   sudo curl --fail --silent --show-error --output /etc/apt/keyrings/postgresql.asc \
             --url "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
   echo "deb [ signed-by=/etc/apt/keyrings/postgresql.asc ] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" |
        sudo tee /etc/apt/sources.list.d/pgdg.list
   sudo apt-get update
   sudo apt-get -y install postgresql-16
   ```

1. Vérifiez que la version de PostgreSQL dont vous disposez est prise en charge par la version de GitLab que vous installez :

   ```shell
   psql --version
   ```

1. Démarrez le service PostgreSQL et confirmez que le service est en cours d'exécution :

   ```shell
   sudo service postgresql start
   sudo service postgresql status
   ```

1. Créez un utilisateur de base de données pour GitLab :

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
   ```

1. Créez l'extension `pg_trgm` :

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
   ```

1. Créez l'extension `btree_gist` :

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
   ```

1. Créez l'extension `plpgsql` :

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS plpgsql;"
   ```

1. Créez la base de données de production GitLab et accordez tous les privilèges sur la base de données :

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
   ```

1. Essayez de vous connecter à la nouvelle base de données avec le nouvel utilisateur :

   ```shell
   sudo -u git -H psql -d gitlabhq_production
   ```

1. Vérifiez si l'extension `pg_trgm` est activée :

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'pg_trgm'
   AND installed_version IS NOT NULL;
   ```

   Si l'extension est activée, la sortie suivante est produite :

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. Vérifiez si l'extension `btree_gist` est activée :

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'btree_gist'
   AND installed_version IS NOT NULL;
   ```

   Si l'extension est activée, la sortie suivante est produite :

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. Vérifiez si l'extension `plpgsql` est activée :

   ```sql
   SELECT true AS enabled
   FROM pg_available_extensions
   WHERE name = 'plpgsql'
   AND installed_version IS NOT NULL;
   ```

   Si l'extension est activée, la sortie suivante est produite :

   ```plaintext
   enabled
   ---------
    t
   (1 row)
   ```

1. Quittez la session de base de données :

   ```shell
   gitlabhq_production> \q
   ```

## 8\. Redis {#8-redis}

Consultez la [page des prérequis](../requirements.md#redis-or-valkey) pour connaître les exigences minimales de Redis.

Installez Redis avec :

```shell
sudo apt-get install redis-server
```

Une fois terminé, vous pouvez configurer Redis :

```shell
# Configure redis to use sockets
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.orig

# Disable Redis listening on TCP by setting 'port' to 0
sudo sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf

# Enable Redis socket for default Debian / Ubuntu path
echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf

# Grant permission to the socket to all members of the redis group
echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf

# Add git to the redis group
sudo usermod -aG redis git
```

### Superviser Redis avec systemd {#supervise-redis-with-systemd}

Si votre distribution utilise systemd init et que la sortie de la commande suivante est `notify`, vous ne devez effectuer aucune modification :

```shell
systemctl show --value --property=Type redis-server.service
```

Si la sortie n'est pas `notify`, exécutez :

```shell
# Configure Redis to not daemonize, but be supervised by systemd instead and disable the pidfile
sudo sed -i \
         -e 's/^daemonize yes$/daemonize no/' \
         -e 's/^supervised no$/supervised systemd/' \
         -e 's/^pidfile/# pidfile/' /etc/redis/redis.conf
sudo chown redis:redis /etc/redis/redis.conf

# Make the same changes to the systemd unit file
sudo mkdir -p /etc/systemd/system/redis-server.service.d
sudo tee /etc/systemd/system/redis-server.service.d/10fix_type.conf <<EOF
[Service]
Type=notify
PIDFile=
EOF

# Reload the redis service
sudo systemctl daemon-reload

# Activate the changes to redis.conf
sudo systemctl restart redis-server.service
```

### Laisser Redis sans supervision {#leave-redis-unsupervised}

Si votre système utilise SysV init, exécutez ces commandes :

```shell
# Create the directory which contains the socket
sudo mkdir -p /var/run/redis
sudo chown redis:redis /var/run/redis
sudo chmod 755 /var/run/redis

# Persist the directory which contains the socket, if applicable
if [ -d /etc/tmpfiles.d ]; then
  echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf
fi

# Activate the changes to redis.conf
sudo service redis-server restart
```

## 9\. GitLab {#9-gitlab}

```shell
# We'll install GitLab into the home directory of the user "git"
cd /home/git
```

### Cloner la source {#clone-the-source}

Cloner la Community Edition :

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b <X-Y-stable> gitlab
```

Cloner l'Enterprise Edition :

```shell
# Clone GitLab repository
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab.git -b <X-Y-stable-ee> gitlab
```

Assurez-vous de remplacer `<X-Y-stable>` par la branche stable qui correspond à la version que vous souhaitez installer. Par exemple, si vous souhaitez installer la version 11.8, vous utiliseriez le nom de branche `11-8-stable`.

> [!warning]
> Vous pouvez remplacer `<X-Y-stable>` par `master` si vous souhaitez la version « bleeding edge », mais n'installez jamais `master` sur un serveur de production !

### Configurer {#configure-it}

```shell
# Go to GitLab installation folder
cd /home/git/gitlab

# Copy the example GitLab config
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

# Update GitLab config file, follow the directions at top of the file
sudo -u git -H editor config/gitlab.yml

# Copy the example secrets file
sudo -u git -H cp config/secrets.yml.example config/secrets.yml
sudo -u git -H chmod 0600 config/secrets.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX,go-w log/
sudo chmod -R u+rwX tmp/

# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
sudo chmod -R u+rwX tmp/pids/
sudo chmod -R u+rwX tmp/sockets/

# Create the public/uploads/ directory
sudo -u git -H mkdir -p public/uploads/

# Make sure only the GitLab user has access to the public/uploads/ directory
# now that files in public/uploads are served by gitlab-workhorse
sudo chmod 0700 public/uploads

# Change the permissions of the directory where CI job logs are stored
sudo chmod -R u+rwX builds/

# Change the permissions of the directory where CI artifacts are stored
sudo chmod -R u+rwX shared/artifacts/

# Change the permissions of the directory where GitLab Pages are stored
sudo chmod -R ug+rwX shared/pages/

# Copy the example Puma config
sudo -u git -H cp config/puma.rb.example config/puma.rb

# Refer to https://github.com/puma/puma#configuration for more information.
# You should scale Puma workers and threads based on the number of CPU
# cores you have available. You can get that number via the `nproc` command.
sudo -u git -H editor config/puma.rb

# Configure Redis connection settings
sudo -u git -H cp config/resque.yml.example config/resque.yml
sudo -u git -H cp config/cable.yml.example config/cable.yml

# Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
sudo -u git -H editor config/resque.yml config/cable.yml
```

Assurez-vous de modifier à la fois `gitlab.yml` et `puma.rb` pour correspondre à votre configuration.

Si vous souhaitez utiliser HTTPS, consultez [Utilisation de HTTPS](#using-https) pour les étapes supplémentaires.

### Configurer les paramètres de base de données GitLab {#configure-gitlab-db-settings}

> [!note]
> Depuis [GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/387898), `database.yml` avec uniquement une section : `main:` est obsolète. Dans GitLab 17.0 et versions ultérieures, vous devez avoir les deux sections `main:` et `ci:` dans votre `database.yml`.

```shell
sudo -u git cp config/database.yml.postgresql config/database.yml

# Remove host, username, and password lines from config/database.yml.
# Once modified, the `production` settings will be as follows:
#
#   production:
#     main:
#       adapter: postgresql
#       encoding: unicode
#       database: gitlabhq_production
#     ci:
#       adapter: postgresql
#       encoding: unicode
#       database: gitlabhq_production
#       database_tasks: false
#
sudo -u git -H editor config/database.yml

# Remote PostgreSQL only:
# Update username/password in config/database.yml.
# You only need to adapt the production settings (first part).
# If you followed the database guide then please do as follows:
# Change 'secure password' with the value you have given to $password
# You can keep the double quotes around the password
sudo -u git -H editor config/database.yml

# Uncomment the `ci:` sections in config/database.yml.
# Ensure the `database` value in `ci:` matches the database value in `main:`.

# Make config/database.yml readable to git only
sudo -u git -H chmod o-rwx config/database.yml
```

Votre `database.yml` doit comporter deux sections : `main:` et `ci:`. La connexion `ci` : [doit être vers la même base de données](../../administration/postgresql/_index.md).

### Installer les Gems {#install-gems}

> [!note]
> Depuis Bundler 1.5.2, vous pouvez invoquer `bundle install -jN` (où `N` est le nombre de cœurs de votre processeur) et profiter d'une installation parallèle des gems avec une différence mesurable dans le temps d'achèvement (~60 % plus rapide). Vérifiez le nombre de vos cœurs avec `nproc`. Pour plus d'informations, consultez ce [billet](https://thoughtbot.com/blog/parallel-gem-installing-using-bundler).

Assurez-vous d'avoir `bundle` (exécutez `bundle -v`) :

- `>= 1.5.2`, car certains [problèmes](https://devcenter.heroku.com/changelog-items/411) ont été [corrigés](https://github.com/rubygems/bundler/pull/2817) dans la version 1.5.2.
- `< 2.x`.

Installez les gems (si vous souhaitez utiliser Kerberos pour l'authentification des utilisateurs, omettez `kerberos` dans l'option `--without` dans les commandes suivantes) :

```shell
sudo -u git -H bundle config set --local deployment 'true'
sudo -u git -H bundle config set --local without 'development test kerberos'
sudo -u git -H bundle config path /home/git/gitlab/vendor/bundle
sudo -u git -H bundle install
```

### Installer GitLab Shell {#install-gitlab-shell}

GitLab Shell est un logiciel d'accès SSH et de gestion des dépôts développé spécialement pour GitLab.

```shell
# Run the installation task for gitlab-shell:
sudo -u git -H bundle exec rake gitlab:shell:install RAILS_ENV=production

# By default, the gitlab-shell config is generated from your main GitLab config.
# You can review (and modify) the gitlab-shell config as follows:
sudo -u git -H editor /home/git/gitlab-shell/config.yml
```

Si vous souhaitez utiliser HTTPS, consultez [Utilisation de HTTPS](#using-https) pour les étapes supplémentaires.

Assurez-vous que le nom d'hôte peut être résolu sur la machine elle-même par un enregistrement DNS approprié ou une ligne supplémentaire dans `/etc/hosts` (« 127.0.0.1 hostname »). Cela peut être nécessaire, par exemple, si vous configurez GitLab derrière un proxy inverse. Si le nom d'hôte ne peut pas être résolu, la vérification finale de l'installation échoue avec `Check GitLab API access: FAILED. code: 401` et les push de commits sont rejetés avec `[remote rejected] master -> master (hook declined)`.

### Installer GitLab Workhorse {#install-gitlab-workhorse}

GitLab-Workhorse utilise [GNU Make](https://www.gnu.org/software/make/). La ligne de commande suivante installe GitLab-Workhorse dans `/home/git/gitlab-workhorse`, qui est l'emplacement recommandé.

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

Vous pouvez spécifier un dépôt Git différent en le fournissant comme paramètre supplémentaire :

```shell
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse,https://example.com/gitlab-workhorse.git]" RAILS_ENV=production
```

### Installer GitLab-Elasticsearch-indexer sur Enterprise Edition {#install-gitlab-elasticsearch-indexer-on-enterprise-edition}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab-Elasticsearch-Indexer utilise [GNU Make](https://www.gnu.org/software/make/). La ligne de commande suivante installe GitLab-Elasticsearch-Indexer dans `/home/git/gitlab-elasticsearch-indexer`, qui est l'emplacement recommandé.

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer]" RAILS_ENV=production
```

Vous pouvez spécifier un dépôt Git différent en le fournissant comme paramètre supplémentaire :

```shell
sudo -u git -H bundle exec rake "gitlab:indexer:install[/home/git/gitlab-elasticsearch-indexer,https://example.com/gitlab-elasticsearch-indexer.git]" RAILS_ENV=production
```

Le code source est d'abord récupéré vers le chemin spécifié par le premier paramètre. Ensuite, un binaire est compilé dans son répertoire `bin`. Vous devez ensuite mettre à jour le paramètre `production -> elasticsearch -> indexer_path` de `gitlab.yml` pour pointer vers ce binaire.

### Installer GitLab Pages {#install-gitlab-pages}

GitLab Pages utilise [GNU Make](https://www.gnu.org/software/make/). Cette étape est facultative et n'est nécessaire que si vous souhaitez héberger des sites statiques depuis GitLab. Les commandes suivantes installent GitLab Pages dans `/home/git/gitlab-pages`. Pour les étapes de configuration supplémentaires, consultez le [guide d'administration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/pages/source.md) correspondant à votre version de GitLab, car le démon GitLab Pages peut être exécuté de plusieurs façons différentes.

```shell
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
cd gitlab-pages
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Installer Gitaly {#install-gitaly}

```shell
# Create and restrict access to the git repository data directory
sudo install -d -o git -m 0700 /home/git/repositories

# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

Vous pouvez spécifier un dépôt Git différent en le fournissant comme paramètre supplémentaire :

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories,https://example.com/gitaly.git]" RAILS_ENV=production
```

Ensuite, assurez-vous que Gitaly est configuré :

```shell
# Restrict Gitaly socket access
sudo chmod 0700 /home/git/gitlab/tmp/sockets/private
sudo chown git /home/git/gitlab/tmp/sockets/private

# If you are using non-default settings, you need to update config.toml
cd /home/git/gitaly
sudo -u git -H editor config.toml
```

Pour plus d'informations sur la configuration de Gitaly, consultez [la documentation Gitaly](../../administration/gitaly/_index.md).

### Installer le service {#install-the-service}

GitLab a toujours pris en charge les scripts init SysV, qui sont largement pris en charge et portables, mais systemd est désormais la norme pour la supervision des services et est utilisé par toutes les principales distributions Linux. Vous devriez utiliser les services natifs systemd si vous le pouvez pour bénéficier des redémarrages automatiques, d'un meilleur sandboxing et d'un meilleur contrôle des ressources.

#### Installer les unités systemd {#install-systemd-units}

Suivez ces étapes si vous utilisez systemd comme init. Sinon, suivez les [étapes du script init SysV](#install-sysv-init-script).

Copiez les services et exécutez `systemctl daemon-reload` pour que systemd les prenne en compte :

```shell
cd /home/git/gitlab
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
sudo systemctl daemon-reload
```

Les unités fournies par GitLab font très peu d'hypothèses sur l'endroit où vous exécutez Redis et PostgreSQL.

Si vous avez installé GitLab dans un autre répertoire ou en tant qu'utilisateur autre que celui par défaut, vous devez également modifier ces valeurs dans les unités.

Par exemple, si vous exécutez Redis et PostgreSQL sur la même machine que GitLab, vous devriez :

- Modifiez le service Puma :

  ```shell
  sudo systemctl edit gitlab-puma.service
  ```

  Dans l'éditeur qui s'ouvre, ajoutez ce qui suit et enregistrez le fichier :

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

- Modifiez le service Sidekiq :

  ```shell
  sudo systemctl edit gitlab-sidekiq.service
  ```

  Ajoutez ce qui suit et enregistrez le fichier :

  ```plaintext
  [Unit]
  Wants=redis-server.service postgresql.service
  After=redis-server.service postgresql.service
  ```

`systemctl edit` installe des fichiers de configuration drop-in dans `/etc/systemd/system/<name of the unit>.d/override.conf`, de sorte que votre configuration locale n'est pas écrasée lors de la mise à jour ultérieure des fichiers d'unité. Pour diviser vos fichiers de configuration drop-in, vous pouvez ajouter les extraits précédents à des fichiers `.conf` sous `/etc/systemd/system/<name of the unit>.d/`.

Si vous avez apporté manuellement des modifications aux fichiers d'unité ou ajouté des fichiers de configuration drop-in (sans utiliser `systemctl edit`), exécutez la commande suivante pour qu'elles prennent effet :

```shell
sudo systemctl daemon-reload
```

Faites démarrer GitLab au démarrage :

```shell
sudo systemctl enable gitlab.target
```

#### Installer le script init SysV {#install-sysv-init-script}

Suivez ces étapes si vous utilisez le script init SysV. Si vous utilisez systemd, suivez les [étapes des unités systemd](#install-systemd-units).

Téléchargez le script init (est `/etc/init.d/gitlab`) :

```shell
cd /home/git/gitlab
sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

Et si vous installez avec un dossier ou un utilisateur non par défaut, copiez et modifiez le fichier de paramètres par défaut :

```shell
sudo cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
```

Si vous avez installé GitLab dans un autre répertoire ou en tant qu'utilisateur autre que celui par défaut, vous devez modifier ces paramètres dans `/etc/default/gitlab`. Ne modifiez pas `/etc/init.d/gitlab` car il est modifié lors des mises à niveau.

Faites démarrer GitLab au démarrage :

```shell
sudo update-rc.d gitlab defaults 21
# or if running this on a machine running systemd
sudo systemctl daemon-reload
sudo systemctl enable gitlab.service
```

### Configurer Logrotate {#set-up-logrotate}

```shell
sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
```

### Démarrer Gitaly {#start-gitaly}

Gitaly doit être en cours d'exécution pour la section suivante.

- Pour démarrer Gitaly avec systemd :

  ```shell
  sudo systemctl start gitlab-gitaly.service
  ```

- Pour démarrer Gitaly manuellement avec SysV :

  ```shell
  gitlab_path=/home/git/gitlab
  gitaly_path=/home/git/gitaly

  sudo -u git -H sh -c "$gitlab_path/bin/daemon_with_pidfile $gitlab_path/tmp/pids/gitaly.pid \
    $gitaly_path/_build/bin/gitaly $gitaly_path/config.toml >> $gitlab_path/log/gitaly.log 2>&1 &"
  ```

### Initialiser la base de données et activer les fonctionnalités avancées {#initialize-database-and-activate-advanced-features}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# Type 'yes' to create the database tables.

# or you can skip the question by adding force=yes
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production force=yes

# When done, you see 'Administrator account created:'
```

Vous pouvez définir le mot de passe et l'e-mail Administrateur/root en les fournissant dans des variables d'environnement, `GITLAB_ROOT_PASSWORD` et `GITLAB_ROOT_EMAIL`, comme indiqué dans la commande suivante. Si vous ne définissez pas le mot de passe (et qu'il est défini sur celui par défaut), attendez d'exposer GitLab à l'internet public jusqu'à ce que l'installation soit terminée et que vous vous soyez connecté au serveur pour la première fois. Lors de la première connexion, vous êtes forcé de changer le mot de passe par défaut. Un abonnement Enterprise Edition peut également être activé à ce moment en fournissant le code d'activation dans la variable d'environnement `GITLAB_ACTIVATION_CODE`.

```shell
sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=yourpassword GITLAB_ROOT_EMAIL=youremail GITLAB_ACTIVATION_CODE=yourcode
```

### Sécuriser `secrets.yml` {#secure-secretsyml}

Le fichier `secrets.yml` stocke les clés de chiffrement pour les sessions et les variables sécurisées. Sauvegardez `secrets.yml` dans un endroit sûr, mais ne le stockez pas au même endroit que vos sauvegardes de base de données. Sinon, vos secrets sont exposés si l'une de vos sauvegardes est compromise.

### Vérifier le statut de l'application {#check-application-status}

Vérifiez si GitLab et son environnement sont correctement configurés :

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

### Compiler les ressources {#compile-assets}

```shell
sudo -u git -H yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
```

Si `rake` échoue avec l'erreur `JavaScript heap out of memory`, essayez de l'exécuter avec `NODE_OPTIONS` défini comme suit.

```shell
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### Démarrer votre instance GitLab {#start-your-gitlab-instance}

```shell
# For systems running systemd
sudo systemctl start gitlab.target

# For systems running SysV init
sudo service gitlab start
```

## 10\. NGINX {#10-nginx}

NGINX est le serveur web officiellement pris en charge pour GitLab. Si vous ne pouvez pas ou ne souhaitez pas utiliser NGINX comme serveur web, consultez les [recettes GitLab](https://gitlab.com/gitlab-org/gitlab-recipes/).

### Installation {#installation}

```shell
sudo apt-get install -y nginx
```

### Configuration du site {#site-configuration}

Copiez l'exemple de configuration de site :

```shell
sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
```

Assurez-vous de modifier le fichier de configuration pour qu'il corresponde à votre configuration. Assurez-vous également que vos chemins correspondent à GitLab, surtout si vous installez pour un utilisateur autre que l'utilisateur `git` :

```shell
# Change YOUR_SERVER_FQDN to the fully-qualified
# domain name of your host serving GitLab.
#
# Remember to match your paths to GitLab, especially
# if installing for a user other than 'git'.
#
# If using Ubuntu default nginx install:
# either remove the default_server from the listen line
# or else sudo rm -f /etc/nginx/sites-enabled/default
sudo editor /etc/nginx/sites-available/gitlab
```

Si vous avez l'intention d'activer GitLab Pages, il existe une configuration NGINX séparée que vous devez utiliser. Consultez toutes les informations sur la configuration nécessaire dans le [guide d'administration de GitLab Pages](../../administration/pages/_index.md).

Si vous souhaitez utiliser HTTPS, remplacez la configuration NGINX `gitlab` par `gitlab-ssl`. Consultez [Utilisation de HTTPS](#using-https) pour les détails de configuration HTTPS.

Pour que NGINX puisse lire le socket GitLab-Workhorse, vous devez vous assurer que l'utilisateur `www-data` peut lire le socket, qui appartient à l'utilisateur GitLab. Cela est réalisé si le socket est accessible en lecture universelle, par exemple s'il dispose des permissions `0755`, ce qui est la valeur par défaut. `www-data` doit également être en mesure de lister les répertoires parents.

### Tester la configuration {#test-configuration}

Validez votre fichier de configuration NGINX `gitlab` ou `gitlab-ssl` avec la commande suivante :

```shell
sudo nginx -t
```

Vous devriez recevoir les messages `syntax is okay` et `test is successful`. Si vous recevez des messages d'erreur, vérifiez que votre fichier de configuration NGINX `gitlab` ou `gitlab-ssl` ne contient pas de fautes de frappe, comme indiqué dans le message d'erreur fourni.

Vérifiez que la version installée est supérieure à 1.12.1 :

```shell
nginx -v
```

Si elle est inférieure, vous pouvez recevoir l'erreur suivante :

```plaintext
nginx: [emerg] unknown "start$temp=[filtered]$rest" variable
nginx: configuration file /etc/nginx/nginx.conf test failed
```

### Redémarrer {#restart}

```shell
# For systems running systemd
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service nginx restart
```

## Post-installation {#post-install}

### Vérification du statut de l'application {#double-check-application-status}

Pour vous assurer de ne rien avoir manqué, effectuez une vérification plus approfondie avec :

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

Si tous les éléments sont en vert, félicitations pour avoir installé GitLab avec succès !

> [!note]
> Fournissez la variable d'environnement `SANITIZE=true` à `gitlab:check` pour omettre les noms de projets dans la sortie de la commande de vérification.

### Connexion initiale {#initial-login}

Visitez YOUR_SERVER dans votre navigateur web pour votre première connexion à GitLab.

Si vous n'avez pas [fourni de mot de passe root lors de la configuration](#initialize-database-and-activate-advanced-features), vous êtes redirigé vers un écran de réinitialisation de mot de passe pour fournir le mot de passe du compte administrateur initial. Saisissez le mot de passe souhaité et vous serez redirigé vers l'écran de connexion.

Le nom d'utilisateur du compte par défaut est **root**. Fournissez le mot de passe que vous avez créé précédemment et connectez-vous. Après la connexion, vous pouvez modifier le nom d'utilisateur si vous le souhaitez.

**Profitez !**

Pour démarrer et arrêter GitLab en utilisant :

- Unités systemd : utilisez `sudo systemctl start gitlab.target` ou `sudo systemctl stop gitlab.target`.
- Le script init SysV : utilisez `sudo service gitlab start` ou `sudo service gitlab stop`.

### Prochaines étapes recommandées {#recommended-next-steps}

Après avoir terminé votre installation, envisagez de suivre les [prochaines étapes recommandées](../next_steps.md), notamment les options d'authentification et les restrictions de compte pour les nouveaux utilisateurs.

## Conseils de configuration avancée {#advanced-setup-tips}

### Prise en charge des URL relatives {#relative-url-support}

Consultez la [documentation sur les URL relatives](../relative_url.md) pour plus d'informations sur la façon de configurer GitLab avec une URL relative.

### Utilisation de HTTPS {#using-https}

Pour utiliser GitLab avec HTTPS :

1. Dans `gitlab.yml` :
   1. Définissez l'option `port` dans la section 1 sur `443`.
   1. Définissez l'option `https` dans la section 1 sur `true`.
1. Dans le `config.yml` de GitLab Shell :
   1. Définissez l'option `gitlab_url` sur le point de terminaison HTTPS de GitLab (par exemple, `https://git.example.com`).
   1. Définissez les certificats en utilisant l'option `ca_file` ou `ca_path`.
1. Utilisez l'exemple de configuration NGINX `gitlab-ssl` à la place de la configuration `gitlab`.
   1. Mettez à jour `YOUR_SERVER_FQDN`.
   1. Mettez à jour `ssl_certificate` et `ssl_certificate_key`.
   1. Examinez le fichier de configuration et envisagez d'appliquer d'autres fonctionnalités améliorant la sécurité et les performances.

L'utilisation d'un certificat auto-signé est déconseillée. Si vous devez en utiliser un, suivez les instructions standard et générez un certificat SSL auto-signé :

   ```shell
   mkdir -p /etc/nginx/ssl/
   cd /etc/nginx/ssl/
   sudo openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key
   sudo chmod o-r gitlab.key
   ```

### Activer la réponse par e-mail {#enable-reply-by-email}

Consultez la [documentation « Réponse par e-mail »](../../administration/reply_by_email.md) pour plus d'informations sur la façon de configurer cette fonctionnalité.

### Authentification LDAP {#ldap-authentication}

Vous pouvez configurer l'authentification LDAP dans `config/gitlab.yml`. Redémarrez GitLab après avoir modifié ce fichier.

### Utilisation de fournisseurs OmniAuth personnalisés {#using-custom-omniauth-providers}

Consultez la [documentation d'intégration OmniAuth](../../integration/omniauth.md).

### Compiler vos projets {#build-your-projects}

GitLab peut compiler vos projets. Pour activer cette fonctionnalité, vous avez besoin de runners pour effectuer cette tâche. Consultez la [section GitLab Runner](https://docs.gitlab.com/runner/) pour l'installer.

### Ajouter vos proxies de confiance {#adding-your-trusted-proxies}

Si vous utilisez un proxy inverse sur une machine séparée, vous pouvez souhaiter ajouter le proxy à la liste des proxies de confiance. Sinon, les utilisateurs semblent connectés depuis l'adresse IP du proxy.

Vous pouvez ajouter des proxies de confiance dans `config/gitlab.yml` en personnalisant l'option `trusted_proxies` dans la section 1. Enregistrez le fichier et [reconfigurez GitLab](../../administration/restart_gitlab.md) pour que les modifications prennent effet.

Si vous rencontrez des problèmes avec des caractères mal encodés dans les URL, consultez [Erreur : `404 Not Found` lors de l'utilisation d'un proxy inverse](../../api/rest/troubleshooting.md#error-404-not-found-when-using-a-reverse-proxy).

### Connexion Redis personnalisée {#custom-redis-connection}

Si vous souhaitez vous connecter à un serveur Redis sur un port non standard ou un hôte différent, vous pouvez configurer sa chaîne de connexion via le fichier `config/resque.yml`.

```yaml
# example
production:
  url: redis://redis.example.tld:6379
```

Si vous souhaitez connecter le serveur Redis via socket, utilisez le schéma d'URL `unix:` et le chemin vers le fichier socket Redis dans le fichier `config/resque.yml`.

```yaml
# example
production:
  url: unix:/path/to/redis/socket
```

Vous pouvez également utiliser des variables d'environnement dans le fichier `config/resque.yml` :

```yaml
# example
production:
  url: <%= ENV.fetch('GITLAB_REDIS_URL') %>
```

### Connexion SSH personnalisée {#custom-ssh-connection}

Si vous exécutez SSH sur un port non standard, vous devez modifier la configuration SSH de l'utilisateur GitLab.

```plaintext
# Add to /home/git/.ssh/config
host localhost          # Give your setup a name (here: override localhost)
    user git            # Your remote git user
    port 2222           # Your port number
    hostname 127.0.0.1; # Your server name or IP
```

Vous devez également modifier les options correspondantes (par exemple, `ssh_user`, `ssh_host`, `admin_uri`) dans le fichier `config/gitlab.yml`.

### Styles de balisage supplémentaires {#additional-markup-styles}

Outre le style Markdown toujours pris en charge, il existe d'autres fichiers de texte enrichi que GitLab peut afficher. Mais vous devrez peut-être installer une dépendance pour ce faire. Consultez le [README du gem `github-markup`](https://github.com/gitlabhq/markup#markups) pour plus d'informations.

### Configuration du serveur Prometheus {#prometheus-server-setup}

Vous pouvez configurer le serveur Prometheus dans `config/gitlab.yml` :

```yaml
# example
prometheus:
  enabled: true
  server_address: '10.1.2.3:9090'
```

## Dépannage {#troubleshooting}

### Message : `You appear to have cloned an empty repository.` {#message-you-appear-to-have-cloned-an-empty-repository}

Si vous voyez ce message lors d'une tentative de clonage d'un dépôt hébergé par GitLab, cela est probablement dû à une configuration NGINX ou Apache obsolète, ou à une instance GitLab Workhorse manquante ou mal configurée. Vérifiez que vous avez [installé Go](#4-go), [installé GitLab Workhorse](#install-gitlab-workhorse) et correctement [configuré NGINX](#site-configuration).

### Erreur `google-protobuf` : `LoadError: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.14' not found` {#google-protobuf-error-loaderror-libx86_64-linux-gnulibcso6-version-glibc_214-not-found}

Cela peut se produire sur certaines plateformes pour certaines versions du gem `google-protobuf`. La solution de contournement consiste à installer une version source uniquement de ce gem.

Tout d'abord, vous devez trouver la version exacte de `google-protobuf` requise par votre installation GitLab :

```shell
cd /home/git/gitlab

# Only one of the following two commands will print something. It
# will look like: * google-protobuf (3.2.0)
bundle list | grep google-protobuf
bundle check | grep google-protobuf
```

Dans la commande suivante, `3.2.0` est utilisé comme exemple. Remplacez-le par le numéro de version que vous avez trouvé précédemment :

```shell
cd /home/git/gitlab
sudo -u git -H gem install google-protobuf --version 3.2.0 --platform ruby
```

Enfin, vous pouvez tester si `google-protobuf` se charge correctement. La commande suivante devrait afficher `OK`.

```shell
sudo -u git -H bundle exec ruby -rgoogle/protobuf -e 'puts :OK'
```

Si la commande `gem install` échoue, vous devrez peut-être installer les outils de développement de votre système d'exploitation.

Sur Debian/Ubuntu :

```shell
sudo apt-get install build-essential libgmp-dev
```

Sur RedHat/CentOS :

```shell
sudo yum groupinstall 'Development Tools'
```

### Erreur lors de la compilation des ressources GitLab {#error-compiling-gitlab-assets}

Lors de la compilation des ressources, vous pouvez recevoir le message d'erreur suivant :

```plaintext
Killed
error Command failed with exit code 137.
```

Cela peut se produire lorsque Yarn arrête un conteneur qui manque de mémoire. Pour résoudre ce problème :

1. Augmentez la mémoire de votre système à au moins 8 Go.
1. Exécutez cette commande pour nettoyer les ressources :

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:clean RAILS_ENV=production NODE_ENV=production
   ```

1. Exécutez à nouveau la commande `yarn` pour résoudre les conflits éventuels :

   ```shell
   sudo -u git -H yarn install --production --pure-lockfile
   ```

1. Recompilez les ressources :

   ```shell
   sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
   ```
