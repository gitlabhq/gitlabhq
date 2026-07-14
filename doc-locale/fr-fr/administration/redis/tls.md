---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sécuriser Redis et Sentinel avec TLS
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Prise en charge de TLS pour Redis introduite](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6550) dans GitLab 14.7.
- [Prise en charge de TLS pour Sentinel introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982) dans GitLab 18.10.
- [Prise en charge du TLS mutuel introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982) dans GitLab 18.10.

{{< /history >}}

Sécurisez les communications Redis et Sentinel à l'aide de TLS (Transport Layer Security). Le TLS standard (validation du certificat serveur) et le TLS mutuel (mTLS, où le client et le serveur s'authentifient mutuellement) sont tous deux pris en charge.

Si vous activez TLS pour Redis ou Sentinel, vous devez l'activer pour Redis et Sentinel dans votre déploiement. Le mélange de connexions TLS et non-TLS dans le même environnement peut entraîner une complexité de configuration et des problèmes de sécurité potentiels.

Pour désactiver le port standard non-TLS et n'accepter que les connexions TLS, définissez le port sur 0 dans votre configuration. Par exemple :

- Ajoutez `redis['port'] = 0` pour désactiver le port Redis standard (6379).
- Ajoutez `sentinel['port'] = 0` pour désactiver le port Sentinel standard (26379).

## Générer des fichiers de certificat et de clé TLS {#generate-tls-certificate-and-key-files}

Avant de configurer TLS, vous devez générer ou obtenir les certificats et clés suivants. Ces exemples de noms de fichiers sont utilisés tout au long de la documentation :

- **CA certificate** (`ca.crt`) :  Un certificat d'autorité de certification pour valider les certificats serveur.
- **Server certificate** (`redis-server.crt`) :  Un certificat pour le serveur Redis (signé par la CA).
- **Server key** (`redis-server.key`) :  La clé privée du certificat du serveur Redis.
- **Sentinel server certificate** (`sentinel-server.crt`) :  Un certificat pour le serveur Sentinel (signé par la CA).
- **Sentinel server key** (`sentinel-server.key`) :  La clé privée du certificat du serveur Sentinel.
- **Client certificate** (`redis-client.crt`, pour mTLS) :  Un certificat pour le client (signé par la CA).
- **Client key** (`redis-client.key`, pour mTLS) :  La clé privée du certificat client.

Ces exemples utilisent `/etc/gitlab/ssl/` comme répertoire de certificats, mais vous pouvez stocker les certificats dans n'importe quel répertoire, à condition que les permissions de fichiers appropriées soient définies pour les processus qui doivent les lire.

### Exemple de script de génération de certificats {#sample-certificate-generation-script}

Le script suivant génère un ensemble complet de certificats pour Redis et Sentinel avec des SAN appropriés. Vous devez personnaliser les adresses IP et les noms d'hôte pour correspondre à votre infrastructure réelle avant l'exécution.

> [!warning]
> La clé privée CA (`ca.key`) est sensible. Après avoir généré les certificats, envisagez de stocker la clé privée CA de manière sécurisée hors ligne et de la supprimer des serveurs de production.

