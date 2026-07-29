---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Passerelle entre GitLab et les grands modèles de langage.
title: "Installer l'AI Gateway GitLab"
---

L'[AI Gateway](../administration/gitlab_duo/gateway.md) est une combinaison de deux services qui donnent accès aux fonctionnalités GitLab Duo natives de l'IA :

- Service AI Gateway
- [Service GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)

## Authentification et jetons JSON Web (JWT) {#authentication-and-json-web-tokens-jwt}

Pour accéder aux fonctionnalités GitLab Duo, l'AI Gateway utilise des JWT pour confirmer que les requêtes proviennent d'utilisateurs authentifiés sur votre instance GitLab. Lorsque votre instance GitLab demande un jeton, le service émet un jeton signé de courte durée qui autorise la requête.

Lorsque vous hébergez votre propre AI Gateway, vous devez générer une paire de clés de signature et transmettre les clés au service sous forme de variables d'environnement.

Chaque service utilise sa propre paire de clés :

- L'AI Gateway utilise `AIGW_SELF_SIGNED_JWT__SIGNING_KEY` et `AIGW_SELF_SIGNED_JWT__VALIDATION_KEY` pour des fonctionnalités telles que GitLab Duo Code Suggestions et GitLab Duo Chat.
- Le service GitLab Duo Agent Platform utilise `DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY` et `DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY`.

Chaque paire assure les rôles suivants :

- La clé de signature signe les jetons émis par le service.
- La clé de validation valide les jetons lors de la rotation des clés afin que les jetons signés avec une clé précédente restent valides jusqu'à leur expiration.

Les deux clés d'une paire doivent être des clés privées RSA 2048 bits au format PEM. Si ces clés sont manquantes, le service ne peut pas signer les jetons et les requêtes échouent avec une erreur de création de jeton.

## Installer avec Docker {#install-by-using-docker}

L'image Docker de l'AI Gateway GitLab contient l'ensemble du code et des dépendances nécessaires dans un seul conteneur.

Prérequis :

