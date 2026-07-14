---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Gitaly
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Configurez Gitaly de l'une des deux façons suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ou modifiez les paramètres Gitaly. Reportez-vous au [fichier de configuration Gitaly exemple](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example). Les paramètres du fichier exemple doivent être convertis en Ruby.
1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Configurez le [chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/).
1. [Mettez à niveau votre release Helm](https://docs.gitlab.com/charts/installation/deployment/).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitaly/config.toml` et ajoutez ou modifiez les paramètres Gitaly. Reportez-vous au [fichier de configuration Gitaly exemple](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example).
1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

Les options de configuration suivantes sont également disponibles :

- Activation de la [prise en charge TLS](tls_support.md).
- Limitation de la [simultanéité RPC](concurrency_limiting.md#limit-rpc-concurrency).
- Limitation de la [simultanéité pack-objects](concurrency_limiting.md#limit-pack-objects-concurrency).

## À propos du token Gitaly {#about-the-gitaly-token}

Le token mentionné dans la documentation Gitaly est simplement un mot de passe arbitraire choisi par l'administrateur. Il n'est pas lié aux tokens créés pour l'API GitLab ou à d'autres tokens d'API web similaires.

## Exécuter Gitaly sur son propre serveur {#run-gitaly-on-its-own-server}

Par défaut, Gitaly s'exécute sur le même serveur que les clients Gitaly et est configuré comme décrit précédemment. Les installations sur un seul serveur sont mieux servies par cette configuration par défaut utilisée par :

- [Installations avec le package Linux](https://docs.gitlab.com/omnibus/).
- [Installations compilées manuellement](../../install/self_compiled/_index.md).

Cependant, Gitaly peut être déployé sur son propre serveur, ce qui peut être bénéfique pour les installations GitLab s'étendant sur plusieurs machines.

> [!note]
> Lorsqu'ils sont configurés pour s'exécuter sur leurs propres serveurs, les serveurs Gitaly doivent être [mis à niveau](../../update/package/_index.md) avant les clients Gitaly dans votre cluster.

La procédure de configuration de Gitaly sur son propre serveur est la suivante :

1. [Installer Gitaly](#install-gitaly).
1. [Configurer l'authentification](#configure-authentication).
1. [Configurer les serveurs Gitaly](#configure-gitaly-servers).
1. [Configurer les clients Gitaly](#configure-gitaly-clients).
1. [Désactiver Gitaly là où ce n'est pas requis](#disable-gitaly-where-not-required-optional) (facultatif).

> [!note]
> Les [exigences en matière de disque](_index.md#disk-requirements) s'appliquent aux nœuds Gitaly.

### Architecture réseau {#network-architecture}

La liste suivante représente l'architecture réseau de Gitaly :

- GitLab Rails répartit les dépôts dans des [stockages de dépôts](../repository_storage_paths.md).
- `/config/gitlab.yml` contient un mappage des noms de stockage vers des paires `(Gitaly address, Gitaly token)`.
- Le mappage `storage name` -> `(Gitaly address, Gitaly token)` dans `/config/gitlab.yml` est la source unique de vérité pour la topologie réseau Gitaly.
- Une `(Gitaly address, Gitaly token)` correspond à un serveur Gitaly.
- Un serveur Gitaly héberge un ou plusieurs stockages.
- Un client Gitaly peut utiliser un ou plusieurs serveurs Gitaly.
- Les adresses Gitaly doivent être spécifiées de telle sorte qu'elles se résolvent correctement pour tous les clients Gitaly.
- Les clients Gitaly sont :
  - Puma.
  - Sidekiq.
  - GitLab Workhorse.
  - GitLab Shell.
  - L'indexeur Elasticsearch.
  - Gitaly lui-même.
- Un serveur Gitaly doit être capable d'effectuer des appels RPC vers lui-même en utilisant sa propre paire `(Gitaly address, Gitaly token)` telle que spécifiée dans `/config/gitlab.yml`.
- L'authentification est effectuée via un token statique partagé entre Gitaly et les nœuds GitLab Rails.

Le diagramme suivant illustre la communication entre les serveurs Gitaly et GitLab Rails en indiquant les ports par défaut pour la communication HTTP et HTTPS.

![Deux serveurs Gitaly et un GitLab Rails échangeant des informations.](img/gitaly_network_v13_9.png)

> [!warning]
> Les serveurs Gitaly ne doivent pas être exposés à l'internet public car le trafic réseau Gitaly n'est pas chiffré par défaut. L'utilisation d'un pare-feu est fortement recommandée pour restreindre l'accès au serveur Gitaly. Une autre option consiste à [utiliser TLS](tls_support.md).

Dans les sections suivantes, nous décrivons comment configurer deux serveurs Gitaly avec le token secret `abc123secret` :

- `gitaly1.internal`.
- `gitaly2.internal`.

Nous supposons que votre installation GitLab dispose de trois stockages de dépôts :

- `default`.
- `storage1`.
- `storage2`.

Vous pouvez utiliser un seul serveur avec un seul stockage de dépôt si vous le souhaitez.

### Installer Gitaly {#install-gitaly}

Installez Gitaly sur chaque serveur Gitaly en utilisant l'une des méthodes suivantes :

- Une installation avec le package Linux. [Téléchargez et installez](https://about.gitlab.com/install/) le package Linux souhaité, mais ne fournissez pas la valeur `EXTERNAL_URL=`.
- Une installation compilée manuellement. Suivez les étapes décrites dans [Installer Gitaly](../../install/self_compiled/_index.md#install-gitaly).

### Configurer les serveurs Gitaly {#configure-gitaly-servers}

Pour configurer les serveurs Gitaly, vous devez :

- Configurer l'authentification.
- Configurer les chemins de stockage.
- Activer l'écouteur réseau.

L'utilisateur `git` doit pouvoir lire, écrire et définir des permissions sur le chemin de stockage configuré.

Pour éviter les temps d'arrêt lors de la rotation du token Gitaly, vous pouvez désactiver temporairement l'authentification en utilisant le paramètre `gitaly['auth_transitioning']`. Pour plus d'informations, consultez [Activer le mode de transition d'authentification](#enable-auth-transitioning-mode).

#### Configurer l'authentification {#configure-authentication}

{{< history >}}

- Prise en charge de `token_file` [introduite](https://gitlab.com/gitlab-org/gitaly/-/issues/7083) dans GitLab 18.11.

{{< /history >}}

Gitaly et GitLab utilisent deux secrets partagés pour l'authentification :

- _Token Gitaly_ : utilisé pour authentifier les requêtes gRPC vers Gitaly. Vous pouvez spécifier le token Gitaly directement dans la configuration GitLab ou dans un fichier de token. L'utilisation d'un fichier de token est plus sécurisée et mieux adaptée aux environnements conteneurisés, car elle évite d'intégrer les secrets dans la configuration au démarrage. Le fichier de token doit :
  - Contenir uniquement la chaîne du token. Les espaces blancs sont supprimés automatiquement.
  - Avoir des permissions de fichier `0600` ou `0400`.
- _Token GitLab Shell_ : utilisé pour les rappels d'authentification de GitLab Shell vers l'API interne de GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Pour configurer le _token Gitaly_, modifiez `/etc/gitlab/gitlab.rb` :

   - Lors de l'utilisation d'un fichier de token :

     ```ruby
     gitaly['configuration'] = {
        # ...
        auth: {
          # ...
          token_file: '/etc/gitlab/gitaly_token',
        },
     }
     ```

   - Lors de la spécification directe du token :

     ```ruby
     gitaly['configuration'] = {
        # ...
        auth: {
          # ...
          token: 'abc123secret',
        },
     }
     ```

   `token` et `token_file` sont mutuellement exclusifs.

1. Configurez le _token GitLab Shell_ de l'une des deux façons suivantes :

   - Méthode 1 (recommandée) : copiez `/etc/gitlab/gitlab-secrets.json` du client Gitaly vers le même chemin sur les serveurs Gitaly et tout autre client Gitaly.

   - Méthode 2 :

     1. Sur tous les nœuds exécutant GitLab Rails, modifiez `/etc/gitlab/gitlab.rb`.
     1. Remplacez `GITLAB_SHELL_SECRET_TOKEN` par le vrai secret :

        - GitLab 17.5 et versions ultérieures :

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4 et versions antérieures :

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. Sur tous les nœuds exécutant Gitaly, modifiez `/etc/gitlab/gitlab.rb`.
     1. Remplacez `GITLAB_SHELL_SECRET_TOKEN` par le vrai secret :

        - GitLab 17.5 et versions ultérieures :

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4 et versions antérieures :

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. Après ces modifications, reconfigurez GitLab :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Copiez `/home/git/gitlab/.gitlab_shell_secret` du client Gitaly vers le même chemin sur les serveurs Gitaly (et tout autre client Gitaly).
1. Sur les clients Gitaly, modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   gitlab:
     gitaly:
       token: 'abc123secret'
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Sur les serveurs Gitaly, modifiez `/home/git/gitaly/config.toml` :

   - Lors de l'utilisation d'un fichier de token :

     ```toml
     [auth]
     token_file = '/etc/gitaly/token'
     ```

   - Lors de la spécification directe du token :

     ```toml
     [auth]
     token = 'abc123secret'
     ```

   `token` et `token_file` sont mutuellement exclusifs.

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

#### Configurer le serveur Gitaly {#configure-gitaly-server}

<!--
Updates to example must be made at:

- <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation>
- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/praefect/configure.md#praefect>
- All reference architecture pages
-->

Configurez le serveur Gitaly.

Gitaly dispose de certains RPCs dans lesquels il effectue un appel réseau vers lui-même en utilisant l'adresse fournie par le client (comme Rails ou Sidekiq).

Si Gitaly ne peut pas se joindre lui-même de cette façon en raison de votre configuration réseau (par exemple, Gitaly est derrière un équilibreur de charge qui ne prend pas en charge les connexions en épingle à cheveux) :

1. Modifiez le fichier `/etc/hosts` du serveur Gitaly.
1. Ajoutez une entrée pour rediriger l'adresse Gitaly utilisée par les clients vers l'adresse IP propre du serveur Gitaly. Par exemple, `127.0.0.1 gitaly.example.com` ou `<local-ip> gitaly.example.com`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_kas['enable'] = false

   # If you run a separate monitoring node you can disable these services
   prometheus['enable'] = false
   alertmanager['enable'] = false

   # If you don't run a separate monitoring node you can
   # enable Prometheus access & disable these extra services.
   # This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
   # prometheus['listen_address'] = '0.0.0.0:9090'
   # prometheus['monitor_kubernetes'] = false

   # If you don't want to run monitoring services uncomment the following (not recommended)
   # node_exporter['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from Gitaly client to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces. You must use
      # firewalls to restrict access to this address/port.
      # Comment out following line if you only want to support TLS connections
      listen_addr: '0.0.0.0:8075',
      auth: {
        # ...
        #
        # Authentication token to ensure only authorized servers can communicate with
        # Gitaly server
        token: 'AUTH_TOKEN',
      },
   }
   ```

1. Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` pour chaque serveur Gitaly respectif :

   <!-- Updates to following example must also be made at <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation> -->

   Sur `gitaly1.internal` :

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'default',
            path: '/var/opt/gitlab/git-data/repositories',
         },
         {
            name: 'storage1',
            path: '/mnt/gitlab/git-data/repositories',
         },
      ],
   }
   ```

   Sur `gitaly2.internal` :

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'storage2',
            path: '/srv/gitlab/git-data/repositories',
         },
      ],
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Confirmez que Gitaly peut effectuer des rappels vers l'API interne de GitLab :

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitaly/config.toml` :

   ```toml
   listen_addr = '0.0.0.0:8075'

   runtime_dir = '/var/opt/gitlab/gitaly'

   [logging]
   format = 'json'
   level = 'info'
   dir = '/var/log/gitaly'
   ```

1. Ajoutez ce qui suit à `/home/git/gitaly/config.toml` pour chaque serveur Gitaly respectif :

   Sur `gitaly1.internal` :

   ```toml
   [[storage]]
   name = 'default'
   path = '/var/opt/gitlab/git-data/repositories'

   [[storage]]
   name = 'storage1'
   path = '/mnt/gitlab/git-data/repositories'
   ```

   Sur `gitaly2.internal` :

   ```toml
   [[storage]]
   name = 'storage2'
   path = '/srv/gitlab/git-data/repositories'
   ```

1. Modifiez `/home/git/gitlab-shell/config.yml` :

   ```yaml
   gitlab_url: https://gitlab.example.com
   ```

1. Enregistrez les fichiers et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Confirmez que Gitaly peut effectuer des rappels vers l'API interne de GitLab :

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> Si vous copiez directement des données de dépôt d'un serveur GitLab vers Gitaly, assurez-vous que le fichier de métadonnées, dont le chemin par défaut est `/var/opt/gitlab/git-data/repositories/.gitaly-metadata`, n'est pas inclus dans le transfert. La copie de ce fichier entraîne l'utilisation par GitLab de l'accès direct au disque pour les dépôts hébergés sur le serveur Gitaly, ce qui provoque des erreurs `Error creating pipeline` et `Commit not found`, ou des données obsolètes.

### Configurer les clients Gitaly {#configure-gitaly-clients}

En dernière étape, vous devez mettre à jour les clients Gitaly pour passer de l'utilisation du service Gitaly local à l'utilisation des serveurs Gitaly que vous venez de configurer.

> [!note]
> GitLab nécessite qu'un stockage de dépôt `default` soit configuré. [En savoir plus sur cette limitation](#gitlab-requires-a-default-repository-storage).

Cela peut être risqué car tout ce qui empêche vos clients Gitaly d'atteindre les serveurs Gitaly entraîne l'échec de toutes les requêtes Gitaly. Par exemple, tout type de problème de réseau, de pare-feu ou de résolution de noms.

Gitaly formule les hypothèses suivantes :

- Votre serveur Gitaly `gitaly1.internal` est accessible à `gitaly1.internal:8075` depuis vos clients Gitaly, et ce serveur Gitaly peut lire, écrire et définir des permissions sur `/var/opt/gitlab/git-data` et `/mnt/gitlab/git-data`.
- Votre serveur Gitaly `gitaly2.internal` est accessible à `gitaly2.internal:8075` depuis vos clients Gitaly, et ce serveur Gitaly peut lire, écrire et définir des permissions sur `/srv/gitlab/git-data`.
- Vos serveurs Gitaly `gitaly1.internal` et `gitaly2.internal` peuvent se joindre mutuellement.

Vous ne pouvez pas définir des serveurs Gitaly dont certains sont des serveurs Gitaly locaux (sans `gitaly_address`) et d'autres des serveurs distants (avec `gitaly_address`) sauf si vous utilisez une [configuration mixte](#mixed-configuration).

Configurez les clients Gitaly de l'une des deux façons suivantes. Ces instructions concernent les connexions non chiffrées, mais vous pouvez également activer la [prise en charge TLS](tls_support.md) :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Use the same token value configured on all Gitaly servers
   gitlab_rails['gitaly_token'] = '<AUTH_TOKEN>'

   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   }
   ```

   Sinon, si chaque serveur Gitaly est configuré pour utiliser un token d'authentification différent :

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Exécutez `sudo gitlab-rake gitlab:gitaly:check` sur le client Gitaly (par exemple, l'application Rails) pour confirmer qu'il peut se connecter aux serveurs Gitaly.
1. Suivez les logs pour voir les requêtes :

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           gitaly_token: AUTH_TOKEN_2
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Exécutez `sudo -u git -H bundle exec rake gitlab:gitaly:check RAILS_ENV=production` pour confirmer que le client Gitaly peut se connecter aux serveurs Gitaly.
1. Suivez les logs pour voir les requêtes :

   ```shell
   tail -f /home/git/gitlab/log/gitaly.log
   ```

{{< /tab >}}

{{< /tabs >}}

Lorsque vous consultez les logs Gitaly sur votre serveur Gitaly, vous devriez voir des requêtes arriver. Un moyen infaillible de déclencher une requête Gitaly est de cloner un dépôt depuis GitLab via HTTP ou HTTPS.

> [!warning]
> Si vous avez configuré des [hooks de serveur](../server_hooks.md), que ce soit par dépôt ou globalement, vous devez les déplacer vers les serveurs Gitaly. Si vous avez plusieurs serveurs Gitaly, copiez vos hooks de serveur sur tous les serveurs Gitaly.

#### Configuration mixte {#mixed-configuration}

GitLab peut résider sur le même serveur que l'un des nombreux serveurs Gitaly, mais ne prend pas en charge une configuration qui mélange des configurations locales et distantes. La configuration suivante est incorrecte, car :

- Toutes les adresses doivent être accessibles depuis les autres serveurs Gitaly.
- `storage1` est associé à un socket Unix pour `gitaly_address`, ce qui est invalide pour certains serveurs Gitaly.

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}
```

Pour combiner des serveurs Gitaly locaux et distants, utilisez une adresse externe pour le serveur Gitaly local. Par exemple :

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  # Address of the GitLab server that also has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}

gitaly['configuration'] = {
  # ...
  #
  # Make Gitaly accept connections on all network interfaces
  listen_addr: '0.0.0.0:8075',
  # Or for TLS
  tls_listen_addr: '0.0.0.0:9999',
  tls: {
    certificate_path:  '/etc/gitlab/ssl/cert.pem',
    key_path: '/etc/gitlab/ssl/key.pem',
  },
  storage: [
    {
      name: 'storage1',
      path: '/mnt/gitlab/git-data/repositories',
    },
  ],
}
```

`path` peut être inclus uniquement pour les partitions de stockage sur le serveur Gitaly local. S'il est exclu, le répertoire de stockage Git par défaut est utilisé pour cette partition de stockage.

### GitLab nécessite un stockage de dépôt par défaut {#gitlab-requires-a-default-repository-storage}

Lors de l'ajout de serveurs Gitaly à un environnement, vous pourriez vouloir remplacer le service Gitaly `default` d'origine. Cependant, vous ne pouvez pas reconfigurer les serveurs d'application GitLab pour supprimer le stockage `default` car GitLab requiert un stockage appelé `default`. [En savoir plus](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) sur cette limitation.

Pour contourner cette limitation :

1. Définissez un emplacement de stockage supplémentaire sur le nouveau service Gitaly et configurez le stockage supplémentaire pour qu'il soit `default`. L'emplacement de stockage doit avoir un service Gitaly en cours d'exécution et disponible pour éviter les problèmes avec les migrations de base de données qui attendent des stockages fonctionnels.
1. Dans la [zone **Admin**](../repository_storage_paths.md#configure-where-new-repositories-are-stored), définissez `default` avec un poids de zéro pour empêcher les dépôts d'y être stockés.

### Désactiver Gitaly là où ce n'est pas requis (facultatif) {#disable-gitaly-where-not-required-optional}

Si vous exécutez Gitaly [en tant que service distant](#run-gitaly-on-its-own-server), envisagez de désactiver le service Gitaly local qui s'exécute par défaut sur votre serveur GitLab, et de l'exécuter uniquement là où c'est requis.

La désactivation de Gitaly sur l'instance GitLab n'a de sens que lorsque vous exécutez GitLab dans une configuration de cluster personnalisée, où Gitaly s'exécute sur une machine distincte de l'instance GitLab. La désactivation de Gitaly sur toutes les machines du cluster n'est pas une configuration valide (certaines machines doivent agir en tant que serveurs Gitaly).

Désactivez Gitaly sur un serveur GitLab de l'une des deux façons suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitaly['enable'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/etc/default/gitlab` :

   ```shell
   gitaly_enabled=false
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

## Modifier l'interface d'écoute Gitaly {#change-the-gitaly-listening-interface}

Vous pouvez modifier l'interface sur laquelle Gitaly écoute. Vous pourriez modifier l'interface d'écoute lorsque vous disposez d'un service externe qui doit communiquer avec Gitaly. Par exemple, la [recherche de code exacte](../../integration/zoekt/_index.md) qui utilise Zoekt lorsque la recherche de code exacte est activée mais que le service réel s'exécute sur un autre serveur.

Le `gitaly_token` doit être une chaîne secrète car `gitaly_token` est utilisé pour l'authentification avec le service Gitaly. Ce secret peut être généré avec `openssl rand -base64 24` pour produire une chaîne aléatoire de 32 caractères.

Par exemple, pour modifier l'interface d'écoute Gitaly vers `0.0.0.0:8075` :

```ruby
# /etc/gitlab/gitlab.rb
# Add a shared token for Gitaly authentication
gitlab_shell['secret_token'] = 'your_secure_token_here'
gitlab_rails['gitaly_token'] = 'your_secure_token_here'

# Gitaly configuration
gitaly['gitlab_secret'] = 'your_secure_token_here'
gitaly['configuration'] = {
  listen_addr: '0.0.0.0:8075',
  auth: {
    token: 'your_secure_token_here',
  },
  storage: [
    {
      name: 'default',
      path: '/var/opt/gitlab/git-data/repositories',
    },
  ]
}

# Tell Rails where to find Gitaly
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://ip_address_here:8075' },
}

# Internal API URL (important for multi-server setups)
gitlab_rails['internal_api_url'] = 'http://ip_address_here'
```

## Groupes de contrôle {#control-groups}

Pour des informations sur les groupes de contrôle, consultez [Cgroups](cgroups.md).

## Optimisation des dépôts en arrière-plan {#background-repository-optimization}

La façon dont les données sont stockées dans la base de données d'objets d'un dépôt Git peut devenir inefficace au fil du temps, ce qui ralentit les opérations Git. Vous pouvez planifier l'exécution par Gitaly d'une tâche d'arrière-plan quotidienne avec une durée maximale pour nettoyer ces éléments et améliorer les performances.

> [!warning]
> L'optimisation des dépôts en arrière-plan peut exercer une charge significative sur l'hôte pendant son exécution. Veillez à planifier cela pendant les heures creuses et à maintenir une courte durée (par exemple, 30 à 60 minutes).

Configurez l'optimisation des dépôts en arrière-plan de l'une des deux façons suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et ajoutez :

```ruby
gitaly['configuration'] = {
  # ...
  daily_maintenance: {
    # ...
    start_hour: 4,
    start_minute: 30,
    duration: '30m',
    storages: ['default'],
  },
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et ajoutez :

```toml
[daily_maintenance]
start_hour = 4
start_minute = 30
duration = '30m'
storages = ["default"]
```

{{< /tab >}}

{{< /tabs >}}

## Rotation du token d'authentification Gitaly {#rotate-gitaly-authentication-token}

La rotation des identifiants dans un environnement de production nécessite souvent des temps d'arrêt, provoque des pannes, ou les deux.

Cependant, vous pouvez effectuer la rotation des identifiants Gitaly sans interruption de service. La rotation d'un token d'authentification Gitaly implique :

- [Vérification de la surveillance de l'authentification](#verify-authentication-monitoring).
- [Activation du mode de transition d'authentification](#enable-auth-transitioning-mode).
- [Mise à jour des tokens d'authentification Gitaly](#update-gitaly-authentication-token).
- [S'assurer qu'il n'y a pas d'échecs d'authentification](#ensure-there-are-no-authentication-failures).
- [Désactivation du mode de transition d'authentification](#disable-auth-transitioning-mode).
- [Vérification de l'application de l'authentification](#verify-authentication-is-enforced).

Cette procédure fonctionne également si vous exécutez GitLab sur un seul serveur. Dans ce cas, le serveur Gitaly et le client Gitaly font référence à la même machine.

### Vérifier la surveillance de l'authentification {#verify-authentication-monitoring}

Avant de procéder à la rotation d'un token d'authentification Gitaly, vérifiez que vous pouvez [surveiller le comportement de l'authentification](monitoring.md#queries) de votre installation GitLab en utilisant Prometheus.

Vous pouvez ensuite poursuivre le reste de la procédure.

### Activer le mode de transition d'authentification {#enable-auth-transitioning-mode}

Désactivez temporairement l'authentification Gitaly sur les serveurs Gitaly en les plaçant en mode de transition d'authentification comme suit :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: true,
  },
}
```

Après avoir effectué cette modification, votre [requête Prometheus](#verify-authentication-monitoring) devrait renvoyer quelque chose comme :

```promql
{enforced="false",status="would be ok"}  4424.985419441742
```

Étant donné que `enforced="false"`, il est sûr de commencer le déploiement du nouveau token.

### Mettre à jour le token d'authentification Gitaly {#update-gitaly-authentication-token}

Pour mettre à jour vers un nouveau token d'authentification Gitaly, sur chaque client Gitaly et serveur Gitaly :

1. Mettez à jour la configuration :

   ```ruby
   # in /etc/gitlab/gitlab.rb
   gitaly['configuration'] = {
      # ...
      auth: {
         # ...
         token: '<new secret token>',
      },
   }
   ```

   Si vous utilisez `token_file`, mettez à jour le contenu du fichier référencé avec le nouveau token. Aucun changement de configuration n'est nécessaire. Le fichier de token est lu au démarrage.

1. Redémarrez Gitaly :

   ```shell
   gitlab-ctl restart gitaly
   ```

Si vous exécutez votre [requête Prometheus](#verify-authentication-monitoring) pendant que ce changement est déployé, vous verrez des valeurs non nulles pour le compteur `enforced="false",status="denied"`.

### S'assurer qu'il n'y a pas d'échecs d'authentification {#ensure-there-are-no-authentication-failures}

Une fois le nouveau token défini, et tous les services impliqués redémarrés, vous [verrez temporairement](#verify-authentication-monitoring) un mélange de :

- `status="would be ok"`.
- `status="denied"`.

Une fois que le nouveau token a été pris en compte par tous les clients Gitaly et serveurs Gitaly, le seul taux non nul devrait être `enforced="false",status="would be ok"`.

### Désactiver le mode de transition d'authentification {#disable-auth-transitioning-mode}

Pour réactiver l'authentification Gitaly, désactivez le mode de transition d'authentification. Mettez à jour la configuration sur vos serveurs Gitaly comme suit :

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: false,
  },
}
```

> [!warning]
> Sans effectuer cette étape, vous n'avez aucune authentification Gitaly.

### Vérifier que l'authentification est appliquée {#verify-authentication-is-enforced}

Actualisez votre [requête Prometheus](#verify-authentication-monitoring). Vous devriez maintenant voir un résultat similaire à celui du début. Par exemple :

```promql
{enforced="true",status="ok"}  4424.985419441742
```

`enforced="true"` signifie que l'authentification est appliquée.

## Cache pack-objects {#pack-objects-cache}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

[Gitaly](_index.md), le service qui fournit le stockage pour les dépôts Git, peut être configuré pour mettre en cache une courte fenêtre glissante de réponses de récupération Git. Cela peut réduire la charge du serveur lorsque votre serveur reçoit beaucoup de trafic de récupération CI.

Le cache pack-objects enveloppe `git pack-objects`, une partie interne de Git qui est invoquée indirectement en utilisant les RPCs Gitaly PostUploadPack et SSHUploadPack. Gitaly exécute PostUploadPack lorsqu'un utilisateur effectue une récupération Git via HTTP, ou SSHUploadPack lorsqu'un utilisateur effectue une récupération Git via SSH. Lorsque le cache est activé, tout ce qui utilise PostUploadPack ou SSHUploadPack peut en bénéficier. Il est indépendant et n'est pas affecté par :

- Le transport (HTTP ou SSH).
- La version du protocole Git (v0 ou v2).
- Le type de récupération, comme les clones complets, les récupérations incrémentielles, les clones superficiels ou les clones partiels.

La force de ce cache réside dans sa capacité à dédupliquer les récupérations identiques simultanées. Il :

- Peut bénéficier aux instances GitLab où vos utilisateurs exécutent des pipelines CI/CD avec de nombreux jobs simultanés. Il devrait y avoir une réduction notable de l'utilisation du CPU du serveur.
- Ne bénéficie pas du tout aux récupérations uniques. Par exemple, si vous effectuez une vérification ponctuelle en clonant un dépôt sur votre ordinateur local, vous êtes peu susceptible de voir un bénéfice de ce cache car votre récupération est probablement unique.

Le cache pack-objects est un cache local. Il :

- Stocke ses métadonnées dans la mémoire du processus Gitaly dans lequel il est activé.
- Stocke les données Git réelles qu'il met en cache dans des fichiers sur le stockage local.

L'utilisation de fichiers locaux a l'avantage que le système d'exploitation peut automatiquement conserver des parties des fichiers du cache pack-objects en RAM, ce qui le rend plus rapide.

Étant donné que le cache pack-objects peut entraîner une augmentation significative des E/S d'écriture sur disque, il est désactivé par défaut.

### Configurer le cache {#configure-the-cache}

Ces paramètres de configuration sont disponibles pour le cache pack-objects. Chaque paramètre est abordé plus en détail ci-dessous.

| Paramètre   | Valeur par défaut                                            | Description                                                                                        |
|:----------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| `enabled` | `false`                                            | Active le cache. Lorsqu'il est désactivé, Gitaly exécute un processus `git pack-objects` dédié pour chaque requête. |
| `dir`     | `<PATH TO FIRST STORAGE>/+gitaly/PackObjectsCache` | Répertoire local où les fichiers de cache sont stockés.                                                      |
| `max_age` | `5m` (5 minutes)                                   | Les entrées du cache plus anciennes que cette valeur sont expulsées et supprimées du disque.                                   |
| `min_occurrences` | 1 | Nombre minimum de fois qu'une clé doit apparaître avant qu'une entrée de cache soit créée. |

Dans `/etc/gitlab/gitlab.rb`, définissez :

```ruby
gitaly['configuration'] = {
  # ...
  pack_objects_cache: {
    enabled: true,
    # The default settings for "dir", "max_age" and "min_occurences" should be fine.
    # If you want to customize these, see details below.
  },
}
```

#### `enabled` est par défaut à `false` {#enabled-defaults-to-false}

Le cache est désactivé par défaut car dans certains cas, il peut entraîner une [augmentation extrême](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4010#note_534564684) du nombre d'octets écrits sur le disque. Sur GitLab.com, nous avons vérifié que nos disques de stockage de dépôts peuvent gérer cette charge de travail supplémentaire, mais nous estimons que nous ne pouvons pas supposer que c'est le cas partout.

#### Répertoire de stockage du cache `dir` {#cache-storage-directory-dir}

Le cache a besoin d'un répertoire pour y stocker ses fichiers. Ce répertoire doit être :

- Dans un système de fichiers avec suffisamment d'espace. Si le système de fichiers du cache manque d'espace, toutes les récupérations commencent à échouer.
- Sur un disque avec suffisamment de bande passante E/S. Si le disque de cache manque de bande passante E/S, toutes les récupérations, et probablement l'ensemble du serveur, ralentissent.

> [!warning]
> Toutes les données existantes dans le répertoire spécifié seront supprimées. Veillez à ne pas utiliser un répertoire contenant des données existantes.

Par défaut, le répertoire de stockage du cache est défini sur un sous-répertoire du premier stockage Gitaly défini dans le fichier de configuration.

Plusieurs processus Gitaly peuvent utiliser le même répertoire pour le stockage du cache. Chaque processus Gitaly utilise une chaîne aléatoire unique dans le cadre des noms de fichiers de cache qu'il crée. Cela signifie :

- Ils n'entrent pas en collision.
- Ils ne réutilisent pas les fichiers d'un autre processus.

Bien que le répertoire par défaut place les fichiers de cache dans le même système de fichiers que vos données de dépôt, ce n'est pas une obligation. Vous pouvez placer les fichiers de cache sur un système de fichiers différent si cela convient mieux à votre infrastructure.

La quantité de bande passante E/S requise du disque dépend de :

- La taille et la forme des dépôts sur votre serveur Gitaly.
- Le type de trafic généré par vos utilisateurs.

Vous pouvez utiliser la métrique `gitaly_pack_objects_generated_bytes_total` comme estimation pessimiste, en supposant que votre taux de succès de cache est de 0 %.

La quantité d'espace requise dépend de :

- Le débit en octets par seconde que vos utilisateurs extraient du cache.
- La taille de la fenêtre d'expulsion du cache `max_age`.

Si vos utilisateurs extraient 100 Mo/s et que vous utilisez une fenêtre de 5 minutes, vous avez en moyenne `5*60*100 MB = 30 GB` de données dans votre répertoire de cache. Cette moyenne est une moyenne attendue, pas une garantie. La taille de pointe peut dépasser cette moyenne.

#### Fenêtre d'expulsion du cache `max_age` {#cache-eviction-window-max_age}

Le paramètre de configuration `max_age` vous permet de contrôler la probabilité d'un succès de cache et la quantité moyenne de stockage utilisée par les fichiers de cache. Les entrées plus anciennes que `max_age` sont supprimées du disque.

L'expulsion n'interfère pas avec les requêtes en cours. Il est acceptable que `max_age` soit inférieur au temps nécessaire pour effectuer une récupération sur une connexion lente, car les systèmes de fichiers Unix ne suppriment pas réellement un fichier tant que tous les processus qui lisent le fichier supprimé ne l'ont pas fermé.

#### Occurrences minimales de clé `min_occurrences` {#minimum-key-occurrences-min_occurrences}

Le paramètre `min_occurrences` contrôle la fréquence à laquelle une requête identique doit se produire avant que nous créions une nouvelle entrée de cache. La valeur par défaut est `1`, ce qui signifie que les requêtes uniques ne sont pas écrites dans le cache.

Si vous :

- Augmentez ce nombre, votre taux de succès du cache diminue et le cache utilise moins d'espace disque.
- Diminuez ce nombre, votre taux de succès du cache augmente et le cache utilise plus d'espace disque.

Vous devriez définir `min_occurrences` à `1`. Sur GitLab.com, passer de 0 à 1 nous a permis d'économiser 50 % d'espace disque de cache tout en affectant à peine le taux de succès du cache.

### Observer le cache {#observe-the-cache}

{{< history >}}

- Les logs pour la mise en cache pack-objects ont été [modifiés](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719) dans GitLab 16.0.

{{< /history >}}

Vous pouvez observer le cache en utilisant les métriques Prometheus et les champs de log.

#### Métriques Prometheus {#prometheus-metrics}

Gitaly exporte les métriques Prometheus suivantes pour surveiller le cache pack-objects :

| Métrique | Type | Description |
|:-------|:-----|:------------|
| `gitaly_pack_objects_served_bytes_total` | Compteur | Nombre total d'octets de données `git-pack-objects` servis aux clients |
| `gitaly_pack_objects_cache_lookups_total` | Compteur | Nombre de recherches dans le cache, avec un label `result` indiquant `hit` ou `miss` |
| `gitaly_pack_objects_generated_bytes_total` | Compteur | Nombre total d'octets générés en exécutant `git-pack-objects` |

**Example Prometheus queries:**

Taux de succès du cache :

```promql
sum(rate(gitaly_pack_objects_cache_lookups_total{result="hit"}[5m])) /
sum(rate(gitaly_pack_objects_cache_lookups_total[5m]))
```

Octets servis depuis le cache par seconde :

```promql
rate(gitaly_pack_objects_served_bytes_total[5m])
```

Octets générés (erreurs de cache) par seconde :

```promql
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

Efficacité du cache (octets servis vs octets générés) :

```promql
rate(gitaly_pack_objects_served_bytes_total[5m]) /
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

#### Champs de log {#log-fields}

Ces logs font partie des logs gRPC et peuvent être découverts lorsqu'un appel est exécuté.

| Champ | Description |
|:---|:---|
| `pack_objects_cache.hit` | Indique si le cache pack-objects actuel a été atteint (`true` ou `false`) |
| `pack_objects_cache.key` | Clé de cache utilisée pour le cache pack-objects |
| `pack_objects_cache.generated_bytes` | Taille (en octets) du nouveau cache en cours d'écriture |
| `pack_objects_cache.served_bytes` | Taille (en octets) du cache en cours de traitement |
| `pack_objects.compression_statistics` | Statistiques concernant la génération pack-objects |
| `pack_objects.enumerate_objects_ms` | Temps total (en ms) passé à énumérer les objets envoyés par les clients |
| `pack_objects.prepare_pack_ms` | Temps total (en ms) passé à préparer le packfile avant de l'envoyer au client |
| `pack_objects.write_pack_file_ms` | Temps total (en ms) passé à renvoyer le packfile au client. Très dépendant de la connexion internet du client |
| `pack_objects.written_object_count` | Nombre total d'objets que Gitaly renvoie au client |

Dans le cas d'un :

- Échec de cache, Gitaly enregistre à la fois un message `pack_objects_cache.generated_bytes` et `pack_objects_cache.served_bytes`. Gitaly enregistre également des statistiques plus détaillées sur la génération pack-object.
- Succès de cache, Gitaly enregistre uniquement un message `pack_objects_cache.served_bytes`.

Exemple :

```json
{
  "bytes":26186490,
  "correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
  "grpc.meta.deadline_type":"none",
  "grpc.method":"PackObjectsHook",
  "grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
  "grpc.request.glProjectPath":"root/gitlab-workhorse",
  "grpc.request.glRepository":"project-2",
  "grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
  "grpc.request.repoStorage":"default",
  "grpc.request.topLevelGroup":"@hashed",
  "grpc.service":"gitaly.HookService",
  "grpc.start_time":"2021-03-25T14:57:52.747Z",
  "level":"info",
  "msg":"finished unary call with code OK",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z",
  "pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
  "pack_objects.enumerate_objects_ms": 170,
  "pack_objects.prepare_pack_ms": 7,
  "pack_objects.write_pack_file_ms": 786,
  "pack_objects.written_object_count": 145991,
  "pack_objects_cache.generated_bytes": 49533030,
  "pack_objects_cache.hit": "false",
  "pack_objects_cache.key": "123456789",
  "pack_objects_cache.served_bytes": 49533030,
  "peer.address": "127.0.0.1",
  "pid": 8813,
}
```

## Cache `cat-file` {#cat-file-cache}

De nombreux RPCs Gitaly doivent rechercher des objets Git dans les dépôts. La plupart du temps, nous utilisons des processus `git cat-file --batch` pour cela. Pour de meilleures performances, Gitaly peut réutiliser ces processus `git cat-file` entre les appels RPC. Les processus précédemment utilisés sont conservés dans un [cache `git cat-file`](https://about.gitlab.com/blog/git-performance-on-nfs/#enter-cat-file-cache). Pour contrôler la quantité de ressources système utilisées, nous avons un nombre maximum de processus cat-file pouvant entrer dans le cache.

La limite par défaut est de 100 `cat-file`s, qui constituent une paire de processus `git cat-file --batch` et `git cat-file --batch-check`. Si vous voyez des erreurs concernant « trop de fichiers ouverts », ou une incapacité à créer de nouveaux processus, vous pourriez vouloir réduire cette limite.

Idéalement, le nombre doit être suffisamment grand pour gérer le trafic standard. Si vous augmentez la limite, vous devez mesurer le taux de succès du cache avant et après. Si le taux de succès ne s'améliore pas, la limite plus élevée ne fait probablement pas de différence significative. Voici un exemple de requête Prometheus pour voir le taux de succès :

```plaintext
sum(rate(gitaly_catfile_cache_total{type="hit"}[5m])) / sum(rate(gitaly_catfile_cache_total{type=~"(hit)|(miss)"}[5m]))
```

Configurez le cache `cat-file` dans le fichier de configuration Gitaly.

## Configurer la signature des commits pour les commits de l'interface utilisateur GitLab {#configure-commit-signing-for-gitlab-ui-commits}

{{< history >}}

- Affichage du badge **Vérifié** pour les commits GitLab UI signés [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) dans GitLab 16.3 [avec un feature flag](../feature_flags/_index.md) nommé `gitaly_gpg_signing`. Désactivé par défaut.
- Vérification des signatures à l'aide de plusieurs clés spécifiées dans l'option `rotated_signing_keys` [introduite](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163) dans GitLab 16.3.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876) sur GitLab Self-Managed et GitLab Dedicated dans GitLab 17.0.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité est disponible par défaut. Pour masquer la fonctionnalité, un administrateur peut [désactiver le feature flag](../feature_flags/_index.md) nommé `gitaly_gpg_signing`. Sur GitLab.com, cette fonctionnalité n'est pas disponible. Sur GitLab Dedicated, cette fonctionnalité est disponible.

Par défaut, Gitaly ne signe pas les commits effectués via l'interface utilisateur GitLab. Par exemple, les commits effectués via :

- L'éditeur web.
- Web IDE.
- Les merge requests.

Lorsque vous activez la signature des commits dans Gitaly :

- GitLab signe tous les commits effectués via l'interface utilisateur.
- La signature vérifie l'identité du validateur, pas l'identité de l'auteur.
- Vous pouvez configurer Gitaly pour indiquer qu'un commit a été validé par votre instance en définissant `committer_email` et `committer_name`. Par exemple, sur GitLab.com, ces options de configuration sont définies sur `noreply@gitlab.com` et `GitLab`.

`rotated_signing_keys` est une liste de clés à utiliser uniquement pour la vérification. Gitaly essaie de vérifier un commit web en utilisant la `signing_key` configurée, puis utilise les clés pivotées une par une jusqu'à ce qu'il réussisse. Définissez l'option `rotated_signing_keys` dans l'un ou l'autre des cas suivants :

- La clé de signature est pivotée.
- Vous souhaitez spécifier plusieurs clés pour migrer des projets depuis d'autres instances et afficher leurs commits web comme **Vérifié**.

Configurez Gitaly pour signer les commits effectués via l'interface utilisateur GitLab de l'une des deux façons suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. [Créez une clé GPG](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key) et exportez-la, ou [créez une clé SSH](../../user/ssh.md#generate-an-ssh-key-pair). Pour des performances optimales, utilisez une clé EdDSA.

   Exporter la clé GPG :

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   Ou créez une clé SSH (sans phrase secrète) :

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Sur les nœuds Gitaly, copiez la clé dans `/etc/gitlab/gitaly/` et assurez-vous que l'utilisateur `git` dispose des permissions de lecture du fichier.
1. Modifiez `/etc/gitlab/gitlab.rb` et configurez `gitaly['git']['signing_key']` :

   ```ruby
   gitaly['configuration'] = {
      # ...
      git: {
        # ...
        committer_name: 'Your Instance',
        committer_email: 'noreply@yourinstance.com',
        signing_key: '/etc/gitlab/gitaly/signing_key.gpg',
        rotated_signing_keys: ['/etc/gitlab/gitaly/previous_signing_key.gpg'],
        # ...
      },
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. [Créez une clé GPG](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key) et exportez-la, ou [créez une clé SSH](../../user/ssh.md#generate-an-ssh-key-pair). Pour des performances optimales, utilisez une clé EdDSA.

   Exporter la clé GPG :

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   Ou créez une clé SSH (sans phrase secrète) :

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Sur les nœuds Gitaly, copiez la clé dans `/etc/gitlab`.
1. Modifiez `/home/git/gitaly/config.toml` et configurez `signing_key` :

   ```toml
   [git]
   committer_name = "Your Instance"
   committer_email = "noreply@yourinstance.com"
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   rotated_signing_keys = ["/etc/gitlab/gitaly/previous_signing_key.gpg"]
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

## Configurer une configuration Git personnalisée {#configure-custom-git-configuration}

Gitaly ne lit pas les fichiers de configuration Git du système ou de l'utilisateur. Pour fournir une configuration Git personnalisée sur le serveur Gitaly, utilisez le paramètre `git.config`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` :

```ruby
gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      { key: "fsck.badDate", value: "ignore" },
      ...
    ],
  },
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` :

```toml
[[git.config]]
key = "fsck.badDate"
value = "ignore"
```

{{< /tab >}}

{{< /tabs >}}

### Configuration Git définie par Gitaly {#git-configuration-set-by-gitaly}

Gitaly définit les valeurs de configuration Git suivantes, qui ne peuvent pas être remplacées à l'aide du paramètre `git.config` :

- `advice.fetchShowForcedUpdates`
- `attr.tree`
- `bundle.heuristic`
- `bundle.mode`
- `bundle.version`
- `core.alternateRefsCommand`
- `core.autocrlf`
- `core.bigFileThreshold`
- `core.filesRefLockTimeout`
- `core.fsync`
- `core.fsyncMethod`
- `core.hooksPath`
- `core.packedRefsTimeout`
- `core.useReplaceRefs`
- `diff.noprefix`
- `fetch.fsck.badTimezone`
- `fetch.fsck.missingSpaceBeforeDate`
- `fetch.fsck.zeroPaddedFilemode`
- `fetch.fsckObjects`
- `fetch.negotiationAlgorithm`
- `fetch.recurseSubmodules`
- `fetch.writeCommitGraph`
- `fsck.badTimezone`
- `fsck.missingSpaceBeforeDate`
- `fsck.zeroPaddedFilemode`
- `gc.auto`
- `grep.threads`
- `http.<url>.extraHeader`
- `http.curloptResolve`
- `http.extraHeader`
- `http.followRedirects`
- `init.defaultBranch`
- `init.templateDir`
- `maintenance.auto`
- `pack.allowPackReuse`
- `pack.island`
- `pack.islandCore`
- `pack.threads`
- `pack.windowMemory`
- `pack.writeBitmapLookupTable`
- `pack.writeReverseIndex`
- `receive.advertisePushOptions`
- `receive.autogc`
- `receive.fsck.badTimezone`
- `receive.fsck.missingSpaceBeforeDate`
- `receive.fsck.zeroPaddedFilemode`
- `receive.hideRefs`
- `receive.procReceiveRefs`
- `remote.inmemory.fetch`
- `remote.inmemory.url`
- `remote.origin.fetch`
- `remote.origin.url`
- `repack.updateServerInfo`
- `repack.writeBitmaps`
- `transfer.bundleURI`
- `transfer.fsckObjects`
- `uploadpack.advertiseBundleURIs`
- `uploadpack.allowAnySHA1InWant`
- `uploadpack.allowFilter`
- `uploadpack.hideRefs`

## Générer une configuration à l'aide d'une commande externe {#generate-configuration-using-an-external-command}

Vous pouvez générer des parties de la configuration Gitaly à l'aide d'une commande externe. Vous pourriez le faire :

- Pour configurer des nœuds sans avoir à distribuer la configuration complète à chacun d'eux.
- Pour configurer en utilisant la découverte automatique des paramètres du nœud. Par exemple, en utilisant des entrées DNS.
- Pour configurer des secrets au démarrage du nœud, afin qu'ils n'aient pas besoin d'être visibles en texte clair.

Pour générer une configuration à l'aide d'une commande externe, vous devez fournir un script qui produit la configuration souhaitée du nœud Gitaly au format JSON sur sa sortie standard.

Par exemple, la commande suivante configure le mot de passe HTTP utilisé pour se connecter à l'API interne de GitLab en utilisant un secret AWS :

```ruby
#!/usr/bin/env ruby
require 'json'
JSON.generate({"gitlab": {"http_settings": {"password": `aws get-secret-value --secret-id ...`}}})
```

Vous devez ensuite rendre le chemin du script connu de Gitaly de l'une des deux façons suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `config_command` :

```ruby
gitaly['configuration'] = {
    config_command: '/path/to/config_command',
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `config_command` :

```toml
config_command = "/path/to/config_command"
```

{{< /tab >}}

{{< /tabs >}}

Après la configuration, Gitaly exécute la commande au démarrage et analyse sa sortie standard en JSON. La configuration résultante est ensuite fusionnée avec les autres configurations Gitaly.

Gitaly échoue au démarrage si :

- La commande de configuration échoue.
- La sortie produite par la commande ne peut pas être analysée comme du JSON valide.

## Configurer les sauvegardes côté serveur {#configure-server-side-backups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) dans GitLab 16.3.
- Prise en charge côté serveur pour la restauration d'une sauvegarde spécifiée au lieu de la dernière sauvegarde [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188) dans GitLab 16.6.
- Prise en charge côté serveur pour la création de sauvegardes incrémentielles [introduite](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475) dans GitLab 16.6.
- Prise en charge côté serveur ajoutée aux installations Helm chart dans GitLab 17.0.

{{< /history >}}

Les sauvegardes de dépôts peuvent être configurées de sorte que le nœud Gitaly qui héberge chaque dépôt soit responsable de la création de la sauvegarde et de son streaming vers le stockage d'objets. Cela permet de réduire les ressources réseau nécessaires pour créer et restaurer une sauvegarde.

Chaque nœud Gitaly doit être configuré pour se connecter au stockage d'objets pour les sauvegardes.

Après avoir configuré les sauvegardes côté serveur, vous pouvez [créer une sauvegarde de dépôt côté serveur](../backup_restore/backup_gitlab.md#create-server-side-repository-backups).

### Configurer le stockage Azure Blob {#configure-azure-blob-storage}

La façon dont vous configurez le stockage Azure Blob pour les sauvegardes dépend du type d'installation que vous avez. Pour les installations compilées manuellement, vous devez définir les variables d'environnement `AZURE_STORAGE_ACCOUNT` et `AZURE_STORAGE_KEY` en dehors de GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour les déploiements basés sur Helm, consultez la [documentation de sauvegarde côté serveur pour le chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[backup]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configurer le stockage Google Cloud {#configure-google-cloud-storage}

Le stockage Google Cloud (GCP) s'authentifie en utilisant les identifiants par défaut de l'application. Configurez les identifiants par défaut de l'application sur chaque serveur Gitaly en utilisant l'une des méthodes suivantes :

- La commande [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login).
- La variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS`. Pour les installations compilées manuellement, définissez la variable d'environnement en dehors de GitLab.

Pour plus d'informations, consultez [Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc).

Le bucket de destination est configuré à l'aide de l'option `go_cloud_url`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour les déploiements basés sur Helm, consultez la [documentation de sauvegarde côté serveur pour le chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[backup]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configurer le stockage S3 {#configure-s3-storage}

Pour configurer l'authentification du stockage S3 :

- Si vous vous authentifiez avec l'AWS CLI, vous pouvez utiliser la session AWS par défaut.
- Sinon, vous pouvez utiliser les variables d'environnement `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`. Pour les installations compilées manuellement, définissez les variables d'environnement en dehors de GitLab.

Pour plus d'informations, consultez la [documentation de session AWS](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/).

Le bucket et la région de destination sont configurés à l'aide de l'option `go_cloud_url`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour les déploiements basés sur Helm, consultez la [documentation de sauvegarde côté serveur pour le chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### Configurer les serveurs compatibles S3 {#configure-s3-compatible-servers}

Les serveurs compatibles S3 sont configurés de manière similaire à S3, avec l'ajout du paramètre `endpoint`.

Les paramètres suivants sont pris en charge :

- `region` : La région AWS.
- `endpoint` : L'URL du point de terminaison.
- `disabledSSL` : Une valeur `true` désactive SSL.
- `s3ForcePathStyle` : Une valeur `true` force l'adressage en mode chemin.

{{< tabs >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour les déploiements basés sur Helm, consultez la [documentation de sauvegarde côté serveur pour le chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups).

{{< /tab >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => '<your_access_key_id>',
    'AWS_SECRET_ACCESS_KEY' => '<your_secret_access_key>'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true"
```

{{< /tab >}}

{{< /tabs >}}