1. Créez un fichier nommé `generate-redis-certs.sh` avec le contenu suivant :

   ```shell
   #!/bin/bash

   # Configuration: CUSTOMIZE THESE VALUES FOR YOUR INFRASTRUCTURE
   CERT_DIR="/etc/gitlab/ssl"
   CA_CN="redis-ca"
   REDIS_HOSTNAMES="redis-primary,redis-replica-1,redis-replica-2"
   REDIS_IPS="10.0.0.1,10.0.0.2,10.0.0.3"
   SENTINEL_HOSTNAMES="sentinel-1,sentinel-2,sentinel-3"
   SENTINEL_IPS="10.0.0.1,10.0.0.2,10.0.0.3"
   CERT_DAYS=365

   mkdir -p "$CERT_DIR"

   # Create OpenSSL config for SAN extensions
   cat > /tmp/redis-san.conf << EOF
   [redis_server]
   subjectAltName = DNS:${REDIS_HOSTNAMES},IP:${REDIS_IPS}

   [sentinel_server]
   subjectAltName = DNS:${SENTINEL_HOSTNAMES},IP:${SENTINEL_IPS}

   [redis_client]
   subjectAltName = DNS:redis-client
   EOF

   # Generate CA certificate
   echo "Generating CA certificate..."
   openssl genrsa -out "$CERT_DIR/ca.key" 2048
   openssl req -new -x509 -days "$CERT_DAYS" -key "$CERT_DIR/ca.key" \
     -out "$CERT_DIR/ca.crt" -subj "/CN=$CA_CN"

   # Generate Redis server certificate
   echo "Generating Redis server certificate..."
   openssl genrsa -out "$CERT_DIR/redis-server.key" 2048
   openssl req -new -key "$CERT_DIR/redis-server.key" \
     -out "$CERT_DIR/redis-server.csr" -subj "/CN=redis-server"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/redis-server.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/redis-server.crt" \
     -extensions redis_server -extfile /tmp/redis-san.conf

   # Generate Sentinel server certificate
   echo "Generating Sentinel server certificate..."
   openssl genrsa -out "$CERT_DIR/sentinel-server.key" 2048
   openssl req -new -key "$CERT_DIR/sentinel-server.key" \
     -out "$CERT_DIR/sentinel-server.csr" -subj "/CN=sentinel-server"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/sentinel-server.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/sentinel-server.crt" \
     -extensions sentinel_server -extfile /tmp/redis-san.conf

   # Generate client certificate (for mTLS)
   echo "Generating Redis client certificate..."
   openssl genrsa -out "$CERT_DIR/redis-client.key" 2048
   openssl req -new -key "$CERT_DIR/redis-client.key" \
     -out "$CERT_DIR/redis-client.csr" -subj "/CN=redis-client"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/redis-client.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/redis-client.crt" \
     -extensions redis_client -extfile /tmp/redis-san.conf

   # Clean up CSR files and temp config
   rm -f "$CERT_DIR"/*.csr /tmp/redis-san.conf

   # Set basic permissions (will be refined in the next steps)
   chmod 600 "$CERT_DIR"/*.key
   chmod 644 "$CERT_DIR"/*.crt

   echo "Certificates generated in $CERT_DIR"
   echo "Next: Configure file permissions based on your deployment (separate or shared nodes)"
   ```

1. Mettez à jour ces variables dans le script pour correspondre à votre infrastructure :

   - `REDIS_HOSTNAMES` :  Liste séparée par des virgules de tous les noms d'hôte des serveurs Redis.
   - `REDIS_IPS` :  Liste séparée par des virgules de toutes les adresses IP des serveurs Redis.
   - `SENTINEL_HOSTNAMES` :  Liste séparée par des virgules de tous les noms d'hôte des serveurs Sentinel.
   - `SENTINEL_IPS` :  Liste séparée par des virgules de toutes les adresses IP des serveurs Sentinel.
   - `CERT_DAYS` :  Période de validité du certificat en jours (par défaut :  365).

   Le certificat doit inclure tous les noms d'hôte et adresses IP que les clients utilisent pour se connecter à Redis ou Sentinel. Par exemple, si les clients se connectent à `redis.example.com` et `10.0.0.1`, les deux doivent figurer dans le SAN.
1. Exécutez le script :

   ```shell
   chmod +x generate-redis-certs.sh
   sudo ./generate-redis-certs.sh
   ```

### Définir les permissions des fichiers de certificat et de clé {#set-certificate-and-key-file-permissions}

Par défaut, les processus GitLab s'exécutent en tant qu'utilisateurs différents :

- Les processus Redis et Sentinel s'exécutent en tant qu'utilisateur `gitlab-redis`.
- Les processus Puma (GitLab Rails), Workhorse et KAS s'exécutent en tant qu'utilisateur `git`.

Après avoir placé les certificats et les clés dans `/etc/gitlab/ssl/`, assurez-vous que les permissions de fichiers suffisantes sont définies afin que tous les processus requis puissent les lire.

#### Lors de l'exécution sur des nœuds séparés {#when-running-separate-nodes}

Si Redis/Sentinel s'exécute sur un nœud séparé (Redis sur une machine différente) de l'application GitLab :