- Installez un moteur de conteneur Docker, tel que [Docker](https://docs.docker.com/engine/install/#server).
- Utilisez un nom d'hôte valide accessible dans votre réseau. N'utilisez pas `localhost`.
- Assurez-vous de disposer d'environ 340 Mo (compressés) pour l'architecture `linux/amd64` et d'un minimum de 512 Mo de RAM.
- Assurez-vous que le conteneur a accès à au moins deux processeurs pour les services `ai_gateway` et `duo-workflow-service`.
- Générez les clés de signature JWT :
  - Pour la plateforme GitLab Duo Agent :

    ```shell
    openssl genrsa -out duo_workflow_jwt.key 2048
    openssl genrsa -out duo_workflow_validation.key 2048
    ```

  - Pour l'AI Gateway (requis pour des fonctionnalités telles que Duo Chat) :

    ```shell
    openssl genrsa -out aigw_signing.key 2048
    openssl genrsa -out aigw_validation.key 2048
    ```

  > [!warning]
  > Conservez tous les fichiers de clés générés en lieu sûr et ne les partagez pas publiquement. Ces clés sont utilisées pour signer les JWT et doivent être traitées comme des identifiants sensibles.

Pour garantir de meilleures performances, notamment en cas d'utilisation intensive, envisagez d'allouer davantage d'espace disque, de mémoire et de ressources que les exigences minimales. Une RAM et une capacité disque supérieures peuvent améliorer l'efficacité de l'AI Gateway lors des pics de charge.

Un GPU n'est pas nécessaire pour l'AI Gateway GitLab.

### Images de l'AI Gateway {#ai-gateway-images}

#### Images standard {#standard-images}

Les images standard de l'AI Gateway sont disponibles aux emplacements suivants :

- Le registre de conteneurs : [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
- DockerHub : [Stable](https://hub.docker.com/r/gitlab/model-gateway/tags)

Si votre version de GitLab est `vX.Y.*-ee`, utilisez l'image de l'AI Gateway avec le dernier tag `self-hosted-vX.Y.*-ee`. Par exemple :

- Si GitLab est en version `v18.2.1-ee` et que l'image de l'AI Gateway dispose des versions `self-hosted-v18.2.0-ee`, `self-hosted-v18.2.1-ee` et `self-hosted-v18.2.2-ee`, utilisez `self-hosted-v18.2.2-ee`.
- Si GitLab est en version `v18.2.1-ee` et que l'image de l'AI Gateway ne dispose que de la version `self-hosted-v18.2.0-ee`, utilisez `self-hosted-v18.2.0-ee`.

Pour plus d'informations, consultez le [processus de release pour l'AI Gateway auto-hébergé](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/delivery/release.md).

> [!note]
> La compatibilité ascendante n'est pas garantie avec les builds nightly. Utilisez toujours des releases stables avec un tag de version explicite.

#### Images validées FIPS {#fips-validated-images}

Pour les environnements nécessitant une cryptographie validée FIPS 140-3, utilisez une image de l'AI Gateway validée FIPS. Cette image est construite sur Red Hat UBI 9 et utilise le [fournisseur Red Hat OpenSSL FIPS](https://access.redhat.com/compliance/fips) validé par le CMVP.

Les images de l'AI Gateway validées FIPS sont disponibles aux emplacements suivants :

- Le registre de conteneurs : [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/9518478)
- DockerHub : [Stable](https://hub.docker.com/r/gitlab/model-gateway-self-hosted-fips/tags)

Utilisez le même format de tag de version que l'image standard (`self-hosted-vX.Y.Z-ee`).

Pour démarrer le conteneur validé FIPS, remplacez la référence d'image dans la [commande Docker run](#start-a-container-from-the-image) par l'image FIPS :

```shell
registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway/self-hosted-fips:<ai-gateway-tag>
```

### Démarrer un conteneur à partir de l'image {#start-a-container-from-the-image}

1. Exécutez la commande suivante pour démarrer le conteneur :

   ```shell
   docker run -d -p 5052:5052 -p 50052:50052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=<your_gitlab_instance>/api/v4/ \
    -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
    -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
    -e DUO_WORKFLOW_AUTH__ENABLED="true" \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
   ```

   Remplacez les paramètres fictifs suivants :

   - `<your_gitlab_instance>` : L'URL de votre instance GitLab (par exemple, `https://gitlab.example.com`).
   - `<ai-gateway-tag>` : Version correspondant à votre instance GitLab. Si votre version de GitLab est `vX.Y.0`, utilisez `self-hosted-vX.Y.0-ee`.

   Depuis l'hôte du conteneur, l'accès à `http://localhost:5052` devrait renvoyer `{"error":"No authorization header presented"}`.

1. Assurez-vous que les ports `5052` et `50052` sont transférés vers le conteneur depuis l'hôte. Le port `5052` gère la communication HTTP pour l'AI Gateway. Le port `50052` gère la communication gRPC pour le service GitLab Duo Agent Platform.
1. Pour les instances GitLab qui utilisent une licence hors ligne, dans le conteneur AIGW, définissez `-e DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=<your_gitlab_instance>` et `-e AIGW_CUSTOMER_PORTAL_URL=<your_gitlab_instance>`. Cette configuration :
   - Force le service GitLab Duo Workflow à s'authentifier exclusivement auprès de l'instance GitLab locale.
   - Élimine le délai de 20 secondes causé par les appels CustomersDot injoignables.
1. Configurez l'[URL de l'AI Gateway](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway) et l'[URL du service GitLab Duo Agent Platform](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform).
1. Facultatif. Si votre point de terminaison local GitLab Duo Agent Platform utilise TLS :
   1. dans le coin supérieur droit, sélectionnez **Admin**.
   1. Sélectionnez **GitLab Duo** > **Modifier la configuration**.
   1. Cochez la case **Utiliser TLS pour le service GitLab Duo Agent Platform**.

### Restreindre l'accès réseau {#restrict-network-access}

Pour renforcer la sécurité de votre système, effectuez les configurations réseau suivantes :

- Limitez l'accès réseau sortant du conteneur de l'AI Gateway.
- Bloquez tout autre trafic sortant depuis le conteneur.

L'AI Gateway nécessite un accès sortant vers les ressources suivantes. Veillez à les inclure comme exceptions à vos restrictions réseau :

- Votre instance GitLab (`AIGW_GITLAB_URL`).
- Les points de terminaison de votre fournisseur de modèles d'IA configuré (par exemple, Anthropic, Gemini Enterprise Agent Platform ou Azure OpenAI).
- `customers.gitlab.com` pour la validation des licences, sauf si vous utilisez une licence hors ligne.

> [!warning]
> Testez les règles de pare-feu dans un environnement hors production avant de les appliquer. Des règles trop restrictives peuvent interrompre le fonctionnement de l'AI Gateway.

Pour restreindre l'accès sortant sur les hôtes Linux, utilisez les règles `iptables` dans la chaîne `DOCKER-USER`. Pour plus d'informations, consultez [Filtrage de paquets Docker et pare-feux](https://docs.docker.com/engine/network/packet-filtering-firewalls/).

## Configurer Docker avec NGINX et SSL {#set-up-docker-with-nginx-and-ssl}

> [!note]
> Cette méthode de déploiement de NGINX ou Caddy comme proxy inverse est une solution de contournement temporaire pour la prise en charge de SSL jusqu'à ce que l'[issue 455854](https://gitlab.com/gitlab-org/gitlab/-/issues/455854) soit implémentée.

Pour utiliser SSL pour une instance d'AI Gateway, utilisez :

- Docker
- NGINX comme proxy inverse
- Let's Encrypt pour les certificats SSL

NGINX gère la connexion sécurisée avec les clients externes. Il déchiffre les requêtes HTTPS entrantes avant de les transmettre à l'AI Gateway.

Prérequis :

- Docker et Docker Compose installés
- Nom de domaine enregistré et configuré

### Créer des fichiers de configuration {#create-configuration-files}

Commencez par créer les fichiers suivants dans votre répertoire de travail.

1. `nginx.conf` :

   ```nginx
   user  nginx;
   worker_processes  auto;
   error_log  /var/log/nginx/error.log warn;
   pid        /var/run/nginx.pid;
   events {
       worker_connections  1024;
   }
   http {
       include       /etc/nginx/mime.types;
       default_type  application/octet-stream;
       log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';
       access_log  /var/log/nginx/access.log  main;
       sendfile        on;
       keepalive_timeout  65;
       include /etc/nginx/conf.d/*.conf;
   }
   ```

1. `default.conf` :

   ```nginx
   # nginx/conf.d/default.conf
   server {
       listen 80;
       server_name _;

       # Forward all requests to the AI Gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }

   server {
       listen 443 ssl;
       server_name _;

       # SSL configuration
       ssl_certificate /etc/nginx/ssl/server.crt;
       ssl_certificate_key /etc/nginx/ssl/server.key;

       # Configuration for self-signed certificates
       ssl_verify_client off;
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers on;
       ssl_session_cache shared:SSL:10m;
       ssl_session_timeout 10m;

       # Proxy headers
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;

       # WebSocket support (if needed)
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";

       # Forward all requests to the AI Gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }
   ```

1. `grpc-nginx.conf` :

```nginx
# Configuration for Duo Agent Platform with TLS
events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log debug;

    upstream grpcservers {
        server gitlab-ai-gateway:50052;
    }

    server {
        listen 8443 ssl;
        http2 on;

        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            grpc_pass grpc://grpcservers;
            grpc_set_header Host $host;
        }
    }
}
```

### Configurer le certificat SSL avec Let's Encrypt {#set-up-ssl-certificate-by-using-lets-encrypt}

Pour configurer un certificat SSL :

- Pour les serveurs NGINX basés sur Docker, Certbot [fournit un moyen automatisé d'implémenter des certificats Let's Encrypt](https://phoenixnap.com/kb/letsencrypt-docker).
- Vous pouvez également utiliser l'[installation manuelle de Certbot](https://eff-certbot.readthedocs.io/en/stable/using.html#manual).

### Créer un fichier d'environnement {#create-an-environment-file}

Créez un fichier `.env` pour stocker les clés de signature et de validation JWT :

```shell
echo "AIGW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat aigw_signing.key)\"" > .env
echo "AIGW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat aigw_validation.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" >> .env
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY=\"$(cat duo_workflow_validation.key)\"" >> .env
```

### Créer un fichier Docker Compose {#create-a-docker-compose-file}

Créez maintenant un fichier `docker-compose.yaml`.

```yaml
services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /path/to/nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/default.conf:/etc/nginx/conf.d/default.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway

grpc-proxy:
    image: nginx:alpine
    ports:
      - "8443:8443"
    volumes:
      - /path/to/grpc-nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway
    restart: always

  gitlab-ai-gateway:
    image: registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
    ports:
      - "50052:50052" # Agent Platform gRPC exposed to the host
    expose:
      - "5052" # Only exposed internally to the proxy network
    environment:
      - AIGW_GITLAB_URL=<your_gitlab_instance>
      - AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/
    env_file:
      - .env
    networks:
      - proxy-network
    restart: always

networks:
  proxy-network:
    driver: bridge
```

### Déployer et valider {#deploy-and-validate}

Pour déployer et valider la solution :

1. Démarrez les conteneurs `nginx` et `AIGW` et vérifiez qu'ils sont en cours d'exécution :

   ```shell
   docker compose up
   docker ps
   ```

1. Configurez votre [instance GitLab pour accéder à l'AI Gateway](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway).
1. Configurez votre instance GitLab pour accéder à l'URL du [service GitLab Duo Agent Platform](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform).
1. Effectuez le contrôle de santé et confirmez que l'AI Gateway et la plateforme Agent sont tous deux accessibles.

## Installer avec le chart Helm {#install-by-using-helm-chart}

Prérequis :

- Vous devez disposer d'un :
  - Domaine vous appartenant, auquel vous pouvez ajouter un enregistrement DNS.
  - Cluster Kubernetes.
  - Installation fonctionnelle de `kubectl`.
  - Installation fonctionnelle de Helm, version v3.11.0 ou ultérieure.

Pour plus d'informations, consultez [Tester le chart GitLab sur GKE ou EKS](https://docs.gitlab.com/charts/quickstart/).

### Ajouter le dépôt Helm de l'AI Gateway {#add-the-ai-gateway-helm-repository}

Ajoutez le dépôt Helm de l'AI Gateway à la configuration Helm :

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### Installer l'AI Gateway {#install-the-ai-gateway}

1. Créez l'espace de nommage `ai-gateway` :

   ```shell
   kubectl create namespace ai-gateway
   ```

1. Générez le certificat pour le domaine sur lequel vous prévoyez d'exposer l'AI Gateway.
1. Créez le secret TLS dans l'espace de nommage précédemment créé :

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. Obtenez le numéro de version du dernier paquet dans le [registre de paquets du chart](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages).
1. Pour que l'AI Gateway puisse accéder à l'API, il doit connaître l'emplacement de l'instance GitLab. Pour ce faire, définissez `gitlab.url` et `gitlab.apiUrl` ainsi que les valeurs `ingress.hosts` et `ingress.tls` comme suit :

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version <latest-package-in-registery> \
     --namespace=ai-gateway \
     --set="image.tag=<ai-gateway-image-version>" \
     --set="gitlab.url=https://<your_gitlab_domain>" \
     --set="gitlab.apiUrl=https://<your_gitlab_domain>/api/v4/" \
     --set "ingress.enabled=true" \
     --set "ingress.hosts[0].host=<your_gateway_domain>" \
     --set "ingress.hosts[0].paths[0].path=/" \
     --set "ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set "ingress.tls[0].secretName=ai-gateway-tls" \
     --set "ingress.tls[0].hosts[0]=<your_gateway_domain>" \
     --set="ingress.className=nginx" \
     --set "extraEnvironmentVariables[0].name=AIGW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[0].value=$(cat aigw_signing.key)" \
     --set "extraEnvironmentVariables[1].name=AIGW_SELF_SIGNED_JWT__VALIDATION_KEY" \
     --set "extraEnvironmentVariables[1].value=$(cat aigw_validation.key)" \
     --set "extraEnvironmentVariables[2].name=DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[2].value=$(cat duo_workflow_jwt.key)" \
     --set "extraEnvironmentVariables[3].name=DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY" \
     --set "extraEnvironmentVariables[3].value=$(cat duo_workflow_validation.key)" \
     --set "extraEnvironmentVariables[4].name=DUO_WORKFLOW_AUTH__ENABLED" \
     --set "extraEnvironmentVariables[4].value={{ true | quote }}" \
     --timeout=300s --wait --wait-for-jobs
   ```

Vous pouvez trouver la liste des versions de l'AI Gateway utilisables comme `image.tag` dans le [registre de conteneurs](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted).

Cette étape peut prendre quelques secondes pour que toutes les ressources soient allouées et que l'AI Gateway démarre.

Vous devrez peut-être configurer votre propre **Ingress Controller** pour l'AI Gateway si votre contrôleur Ingress `nginx` existant ne dessert pas les services dans un espace de nommage différent. Assurez-vous qu'Ingress est correctement configuré pour les déploiements multi-espaces de nommage.

Pour les versions du chart Helm `ai-gateway`, utilisez `helm search repo ai-gateway --versions` pour trouver la version de chart appropriée.

Attendez que vos pods soient opérationnels :

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

Lorsque vos pods sont opérationnels, vous pouvez configurer vos entrées IP et vos enregistrements DNS.

## Se connecter à une instance GitLab ou à un point de terminaison de modèle avec un certificat SSL auto-signé {#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate}

Si votre instance GitLab ou votre point de terminaison de modèle est configuré avec un certificat auto-signé, vous devez ajouter votre certificat d'autorité de certification (CA) racine au bundle de certificats de l'AI Gateway.

Pour ce faire, vous pouvez soit :

- Transmettre le certificat CA racine à l'AI Gateway pour que l'authentification réussisse.
- Ajouter le certificat CA racine au bundle CA du conteneur de l'AI Gateway.

### Transmettre le certificat CA racine à l'AI Gateway {#pass-the-root-ca-certificate-to-the-ai-gateway}

Pour transmettre le certificat CA racine à l'AI Gateway et vous assurer que l'authentification réussit, définissez la variable d'environnement `REQUESTS_CA_BUNDLE`. Étant donné que GitLab utilise [Certifi](https://pypi.org/project/certifi/) pour la liste de CA de confiance de base, vous configurez un bundle CA personnalisé comme suit :

1. Téléchargez le fichier Certifi `cacert.pem` :

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. Ajoutez votre certificat CA racine auto-signé au fichier. Par exemple, si vous avez utilisé `mkcert` pour créer votre certificat :

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. Définissez `REQUESTS_CA_BUNDLE` sur le chemin de votre fichier `cacert.pem`. Par exemple, dans GDK, ajoutez ce qui suit à votre `$GDK_ROOT/env.runit` :

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### Ajouter le certificat CA racine au bundle CA du conteneur de l'AI Gateway {#add-the-root-ca-certificate-to-the-ai-gateway-containers-ca-bundle}

Pour permettre à l'AI Gateway de faire confiance au certificat d'une instance GitLab Self-Managed signé par une CA personnalisée, ajoutez le certificat CA racine au bundle CA du conteneur de l'AI Gateway.

Cette méthode ne permet pas de prendre en compte les modifications apportées au bundle CA racine dans les versions ultérieures du chart.

Pour effectuer cette opération lors d'un déploiement par chart Helm de l'AI Gateway :

1. Ajoutez le certificat CA racine personnalisé à un fichier local :

   ```shell
   cat customCA-root.crt >> ca-certificates.crt
   ```

1. Copiez le fichier bundle `/etc/ssl/certs/ca-certificates.crt` du conteneur de l'AI Gateway vers le fichier local :

   ```shell
   kubectl cp -n gitlab ai-gateway-55d697ff9d-j9pc6:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt.
   ```

1. Créez un nouveau secret à partir du fichier local :

   ```shell
   kubectl create secret generic ca-certificates -n gitlab --from-file=cacertificates.crt=ca-certificates.crt
   ```

1. Utilisez le secret dans le `values.yml` de chat pour définir un `volume` et un `volumeMount`. Cela crée le fichier `/tmp/ca-certificates.crt` dans le conteneur :

   ```shell
   volumes:
     - name: cacerts
       secret:
         secretName: ca-certificates
         optional: false

   volumeMounts:
     - name: cacerts
       mountPath: "/tmp"
       readOnly: true
   ```

1. Définissez les variables d'environnement `REQUESTS_CA_BUNDLE` et `SSL_CERT_FILE` pour qu'elles pointent vers le fichier monté :

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. Redéployez le chart.

L'[Issue 3](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3) existe pour prendre en charge cette fonctionnalité nativement dans le chart Helm.

#### Pour un déploiement Docker {#for-a-docker-deployment}

Pour un déploiement Docker, utilisez la même méthode. La seule différence est que, pour monter le fichier local dans le conteneur, utilisez `--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`.

## Mettre à niveau l'image Docker de l'AI Gateway {#upgrade-the-ai-gateway-docker-image}

Pour mettre à niveau l'AI Gateway, téléchargez le tag d'image Docker le plus récent.

1. Arrêtez le conteneur en cours d'exécution :

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. Supprimez le conteneur existant :

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. Extrayez et [exécutez la nouvelle image](#start-a-container-from-the-image).
1. Assurez-vous que toutes les variables d'environnement sont correctement définies.

## Mises à jour de sécurité et vérification des images {#security-updates-and-image-verification}

Pour vous assurer que vous exécutez les derniers correctifs de sécurité, suivez ces recommandations en fonction de votre méthode de déploiement.

### Pour les déploiements Kubernetes ou Helm {#for-kubernetes-or-helm-deployments}

Les [versions des charts](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages) antérieures à la 0.7.0 et Kubernetes utilisent `imagePullPolicy: IfNotPresent` par défaut, ce qui n'extrait pas les images mises à jour si le tag n'a pas changé. Cela signifie que vous pourriez manquer des correctifs de sécurité publiés sous le même tag de version.

Vous devriez utiliser l'approche suivante, qui utilise des digests d'image :

```shell
# Find the image digest from the container registry
# Use this digest in your Helm install/upgrade command

helm upgrade --install ai-gateway \
  ai-gateway/ai-gateway \
  --set="image.tag=self-hosted-v18.2.1-ee@sha256:abc123..." \
  # ... other flags
```

Vous pouvez également utiliser `imagePullPolicy` avec l'une des approches suivantes :

- Définissez `imagePullPolicy` sur always :

  ```shell
  helm upgrade --install ai-gateway \
    ai-gateway/ai-gateway \
    --set="image.pullPolicy=Always" \
    # ... other flags
  ```

- Ajoutez `pullPolicy` à votre `values.yaml` :

  ```yaml
  image:
    pullPolicy: Always
  ```

Pour forcer l'extraction des mises à jour :

```shell
kubectl rollout restart deployment/ai-gateway -n ai-gateway
```

### Pour les déploiements Docker {#for-docker-deployments}

Lors de la mise à niveau, vérifiez que vous extrayez la dernière image :

```shell
# Check current image digest
docker images --digests | grep ai-assist

# Pull latest version explicitly
docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>

# Verify digest changed
docker images --digests | grep ai-assist
```

Pour utiliser des digests d'image pour des déploiements immuables :

```shell
docker run -d -p 5052:5052 -p 50052:50052 \
 -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
 -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
 -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v18.2.1-ee@sha256:abc123...
```

## Méthodes d'installation alternatives {#alternative-installation-methods}

Pour plus d'informations sur les autres façons d'installer l'AI Gateway, consultez l'[issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).

## Contrôle de santé et débogage {#health-check-and-debugging}

Pour déboguer les problèmes liés à votre installation GitLab Duo Self-Hosted, exécutez la commande suivante :

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

Vérifiez que :

- L'URL de l'AI Gateway est correctement configurée (via `Ai::Setting.instance.ai_gateway_url`).
- L'accès à GitLab Duo a été explicitement activé pour l'utilisateur root via `/admin/code_suggestions`.

Si les problèmes d'accès persistent, vérifiez que l'authentification est correctement configurée et que le contrôle de santé réussit.

En cas de problèmes persistants, le message d'erreur peut suggérer de contourner l'authentification avec `AIGW_AUTH__BYPASS_EXTERNAL=true`, mais ne faites cela que pour le dépannage.

Vous pouvez également exécuter un [contrôle de santé](../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo) en accédant à **Admin** > **GitLab Duo**.

Ces tests sont effectués pour les environnements hors ligne :

| Test | Description |
|-----------------|-------------|
| Réseau | Teste si : <br>\- L'URL de l'AI Gateway a été correctement configurée dans la base de données via la table `ai_settings`.<br> \- Votre instance peut se connecter à l'URL configurée.<br><br>Si votre instance ne peut pas se connecter à l'URL, assurez-vous que les paramètres de votre pare-feu ou de votre serveur proxy [autorisent la connexion](../administration/gitlab_duo/configure/_index.md). Bien que la variable d'environnement `AI_GATEWAY_URL` soit toujours prise en charge pour la compatibilité ascendante, la configuration de l'URL via la base de données est recommandée pour une meilleure facilité de gestion. |
| Licence | Teste si votre licence permet d'accéder à la fonctionnalité Code Suggestions. |
| Échange système | Vérifie si la fonctionnalité Suggestions de code peut être utilisée dans votre instance. Si l'évaluation de l'échange système échoue, les utilisateurs risquent de ne pas pouvoir utiliser les fonctionnalités GitLab Duo. |

## Surveiller l'AI Gateway {#monitor-the-ai-gateway}

Utilisez Prometheus pour collecter des métriques sur l'utilisation et les performances de votre AI Gateway.

### Configurer les métriques Prometheus pour l'AI Gateway {#set-up-prometheus-metrics-for-the-ai-gateway}

Pour configurer les métriques Prometheus :

1. Définissez les variables d'environnement requises et ouvrez le port `8082` :

   ```shell
   -e AIGW_FASTAPI__METRICS_HOST=0.0.0.0
   -e AIGW_FASTAPI__METRICS_PORT=8082
   ```

### Configurer Prometheus pour le service GitLab Duo Workflow {#set-up-prometheus-for-the-gitlab-duo-workflow-service}

Pour configurer les métriques Prometheus sur le service GitLab Duo Workflow :

1. Définissez les variables d'environnement requises et ouvrez le port `8083` :

   ```shell
   -e PROMETHEUS_METRICS__ADDR=0.0.0.0
   -e PROMETHEUS_METRICS__PORT=8083
   ```

1. Exposez les ports de métriques du conteneur `gitlab-ai-gateway` vers l'hôte :

   - Pour Docker CLI :

     ```shell
     -p 8082:8082 \
     -p 8083:8083 \
     ```

   - Pour Docker Compose, ajoutez au service `gitlab-ai-gateway` :

     ```shell
     ports:
       - "8082:8082"
       - "8083:8083"
     ```

   Cela expose le point de terminaison des métriques de l'AI Gateway sur le port `8082` et le point de terminaison des métriques du service GitLab Duo Workflow sur le port `8083`.

1. Redémarrez le conteneur de l'AI Gateway

### Configurer Prometheus pour collecter les métriques {#configure-prometheus-to-scrape-metrics}

Pour collecter les métriques de l'AI Gateway et du service GitLab Duo Workflow, ajoutez la configuration `prometheus.yml` suivante à votre instance Prometheus. Dans cette configuration, Prometheus collecte les métriques des deux services toutes les 15 secondes.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ai-gateway'
    static_configs:
      - targets: ['<your_AIGW_domain>:8082']
    scheme: 'http'
    metrics_path: '/metrics'

  - job_name: 'duo-agent-platform-service'
    static_configs:
      - targets: ['<your_duo_agent_platform_service_domain>:8083']
    scheme: 'http'
    metrics_path: '/metrics'
```

### Vérifier la collecte des métriques {#verify-metrics-collection}

Pour vérifier que les cibles pour l'AI Gateway et le service GitLab Duo Workflow sont bien collectées :

1. Dans l'interface Prometheus, accédez à **Statut > Targets**.
1. Accédez aux onglets **Alertes** ou **Graphe** pour interroger les métriques. L'AI Gateway et le service GitLab Duo Workflow exposent les métriques aux points de terminaison suivants :

   - AI Gateway : `http://<your_AIGW_domain>:8082/metrics`
   - Service GitLab Duo Workflow : `http://<your_duo_agent_platform_service_domain>:8083/metrics`

## L'AI Gateway doit-il effectuer une mise à l'échelle automatique ? {#does-the-ai-gateway-need-to-autoscale}

La mise à l'échelle automatique n'est pas obligatoire, mais est recommandée pour les environnements avec des charges de travail variables, des exigences élevées en matière de simultanéité ou des modèles d'utilisation imprévisibles. Dans l'environnement de production GitLab :

- Configuration de base : une seule instance AI Gateway avec 2 cœurs CPU et 8 Go de RAM peut gérer environ 40 requêtes simultanées.
- Recommandations de mise à l'échelle : pour les configurations plus importantes, telles qu'une instance AWS t3.2xlarge (8 vCPU, 32 Go de RAM), la passerelle peut gérer jusqu'à 160 requêtes simultanées, soit 4 fois la configuration de base.
- Débit de requêtes : l'utilisation observée sur GitLab.com suggère que 7 RPS (requêtes par seconde) pour 1 000 utilisateurs actifs est une métrique raisonnable pour la planification.
- Options de mise à l'échelle automatique : utilisez les Horizontal Pod Autoscalers (HPA) Kubernetes ou des mécanismes similaires pour ajuster dynamiquement le nombre d'instances en fonction de métriques telles que l'utilisation du CPU, de la mémoire ou les seuils de latence des requêtes.

## Exemples de configuration par taille de déploiement {#configuration-examples-by-deployment-size}

- Petit déploiement :
  - Instance unique avec 2 vCPU et 8 Go de RAM.
  - Gère jusqu'à 40 requêtes simultanées.
  - Équipes ou organisations comptant jusqu'à 50 utilisateurs et des charges de travail prévisibles.
  - Des instances fixes peuvent suffire ; la mise à l'échelle automatique peut être désactivée pour réduire les coûts.
- Déploiement moyen :
  - Instance AWS t3.2xlarge unique avec 8 vCPU et 32 Go de RAM.
  - Gère jusqu'à 160 requêtes simultanées.
  - Organisations comptant 50 à 200 utilisateurs et des exigences modérées en matière de simultanéité.
  - Implémentez le HPA Kubernetes avec des seuils à 50 % d'utilisation CPU ou une latence de requête supérieure à 500 ms.
- Grand déploiement :
  - Cluster de plusieurs instances AWS t3.2xlarge ou équivalent.
  - Chaque instance gère 160 requêtes simultanées, permettant de passer à des milliers d'utilisateurs avec plusieurs instances.
  - Entreprises comptant plus de 200 utilisateurs et des charges de travail variables à forte simultanéité.
  - Utilisez le HPA pour mettre à l'échelle les pods en fonction de la demande en temps réel, combiné à la mise à l'échelle automatique des nœuds pour les ajustements de ressources à l'échelle du cluster.

## Spécifications du conteneur AI Gateway et allocation des ressources {#ai-gateway-container-specs-and-resource-allocation}

L'AI Gateway fonctionne efficacement avec les allocations de ressources suivantes :

- 2 cœurs CPU et 8 Go de RAM par conteneur.
- Les conteneurs utilisent généralement environ 7,39 % du CPU et une mémoire proportionnelle dans l'environnement de production GitLab, laissant de la marge pour la croissance ou la gestion des pics d'activité.

## Stratégies d'atténuation pour la contention de ressources {#mitigation-strategies-for-resource-contention}

- Utilisez les demandes et limites de ressources Kubernetes pour garantir que les conteneurs de l'AI Gateway reçoivent des allocations de CPU et de mémoire garanties. Par exemple :

  ```yaml
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
  ```

- Implémentez des outils tels que Prometheus et Grafana pour suivre l'utilisation des ressources (CPU, mémoire, latence) et détecter les goulots d'étranglement tôt.
- Dédier des nœuds ou des instances exclusivement à l'AI Gateway pour éviter toute compétition de ressources avec d'autres services.

## Stratégies de mise à l'échelle {#scaling-strategies}

- Utilisez le HPA Kubernetes pour mettre à l'échelle les pods en fonction de métriques en temps réel telles que :
  - Utilisation moyenne du CPU dépassant 50 %.
  - Latence des requêtes constamment supérieure à 500 ms.
  - Activez la mise à l'échelle automatique des nœuds pour mettre à l'échelle les ressources d'infrastructure de manière dynamique à mesure que les pods augmentent.

## Recommandations de mise à l'échelle {#scaling-recommendations}

| Taille de déploiement | Type d'instance      | Ressources             | Capacité (requêtes simultanées) | Recommandations de mise à l'échelle                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| Petit            | 2 vCPU, 8 Go de RAM | Instance unique        | 40                              | Déploiement fixe ; pas de mise à l'échelle automatique.           |
| Moyen           | AWS t3.2xlarge    | Instance unique     | 160                             | HPA basé sur des seuils de CPU ou de latence.     |
| Grand            | Plusieurs t3.2xlarge | Instances en cluster   | 160 par instance               | HPA + mise à l'échelle automatique des nœuds pour une forte demande.     |

## Prendre en charge plusieurs instances GitLab {#support-multiple-gitlab-instances}

Vous pouvez déployer un seul AI Gateway pour prendre en charge plusieurs instances GitLab, ou déployer des AI Gateways séparés par instance ou par région géographique. Pour déterminer quelle option est la plus appropriée, tenez compte des éléments suivants :

- Trafic attendu d'environ sept requêtes par seconde pour 1 000 utilisateurs facturables.
- Exigences en ressources basées sur le nombre total de requêtes simultanées sur toutes les instances.
- Configuration d'authentification recommandée pour chaque instance GitLab.

## Co-localiser votre AI Gateway et votre instance {#co-locate-your-ai-gateway-and-instance}

L'AI Gateway est disponible dans plusieurs régions du monde pour garantir des performances optimales aux utilisateurs quel que soit leur emplacement, grâce à :

- Des temps de réponse améliorés pour les fonctionnalités GitLab Duo.
- Une latence réduite pour les utilisateurs géographiquement distribués.
- La conformité aux exigences de souveraineté des données.

Vous devriez localiser votre AI Gateway dans la même région géographique que votre instance GitLab pour contribuer à offrir une expérience de développement fluide, notamment pour les fonctionnalités sensibles à la latence telles que Code Suggestions.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec l'AI Gateway, vous pourriez rencontrer les problèmes suivants.

### Problèmes de permissions OpenShift {#openshift-permission-issues}

Lors du déploiement de l'AI Gateway sur OpenShift, vous pourriez rencontrer des erreurs de permissions dues au modèle de sécurité d'OpenShift.

#### Système de fichiers en lecture seule à `/tmp` {#read-only-filesystem-at-tmp}

L'AI Gateway doit écrire dans `/tmp`. Cependant, selon l'environnement OpenShift, qui est soumis à des restrictions de sécurité, `/tmp` peut être en lecture seule.

Pour résoudre ce problème, créez un nouveau volume `EmptyDir` et montez-le à `/tmp`. Vous pouvez le faire de l'une des manières suivantes :

- Depuis la ligne de commande :

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- Ajouté à votre `values.yaml` :

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### Modèles HuggingFace {#huggingface-models}

Par défaut, l'AI Gateway utilise `/home/aigateway/.hf` pour mettre en cache les modèles HuggingFace, ce qui peut ne pas être accessible en écriture dans l'environnement restreint en matière de sécurité d'OpenShift. Cela peut entraîner des erreurs de permissions telles que :

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

Pour résoudre ce problème, définissez la variable d'environnement `HF_HOME` sur un emplacement accessible en écriture. Vous pouvez utiliser `/var/tmp/huggingface` ou tout autre répertoire accessible en écriture par le conteneur.

Vous pouvez le configurer de l'une des manières suivantes :

- Ajoutez à votre `values.yaml` :

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- Ou incluez dans votre commande de mise à niveau Helm :

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

Cette configuration garantit que l'AI Gateway peut correctement mettre en cache les modèles HuggingFace tout en respectant les contraintes de sécurité d'OpenShift. Le répertoire exact que vous choisissez peut dépendre de votre configuration OpenShift spécifique et de vos politiques de sécurité.

### Cache du tokenizer masqué par un montage de volume {#tokenizer-cache-shadowed-by-a-volume-mount}

Les fichiers de tokenizer précachés dans l'image de l'AI Gateway peuvent être masqués par un montage de volume si :

- Les requêtes de complétion de code renvoient une erreur `500`.
- Les journaux de l'AI Gateway affichent une `OSError` depuis `transformers/utils/hub.py` tentant de télécharger `Salesforce/codegen2-16B` depuis `huggingface.co`.

L'image de l'AI Gateway auto-hébergé (`self-hosted-vX.Y.Z-ee`) définit `HF_HUB_OFFLINE=true` et précache le tokenizer lors de la compilation, de sorte qu'aucun accès réseau à `huggingface.co` ne devrait se produire à l'exécution. Si un accès réseau se produit, un répertoire vide dans vos valeurs Helm pourrait être monté sur `/home/aigateway/.hf`, écrasant les fichiers mis en cache.

N'essayez pas de résoudre ce problème en accordant un accès sortant à `huggingface.co`. Au lieu de cela, pour diagnostiquer le problème, exécutez ce qui suit dans le pod de l'AI Gateway :

```shell
ls -la /home/aigateway/.hf/hub/ 2>/dev/null || echo "NO_CACHE_DIR"
env | grep -E '^(HF_|TRANSFORMERS_)'
```

Si le répertoire de cache est manquant ou vide, procédez comme suit :

1. Vérifiez votre `values.yaml` pour tout `volumeMounts` ciblant `/home/aigateway/.hf` ou le chemin défini par `HF_HOME`.
1. Supprimez ou remappez le montage vers un répertoire qui ne chevauche pas le cache intégré de l'image.

### Erreur de certificat auto-signé {#self-signed-certificate-error}

Une erreur `[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain` est consignée par l'AI Gateway lorsque celui-ci tente de se connecter à une instance GitLab ou à un point de terminaison de modèle en utilisant soit un certificat signé par une autorité de certification (CA) personnalisée, soit un certificat auto-signé.

Pour résoudre ce problème, consultez [Se connecter à une instance GitLab ou à un point de terminaison de modèle avec un certificat SSL auto-signé](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate).

### Échec de la création du jeton {#token-creation-failed}

Si vous rencontrez une erreur `Token creation failed` lors de l'utilisation de fonctionnalités telles que Duo Chat, les variables d'environnement `AIGW_SELF_SIGNED_JWT__SIGNING_KEY` et `AIGW_SELF_SIGNED_JWT__VALIDATION_KEY` ne sont peut-être pas définies sur l'AI Gateway.

Ces clés sont requises pour que l'AI Gateway émette des JWT utilisateur de courte durée. Sans ces clés, l'AI Gateway ne peut pas signer les jetons, ce qui provoque une erreur de désérialisation JWK.

Pour résoudre ce problème :

1. Générez les clés requises :

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   ```

1. Ajoutez les clés à votre conteneur de l'AI Gateway en les transmettant comme variables d'environnement :

   ```shell
   -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
   -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)"
   ```

1. Redémarrez le conteneur de l'AI Gateway.

### Erreurs de certificat SSL lors du chargement de fichiers PEM {#ssl-certificate-errors-when-loading-pem-files}

Si vous obtenez une erreur indiquant `JWKError` lors du chargement du fichier PEM dans le conteneur Docker, vous devrez peut-être résoudre une erreur de certificat SSL.

Pour corriger ce problème, utilisez les variables d'environnement suivantes pour définir le chemin du bundle de certificats approprié dans le conteneur Docker :

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

Remplacez `/path/to/ca-bundle.pem` par le chemin vers votre bundle de certificats.
