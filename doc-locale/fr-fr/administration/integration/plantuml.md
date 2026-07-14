---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurer l'intégration de PlantUML avec GitLab Self-Managed."
title: PlantUML
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez l'intégration [PlantUML](https://plantuml.com) pour créer des diagrammes dans des extraits, des wikis et des dépôts. GitLab.com s'intègre avec PlantUML pour tous les utilisateurs et ne nécessite aucune configuration supplémentaire.

Pour configurer l'intégration sur votre instance GitLab Self-Managed, vous devez [configurer votre serveur PlantUML](#configure-your-plantuml-server).

Une fois l'intégration terminée, PlantUML convertit les blocs `plantuml` en balise image HTML, avec la source pointant vers l'instance PlantUML. Les délimiteurs de diagramme PlantUML `@startuml`/`@enduml` ne sont pas requis car ils sont remplacés par le bloc `plantuml` :

- Fichiers Markdown avec l'extension `.md` :

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

  Pour les extensions supplémentaires acceptées, consultez le fichier [`languages.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/languages.yml#L3174).

- Fichiers AsciiDoc avec l'extension `.asciidoc`, `.adoc` ou `.asc` :

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  Bob->Alice : hello
  Alice -> Bob : hi
  ----
  ```

- reStructuredText :

  ```plaintext
  .. plantuml::
     :caption: Caption with **bold** and *italic*

     Bob -> Alice: hello
     Alice -> Bob: hi
  ```

   Bien que vous puissiez utiliser la directive `uml::` pour la compatibilité avec [`sphinxcontrib-plantuml`](https://pypi.org/project/sphinxcontrib-plantuml/), GitLab ne prend en charge que l'option `caption`.

Si le serveur PlantUML est correctement configuré, ces exemples devraient afficher un diagramme à la place du bloc de code :

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

Dans les blocs, ajoutez l'un des diagrammes pris en charge par PlantUML, par exemple :

- [Activité](https://plantuml.com/activity-diagram-legacy)
- [Classe](https://plantuml.com/class-diagram)
- [Composant](https://plantuml.com/component-diagram)
- [Objet](https://plantuml.com/object-diagram)
- [Séquence](https://plantuml.com/sequence-diagram)
- [État](https://plantuml.com/state-diagram)
- [Cas d'utilisation](https://plantuml.com/use-case-diagram)

Ajoutez des paramètres aux définitions de bloc :

- `id` : Un ID CSS ajouté à la balise HTML du diagramme.
- `width` : Attribut de largeur ajouté à la balise image.
- `height` : Attribut de hauteur ajouté à la balise image.

Markdown ne prend en charge aucun paramètre et utilise toujours le format PNG.

## Inclure des fichiers de diagramme {#include-diagram-files}

Pour inclure ou intégrer un diagramme PlantUML à partir de fichiers séparés dans le dépôt, utilisez la directive `include`. Utilisez ceci pour maintenir des diagrammes complexes dans des fichiers dédiés ou pour réutiliser des diagrammes. Par exemple :

- Markdown :

  ````markdown
  ```plantuml
  ::include{file=diagram.puml}
  ```
  ````

- AsciiDoc :

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  include::diagram.puml[]
  ----
  ```

> [!note]
> La directive `::include` ne se résout qu'après que le fichier a été commité dans le dépôt. L'aperçu de l'éditeur Markdown ne rend pas les fichiers inclus. Pour vérifier que le diagramme s'affiche correctement, commitez le fichier et consultez-le dans le navigateur de fichiers du dépôt.

## Configurer votre serveur PlantUML {#configure-your-plantuml-server}

Avant de pouvoir activer PlantUML dans GitLab, configurez votre propre serveur PlantUML pour générer les diagrammes :

- [Docker](#docker) (recommandé)
- [Debian/Ubuntu](#debianubuntu)

### Docker {#docker}

Pour exécuter un conteneur PlantUML dans Docker, exécutez cette commande :

```shell
docker run -d --name plantuml -p 8005:8080 plantuml/plantuml-server:tomcat
```

L'**URL de PlantUML** est le nom d'hôte du serveur exécutant le conteneur.

Lorsque vous exécutez GitLab dans Docker, il doit avoir accès au conteneur PlantUML. Pour ce faire, utilisez [Docker Compose](https://docs.docker.com/compose/). Dans ce fichier `docker-compose.yml` de base, PlantUML est accessible à GitLab via l'URL `http://plantuml:8080/` :

```yaml
services:
  gitlab:
    image: 'gitlab/gitlab-ee:18.9.1-ee.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    rewrite ^/-/plantuml/(.*) /$1 break;\n proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
    ports:
     - "8005:8080"
```

Ensuite, vous pouvez :

1. [Configurer l'accès local à PlantUML](#configure-local-plantuml-access)
1. [Vérifier que l'installation de PlantUML](#verify-the-plantuml-installation) a réussi

### Debian/Ubuntu {#debianubuntu}

Vous pouvez installer et configurer un serveur PlantUML dans les distributions Debian/Ubuntu à l'aide de Tomcat ou Jetty. Les instructions ci-dessous concernent Tomcat.

Prérequis :

- JRE/JDK version 11 ou ultérieure.
- (Recommandé) Jetty version 11 ou ultérieure.
- (Recommandé) Tomcat version 10 ou ultérieure.

#### Installation {#installation}

PlantUML recommande d'installer Tomcat 10.1 ou une version ultérieure. La portée de cette page comprend uniquement la configuration d'un serveur Tomcat de base. Pour des configurations plus adaptées à la production, consultez la [documentation Tomcat](https://tomcat.apache.org/tomcat-10.1-doc/index.html).

1. Installer JDK/JRE 11 :

   ```shell
   sudo apt update
   sudo apt install default-jre-headless graphviz git
   ```

1. Ajouter un utilisateur pour Tomcat :

   ```shell
   sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
   ```

1. Installer et configurer Tomcat 10.1 :

   ```shell
   wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.33/bin/apache-tomcat-10.1.33.tar.gz -P /tmp
   sudo tar xzvf /tmp/apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
   sudo chown -R tomcat:tomcat /opt/tomcat/
   sudo chmod -R u+x /opt/tomcat/bin
   ```

1. Créer un service systemd. Modifiez le fichier `/etc/systemd/system/tomcat.service` et ajoutez :

   ```shell
   [Unit]
   Description=Tomcat
   After=network.target

   [Service]
   Type=forking

   User=tomcat
   Group=tomcat

   Environment="JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64"
   Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
   Environment="CATALINA_BASE=/opt/tomcat"
   Environment="CATALINA_HOME=/opt/tomcat"
   Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
   Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

   ExecStart=/opt/tomcat/bin/startup.sh
   ExecStop=/opt/tomcat/bin/shutdown.sh

   RestartSec=10
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

   `JAVA_HOME` doit être le même chemin que celui indiqué dans `sudo update-java-alternatives -l`.

1. Pour configurer les ports, modifiez votre `/opt/tomcat/conf/server.xml` et choisissez vos ports. Recommandé :

   - Changer le port d'arrêt de Tomcat de `8005` à `8006`
   - Utiliser le port `8005` pour le point de terminaison HTTP de Tomcat. Le port par défaut `8080` doit être évité, car [Puma](../operations/puma.md) écoute sur le port `8080` pour les métriques.

   ```diff
   - <Server port="8006" shutdown="SHUTDOWN">
   + <Server port="8005" shutdown="SHUTDOWN">

   - <Connector port="8005" protocol="HTTP/1.1"
   + <Connector port="8080" protocol="HTTP/1.1"
   ```

1. Recharger et démarrer Tomcat :

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start tomcat
   sudo systemctl status tomcat
   sudo systemctl enable tomcat
   ```

   Le processus Java doit écouter sur ces ports :

   ```shell
   root@gitlab-omnibus:/plantuml-server# ❯ ss -plnt | grep java
   LISTEN   0        1          [::ffff:127.0.0.1]:8006                   *:*       users:(("java",pid=27338,fd=52))
   LISTEN   0        100                         *:8005                   *:*       users:(("java",pid=27338,fd=43))
   ```

1. Installer PlantUML et copier le fichier `.war` :

   Utilisez la [dernière release](https://github.com/plantuml/plantuml-server/releases) de `plantuml-jsp` (par exemple : `plantuml-jsp-v1.2024.8.war`). Pour le contexte, consultez le [ticket 265](https://github.com/plantuml/plantuml-server/issues/265).

   ```shell
   wget -P /tmp https://github.com/plantuml/plantuml-server/releases/download/v1.2024.8/plantuml-jsp-v1.2024.8.war
   sudo cp /tmp/plantuml-jsp-v1.2024.8.war /opt/tomcat/webapps/plantuml.war
   sudo chown tomcat:tomcat /opt/tomcat/webapps/plantuml.war
   sudo systemctl restart tomcat
   ```

Le service Tomcat devrait redémarrer. Une fois le redémarrage terminé, l'intégration PlantUML est prête et écoute les requêtes sur le port `8005` : `http://localhost:8005/plantuml`.

Pour modifier les paramètres par défaut de Tomcat, modifiez le fichier `/opt/tomcat/conf/server.xml`.

> [!note]
> L'URL par défaut est différente lorsque vous utilisez cette approche. L'image basée sur Docker rend le service disponible à l'URL racine, sans chemin relatif. Ajustez la configuration ci-dessous en conséquence.

Ensuite, vous pouvez :

1. [Configurer l'accès local à PlantUML](#configure-local-plantuml-access). Assurez-vous que le port `proxy_pass` configuré dans le lien correspond au port Connector dans `server.xml`.
1. [Vérifier que l'installation de PlantUML](#verify-the-plantuml-installation) a réussi.

### Configurer l'accès local à PlantUML {#configure-local-plantuml-access}

Le serveur PlantUML s'exécute localement sur votre serveur et n'est donc pas accessible de l'extérieur par défaut. Votre serveur doit intercepter les appels PlantUML externes vers `https://gitlab.example.com/-/plantuml/` et les rediriger vers le serveur PlantUML local. Selon votre configuration, l'URL est l'une des suivantes :

- `http://plantuml:8080/`
- `http://localhost:8080/plantuml/`
- `http://plantuml:8005/`
- `http://localhost:8005/plantuml/`

Si vous exécutez [GitLab avec TLS](https://docs.gitlab.com/omnibus/settings/ssl/), vous devez configurer cette redirection, car PlantUML utilise le protocole HTTP non sécurisé. Les navigateurs récents ne chargent pas les ressources HTTP non sécurisées sur les pages servies via HTTPS.

#### Utiliser le NGINX GitLab intégré {#use-bundled-gitlab-nginx}

Si vous pouvez modifier `/etc/gitlab/gitlab.rb`, configurez le NGINX intégré pour gérer la redirection :

1. Ajoutez la ligne suivante dans `/etc/gitlab/gitlab.rb`, selon votre méthode de configuration :

   ```ruby
   # Docker install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"

   # Debian/Ubuntu install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://localhost:8005/plantuml; \n}\n"
   ```

1. Pour activer les modifications, exécutez la commande suivante :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### Utiliser un serveur PlantUML HTTPS {#use-https-plantuml-server}

Si vous ne pouvez pas modifier le fichier `gitlab.rb`, configurez votre serveur PlantUML pour utiliser directement HTTPS. Cette méthode est recommandée pour les instances GitLab Dedicated.

Cette configuration utilise NGINX pour gérer la terminaison SSL et transmettre les requêtes au conteneur PlantUML. Vous pouvez également utiliser des équilibreurs de charge basés sur le cloud, tels que AWS Application Load Balancer (ALB), pour la terminaison SSL.

1. Créez un fichier `nginx.conf` :

   ```nginx
   events {
       worker_connections 1024;
   }

   http {
       server {
           listen 443 ssl;
           server_name _;
           ssl_certificate /etc/nginx/ssl/plantuml.crt;
           ssl_certificate_key /etc/nginx/ssl/plantuml.key;
           location / {
               proxy_pass http://plantuml:8080;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_set_header X-Forwarded-Proto $scheme;
           }
       }
   }
   ```

1. Ajoutez les fichiers `plantuml.crt` et `plantuml.key` dans un répertoire `ssl`.
1. Configurez le fichier `docker-compose.yml` :

   ```yaml
   version: '3.8'

   services:
     plantuml:
       image: plantuml/plantuml-server:tomcat
       container_name: plantuml
       networks:
         - plantuml-net

     plantuml-ssl:
       image: nginx
       container_name: plantuml-ssl
       ports:
         - "8443:443"
       volumes:
         - ./nginx.conf:/etc/nginx/nginx.conf:ro
         - ./ssl:/etc/nginx/ssl:ro
       depends_on:
         - plantuml
       networks:
         - plantuml-net

   networks:
     plantuml-net:
       driver: bridge
   ```

1. Démarrez votre serveur PlantUML avec `docker-compose up`.
1. [Activez l'intégration PlantUML](#enable-plantuml-integration) avec l'URL `https://your-server:8443`.

### Vérifier l'installation de PlantUML {#verify-the-plantuml-installation}

Pour vérifier que l'installation a réussi :

1. Testez le serveur PlantUML directement :

   ```shell
   # Docker install
   curl --location --verbose "http://localhost:8005/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"

   # Debian/Ubuntu install
   curl --location --verbose "http://localhost:8005/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
   ```

   Vous devriez recevoir une sortie SVG contenant le texte `hello`.

1. Testez que GitLab peut accéder à PlantUML via NGINX en visitant :

   ```plaintext
   http://gitlab.example.com/-/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000
   ```

   Remplacez `gitlab.example.com` par l'URL de votre instance GitLab. Vous devriez voir un diagramme PlantUML rendu affichant `hello`.

   ```plaintext
   Bob -> Alice : hello
   ```

### Configurer la sécurité de PlantUML {#configure-plantuml-security}

PlantUML dispose de fonctionnalités permettant de récupérer des ressources réseau. Si vous hébergez vous-même le serveur PlantUML, mettez en place des contrôles réseau pour l'isoler. Par exemple, utilisez les [profils de sécurité](https://plantuml.com/security) de PlantUML.

```plaintext
@startuml
start
    ' ...
    !include http://localhost/
stop;
@enduml
```

#### Sécuriser la sortie des diagrammes SVG PlantUML {#secure-plantuml-svg-diagram-output}

Lors de la génération de diagrammes PlantUML au format SVG, configurez votre serveur pour une sécurité renforcée. Désactivez la route de sortie SVG dans votre configuration NGINX pour éviter d'éventuels problèmes de sécurité.

Pour désactiver la route de sortie SVG, ajoutez cette configuration à votre serveur NGINX hébergeant le service PlantUML :

```nginx
location ~ ^/-/plantuml/svg/ {
    return 403;
}
```

Cette configuration empêche l'exécution dans les navigateurs d'un code de diagramme potentiellement malveillant.

## Activer l'intégration PlantUML {#enable-plantuml-integration}

Après avoir configuré votre serveur PlantUML local, vous êtes prêt à activer l'intégration PlantUML :

1. Connectez-vous à GitLab en tant qu'utilisateur [Administrateur](../../user/permissions.md).
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, accédez à **Paramètres** > **Général** et développez la section **PlantUML**.
1. Cochez la case **Activer PlantUML**.
1. Définissez l'instance PlantUML sur `https://gitlab.example.com/-/plantuml/`, puis sélectionnez **Sauvegarder les modifications**.

Pour empêcher les navigateurs d'envoyer le contenu des diagrammes au service PlantUML externe, utilisez le [proxy de diagramme](diagram_proxy.md).

Selon vos numéros de version de PlantUML et de GitLab, vous devrez peut-être également effectuer ces étapes :

- Pour les serveurs PlantUML exécutant la version v1.2020.9 ou ultérieure, tels que [plantuml.com](https://plantuml.com), vous devez définir la variable d'environnement `PLANTUML_ENCODING` pour activer la compression `deflate`. Dans les installations de packages Linux, vous pouvez définir cette valeur dans `/etc/gitlab/gitlab.rb` avec cette commande :

  ```ruby
  gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
  ```

  Dans le chart Helm de GitLab, vous pouvez le définir en ajoutant une variable à la section [global.extraEnv](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/charts/globals.md#extraenv), comme suit :

  ```yaml
  global:
  extraEnv:
    PLANTUML_ENCODING: deflate
  ```

- `deflate` est le type d'encodage par défaut pour PlantUML. Pour utiliser un type d'encodage différent, l'intégration PlantUML [nécessite un préfixe d'en-tête dans l'URL](https://plantuml.com/text-encoding) pour distinguer les différents types d'encodage.

## Dépannage {#troubleshooting}

### L'URL du diagramme rendu reste la même après la mise à jour {#rendered-diagram-url-remains-the-same-after-update}

Les diagrammes rendus sont mis en cache. Pour voir les mises à jour, essayez ces étapes :

- Si le diagramme se trouve dans un fichier Markdown, apportez une petite modification au fichier Markdown et commitez-le. Cela déclenche un nouveau rendu.
- [Invalidez le cache Markdown](../invalidate_markdown_cache.md#invalidate-the-cache) pour forcer l'effacement de tout Markdown mis en cache dans la base de données ou Redis.

Si vous ne voyez toujours pas l'URL mise à jour, vérifiez les points suivants :

- Assurez-vous que le serveur PlantUML est accessible depuis votre instance GitLab.
- Vérifiez que l'intégration PlantUML est activée dans vos paramètres GitLab.
- Consultez les journaux GitLab pour les erreurs liées au rendu PlantUML.
- [Videz votre cache Redis GitLab](../raketasks/maintenance.md#clear-redis-cache).

### Erreur `404` lors de l'ouverture de la page PlantUML dans le navigateur {#404-error-when-opening-the-plantuml-page-in-the-browser}

Vous pourriez obtenir une erreur `404` en visitant `https://gitlab.example.com/-/plantuml/`, lorsque le serveur PlantUML est configuré [sous Debian ou Ubuntu](#debianubuntu).

Cela peut se produire même lorsque l'intégration fonctionne. Cela n'indique pas nécessairement un problème avec votre serveur PlantUML ou votre configuration.

Pour confirmer si PlantUML fonctionne correctement, vous pouvez [vérifier l'installation de PlantUML](#verify-the-plantuml-installation).