1. Sur le nœud Redis/Sentinel, exécutez ces commandes :

   ```shell
   # Set ownership to the gitlab-redis user (for Redis/Sentinel processes only)
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/redis-*.{crt,key}
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/sentinel-*.{crt,key}
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/ca.crt

   # Set restrictive permissions (readable by owner only)
   sudo chmod 600 /etc/gitlab/ssl/redis-*.key
   sudo chmod 600 /etc/gitlab/ssl/sentinel-*.key
   sudo chmod 644 /etc/gitlab/ssl/redis-*.crt
   sudo chmod 644 /etc/gitlab/ssl/sentinel-*.crt
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

1. Sur le nœud de l'application GitLab (pour les connexions client mTLS), exécutez ces commandes :

   ```shell
   # For GitLab Rails, Workhorse, and KAS processes (running as 'git' user)
   sudo chown root:git /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:git /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

#### Lors de l'exécution sur un nœud partagé {#when-running-a-shared-node}

Si les processus Redis/Sentinel et de l'application GitLab s'exécutent sur le même nœud, vous devez autoriser les utilisateurs `gitlab-redis` et `git` à lire les certificats. Utilisez une approche de groupe partagé.

1. Sur le nœud partagé, exécutez ces commandes :

   ```shell
   # Create a shared group for certificate access (if it doesn't exist)
   sudo groupadd -f gitlab-certs

   # Add both users to the shared group
   sudo usermod -a -G gitlab-certs gitlab-redis
   sudo usermod -a -G gitlab-certs git

   # Set ownership and permissions for server certificates (Redis/Sentinel)
   sudo chown gitlab-redis:gitlab-certs /etc/gitlab/ssl/redis-server.{crt,key}
   sudo chown gitlab-redis:gitlab-certs /etc/gitlab/ssl/sentinel-server.{crt,key}
   sudo chmod 640 /etc/gitlab/ssl/redis-server.key
   sudo chmod 644 /etc/gitlab/ssl/redis-server.crt
   sudo chmod 644 /etc/gitlab/ssl/sentinel-server.key
   sudo chmod 644 /etc/gitlab/ssl/sentinel-server.crt

   # Set ownership and permissions for client certificates (GitLab processes)
   sudo chown root:gitlab-certs /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:gitlab-certs /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

1. Après avoir apporté des modifications aux permissions, redémarrez GitLab :

   ```shell
   sudo gitlab-ctl restart
   ```

1. Vérifiez que les processus peuvent lire les fichiers en consultant les journaux :

   ```shell
   sudo gitlab-ctl tail
   ```

## Activer le TLS standard {#enable-standard-tls}

Le TLS standard signifie que le client valide le certificat du serveur. Le serveur ne requiert pas et ne valide pas un certificat client.

> [!note]
> Les chemins des fichiers de certificat indiqués dans les exemples suivants (comme `/etc/gitlab/ssl/redis-server.crt`) sont des espaces réservés. Utilisez les noms de fichiers réels générés par votre processus de génération de certificats. Si vous avez utilisé l'exemple de script ci-dessus, les noms de fichiers correspondront à ces exemples.

### Configurer Redis avec le TLS standard {#configure-redis-with-standard-tls}

Configurez le Redis principal avec TLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur Redis principal :

   ```ruby
   roles ['redis_master_role']

   redis['bind'] = '10.0.0.1'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez les réplicas Redis avec TLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque serveur Redis réplica :

   ```ruby
   roles ['redis_replica_role']

   redis['bind'] = '10.0.0.2'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['master_port'] = 6380  # Use TLS port

   # Enable TLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez l'application GitLab pour se connecter à Redis avec TLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur d'application GitLab :

   ```ruby
   # Configure Redis with TLS
   gitlab_rails['redis_host'] = '10.0.0.1'
   gitlab_rails['redis_port'] = 6380
   gitlab_rails['redis_password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   gitlab_rails['redis_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Configurer Sentinel avec le TLS standard {#configure-sentinel-with-standard-tls}

Configurez les serveurs Sentinel avec TLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque serveur Sentinel :

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Enable TLS for Sentinel
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez l'application GitLab pour se connecter à Sentinel avec TLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur d'application GitLab :

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with TLS
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Enable TLS for Sentinel
   gitlab_rails['redis_sentinels_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Activer le TLS mutuel (mTLS) {#enable-mutual-tls-mtls}

Le TLS mutuel exige que le client et le serveur s'authentifient mutuellement à l'aide de certificats.

### Configurer Redis avec le TLS mutuel {#configure-redis-with-mutual-tls}

Configurez le Redis principal avec mTLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur Redis principal :

   ```ruby
   roles ['redis_master_role']

   redis['bind'] = '10.0.0.1'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'

   # Enable mTLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'

   # Require client certificate validation
   redis['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez les réplicas Redis avec mTLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque serveur Redis réplica :

   ```ruby
   roles ['redis_replica_role']

   redis['bind'] = '10.0.0.2'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['master_port'] = 6380  # Use TLS port

   # Enable mTLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'

   # Require client certificate validation
   redis['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez l'application GitLab pour se connecter à Redis avec mTLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur d'application GitLab :

   ```ruby
   # Configure Redis with mTLS
   gitlab_rails['redis_host'] = '10.0.0.1'
   gitlab_rails['redis_port'] = 6380
   gitlab_rails['redis_password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   gitlab_rails['redis_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'

   # Provide client certificate and key for mTLS
   gitlab_rails['redis_tls_client_cert_file'] = '/etc/gitlab/ssl/redis-client.crt'
   gitlab_rails['redis_tls_client_key_file'] = '/etc/gitlab/ssl/redis-client.key'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Configurer Sentinel avec le TLS mutuel {#configure-sentinel-with-mutual-tls}

Configurez les serveurs Sentinel avec mTLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque serveur Sentinel :

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Enable mTLS for Sentinel
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'

   # Require client certificate validation
   sentinel['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez l'application GitLab pour se connecter à Sentinel avec mTLS :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur d'application GitLab :

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with mTLS
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Enable TLS for Sentinel
   gitlab_rails['redis_sentinels_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'

   # Provide client certificate and key for mTLS
   gitlab_rails['redis_sentinels_tls_client_cert_file'] = '/etc/gitlab/ssl/redis-client.crt'
   gitlab_rails['redis_sentinels_tls_client_key_file'] = '/etc/gitlab/ssl/redis-client.key'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Sécuriser Sentinel avec un mot de passe {#secure-sentinel-with-a-password}

En plus de TLS, vous pouvez ajouter une authentification par mot de passe à Sentinel. L'authentification par mot de passe est facultative mais recommandée pour une sécurité accrue.

### Configurer le mot de passe Sentinel {#configure-sentinel-password}

Définissez un mot de passe sur les serveurs Sentinel :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque serveur Sentinel :

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Set Sentinel password
   sentinel['password'] = 'sentinel-password-goes-here'

   # TLS configuration (if enabled)
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Configurez l'application GitLab pour s'authentifier auprès de Sentinel :

1. Modifiez `/etc/gitlab/gitlab.rb` sur le serveur d'application GitLab :

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with password authentication
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Set Sentinel password
   gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here'

   # Enable TLS for Sentinel (if configured)
   gitlab_rails['redis_sentinels_ssl'] = true
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Vérifier la configuration TLS {#verify-tls-configuration}

Après avoir configuré TLS, vérifiez que les connexions fonctionnent correctement :

1. Vérifiez que Redis écoute sur le port TLS (6380 par défaut) :

   ```shell
   sudo netstat -tlnp | grep redis
   ```

   Vous devriez voir Redis écouter sur le port standard (6379) et sur le port TLS (6380).
1. Vérifiez que Sentinel écoute sur le port TLS (26380 par défaut) :

   ```shell
   sudo netstat -tlnp | grep sentinel
   ```

   Vous devriez voir Sentinel écouter sur le port standard (26379) et sur le port TLS (26380).
1. Testez la connexion TLS à Redis à l'aide de `redis-cli` :

   ```shell
   redis-cli --tls --cacert /etc/gitlab/ssl/ca.crt --cert /etc/gitlab/ssl/redis-client.crt --key /etc/gitlab/ssl/redis-client.key -h 10.0.0.1 -p 6380 ping
   ```

   Pour le TLS standard (sans certificats client), omettez les options `--cert` et `--key`.
1. Surveillez les journaux pour détecter toute erreur liée à TLS :

   ```shell
   sudo gitlab-ctl tail redis
   sudo gitlab-ctl tail sentinel
   sudo gitlab-ctl tail gitlab-rails
   sudo gitlab-ctl tail gitlab-workhorse
   ```

1. Sur les nœuds exécutant GitLab Rails, vérifiez les fichiers de configuration générés pour vous assurer que les paramètres TLS sont présents :

   ```shell
   cat /var/opt/gitlab/gitlab-rails/etc/resque.yml
   cat /var/opt/gitlab/gitlab-rails/etc/cable.yml
   ```

   Vous devriez voir `ssl: true` et `ssl_params` avec les chemins des certificats.

## Référence de configuration TLS {#tls-configuration-reference}

Référence des paramètres Redis, Sentinel et de l'application GitLab (Rails).

### Paramètres TLS Redis {#redis-tls-settings}

| Paramètre                     | Description |
|:----------------------------|:------------|
| `redis['port']`             | Port Redis standard (définir sur 0 pour désactiver le port non-TLS) |
| `redis['tls_port']`         | Port pour les connexions TLS (par défaut :  6380) |
| `redis['tls_cert_file']`    | Chemin vers le fichier de certificat serveur |
| `redis['tls_key_file']`     | Chemin vers le fichier de clé privée serveur |
| `redis['tls_ca_cert_file']` | Chemin vers le fichier de certificat CA |
| `redis['tls_replication']`  | Activer TLS pour la réplication (par défaut : `no`) |
| `redis['tls_auth_clients']` | Exiger la validation du certificat client (par défaut : `no`) |
| `redis['master_name']`      | Nom du Redis principal (requis pour Sentinel) |
| `redis['master_password']`  | Mot de passe du Redis principal (requis pour Sentinel uniquement si l'authentification est activée sur le Redis principal) |
| `redis['master_port']`      | Port du Redis principal (requis si TLS est activé pour la réplication) |

### Paramètres TLS Sentinel {#sentinel-tls-settings}

| Paramètre                        | Description |
|:-------------------------------|:------------|
| `sentinel['port']`             | Port Sentinel standard (définir sur 0 pour désactiver le port non-TLS) |
| `sentinel['tls_port']`         | Port pour les connexions TLS (par défaut :  26380) |
| `sentinel['tls_cert_file']`    | Chemin vers le fichier de certificat serveur |
| `sentinel['tls_key_file']`     | Chemin vers le fichier de clé privée serveur |
| `sentinel['tls_ca_cert_file']` | Chemin vers le fichier de certificat CA |
| `sentinel['tls_replication']`  | Activer TLS pour la réplication (par défaut : `no`) |
| `sentinel['tls_auth_clients']` | Exiger la validation du certificat client (par défaut : `no`) |
| `sentinel['password']`         | Mot de passe pour l'authentification Sentinel (facultatif) |

### Paramètres TLS GitLab Rails {#gitlab-rails-tls-settings}

| Paramètre                                                | Description |
|:-------------------------------------------------------|:------------|
| `gitlab_rails['redis_ssl']`                            | Activer TLS pour les connexions Redis (par défaut : false) |
| `gitlab_rails['redis_sentinels_ssl']`                  | Activer TLS pour les connexions Sentinel (par défaut : false) |
| `gitlab_rails['redis_tls_ca_cert_file']`               | Chemin vers le certificat CA pour la validation Redis |
| `gitlab_rails['redis_tls_client_cert_file']`           | Chemin vers le certificat client pour le mTLS Redis |
| `gitlab_rails['redis_tls_client_key_file']`            | Chemin vers la clé privée client pour le mTLS Redis |
| `gitlab_rails['redis_sentinels_password']`             | Mot de passe pour l'authentification Sentinel (facultatif) |
| `gitlab_rails['redis_sentinels_tls_ca_cert_file']`     | Chemin vers le certificat CA pour la validation Sentinel |
| `gitlab_rails['redis_sentinels_tls_client_cert_file']` | Chemin vers le certificat client pour le mTLS Sentinel |
| `gitlab_rails['redis_sentinels_tls_client_key_file']`  | Chemin vers la clé privée client pour le mTLS Sentinel |
| `redis_exporter['enable']`                             | Désactiver l'exportateur Redis pour les instances Redis multi-nœuds (définir sur false) |

## Dépannage {#troubleshooting}

Vous pourriez voir l'erreur suivante :

```plaintext
x509: certificate relies on legacy Common Name field, use SANs instead
```

Pour éviter cette erreur, lors de la génération des certificats, assurez-vous qu'ils incluent des **Subject Alternative Names (SANs)** plutôt que de s'appuyer sur le champ Common Name hérité.
