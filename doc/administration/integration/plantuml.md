---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure PlantUML integration with your self-managed GitLab instance."
---

# PlantUML

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

With the [PlantUML](https://plantuml.com) integration, you can create diagrams in snippets, wikis, and repositories.
This integration is enabled on GitLab.com for all SaaS users and does not require any additional configuration.

To set up the integration on a self-managed instance, you must [configure your PlantUML server](#configure-your-plantuml-server).

After completing the integration, PlantUML converts `plantuml`
blocks to an HTML image tag, with the source pointing to the PlantUML instance. The PlantUML
diagram delimiters `@startuml`/`@enduml` aren't required, as these are replaced
by the `plantuml` block:

- **Markdown** files with the extension `.md`:

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

  For additional acceptable extensions, review the
  [`languages.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/languages.yml#L3174) file.

- **AsciiDoc** files with the extension `.asciidoc`, `.adoc`, or `.asc`:

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  Bob->Alice : hello
  Alice -> Bob : hi
  ----
  ```

- **reStructuredText**

  ```plaintext
  .. plantuml::
     :caption: Caption with **bold** and *italic*

     Bob -> Alice: hello
     Alice -> Bob: hi
  ```

   Although you can use the `uml::` directive for compatibility with
   [`sphinxcontrib-plantuml`](https://pypi.org/project/sphinxcontrib-plantuml/),
   GitLab supports only the `caption` option.

If the PlantUML server is correctly configured, these examples should render a
diagram instead of the code block:

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

Inside the block you can add any of the diagrams PlantUML supports, such as:

- [Activity](https://plantuml.com/activity-diagram-legacy)
- [Class](https://plantuml.com/class-diagram)
- [Component](https://plantuml.com/component-diagram)
- [Object](https://plantuml.com/object-diagram)
- [Sequence](https://plantuml.com/sequence-diagram)
- [State](https://plantuml.com/state-diagram)
- [Use Case](https://plantuml.com/use-case-diagram)

You can add parameters to block definitions:

- `id`: A CSS ID added to the diagram HTML tag.
- `width`: Width attribute added to the image tag.
- `height`: Height attribute added to the image tag.

Markdown does not support any parameters, and always uses PNG format.

## Configure your PlantUML server

Before you can enable PlantUML in GitLab, set up your own PlantUML
server to generate the diagrams:

- [In Docker](#docker).
- [In Debian/Ubuntu](#debianubuntu).

### Docker

To run a PlantUML container in Docker, run this command:

```shell
docker run -d --name plantuml -p 8005:8080 plantuml/plantuml-server:tomcat
```

The **PlantUML URL** is the hostname of the server running the container.

When running GitLab in Docker, it must have access to the PlantUML container.
To achieve that, use [Docker Compose](https://docs.docker.com/compose/).
In this basic `docker-compose.yml` file, PlantUML is accessible to GitLab at the URL
`http://plantuml:8005/`:

```yaml
version: "3"
services:
  gitlab:
    image: 'gitlab/gitlab-ee:12.2.5-ee.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    rewrite ^/-/plantuml/(.*) /$1 break;\n proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
    ports:
     - "8005:8080"
```

#### Configure local PlantUML access

The PlantUML server runs locally on your server, so it can't be accessed
externally by default. Your server must catch external PlantUML
calls to `https://gitlab.example.com/-/plantuml/` and redirect them to the
local PlantUML server. Depending on your setup, the URL is either of the
following:

- `http://plantuml:8080/`
- `http://localhost:8080/plantuml/`
- `http://plantuml:8005/`
- `http://localhost:8005/plantuml/`

If you're running [GitLab with TLS](https://docs.gitlab.com/omnibus/settings/ssl/index.html)
you must configure this redirection, because PlantUML uses the insecure HTTP protocol.
Newer browsers such as [Google Chrome 86+](https://www.chromestatus.com/feature/4926989725073408)
don't load insecure HTTP resources on pages served over HTTPS.

To enable this redirection:

1. Add the following line in `/etc/gitlab/gitlab.rb`, depending on your setup method:

   ```ruby
   # Docker deployment
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"
   ```

1. To activate the changes, run the following command:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Debian/Ubuntu

You can install and configure a PlantUML server in Debian/Ubuntu distributions
using Tomcat or Jetty.

Prerequisites:

- JRE/JDK version 11 or later.
- (Recommended) Jetty version 11 or later.
- (Recommended) Tomcat version 10 or later.

#### Installation

PlantUML recommends to install Tomcat 10 or above. The scope of this page only
includes setting up a basic Tomcat server. For more production-ready configurations,
see the [Tomcat Documentation](https://tomcat.apache.org/tomcat-10.1-doc/index.html).

1. Install JDK/JRE 11:

   ```shell
   sudo apt update
   sudo apt-get install graphviz default-jdk git-core
   ```

1. Add a user for Tomcat:

   ```shell
   sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
   ```

1. Install and configure Tomcat 10:

   ```shell
   wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.15/bin/apache-tomcat-10.1.15.tar.gz -P /tmp
   sudo tar xzvf /tmp/apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
   sudo chown -R tomcat:tomcat /opt/tomcat/
   sudo chmod -R u+x /opt/tomcat/bin
   ```

1. Create a systemd service. Edit the `/etc/systemd/system/tomcat.service` file and add:

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

   `JAVA_HOME` should be the same path as seen in `sudo update-java-alternatives -l`.

1. To configure ports, edit your `/opt/tomcat/conf/server.xml` and choose your
   ports. Avoid using port `8080`, as [Puma](../operations/puma.md) listens on port `8080` for metrics.

   ```shell
   <Server port="8006" shutdown="SHUTDOWN">
   ...
       <Connector port="8005" protocol="HTTP/1.1"
   ...
   ```

1. Reload and start Tomcat:

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start tomcat
   sudo systemctl status tomcat
   sudo systemctl enable tomcat
   ```

   The Java process should be listening on these ports:

   ```shell
   root@gitlab-omnibus:/plantuml-server# netstat -plnt | grep java
   tcp6       0      0 127.0.0.1:8006          :::*                    LISTEN      14935/java
   tcp6       0      0 :::8005                 :::*                    LISTEN      14935/java
   ```

1. Modify your NGINX configuration in `/etc/gitlab/gitlab.rb`. Ensure the `proxy_pass` port matches the Connector port in `server.xml`:

   ```shell
   nginx['custom_gitlab_server_config'] = "location /-/plantuml {
       rewrite ^/-/(plantuml.*) /$1 break;
       proxy_set_header  HOST               $host;
       proxy_set_header  X-Forwarded-Host   $host;
       proxy_set_header  X-Forwarded-Proto  $scheme;
       proxy_cache off;
       proxy_pass http://localhost:8005/plantuml;
   }"
   ```

1. Reconfigure GitLab to read the new changes:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Install PlantUML and copy the `.war` file:

   Use the [latest release](https://github.com/plantuml/plantuml-server/releases) of plantuml-jsp (example: plantuml-jsp-v1.2023.12.war). For context, see [this issue](https://github.com/plantuml/plantuml-server/issues/265).

   ```shell
   wget -P /tmp https://github.com/plantuml/plantuml-server/releases/download/v1.2023.12/plantuml-jsp-v1.2023.12.war
   sudo cp /tmp/plantuml-jsp-v1.2023.12.war /opt/tomcat/webapps/plantuml.war
   sudo chown tomcat:tomcat /opt/tomcat/webapps/plantuml.war
   sudo systemctl restart tomcat
   ```

The Tomcat service should restart. After the restart is complete, the
PlantUML integration is ready and listening for requests on port `8005`:
`http://localhost:8005/plantuml`

To test if the PlantUML server is working, run `curl --location --verbose "http://localhost:8005/plantuml/"`.

To change the Tomcat defaults, edit the `/opt/tomcat/conf/server.xml` file.

NOTE:
The default URL is different when using this approach. The Docker-based image
makes the service available at the root URL, with no relative path. Adjust
the configuration below accordingly.

#### `404` error when opening the PlantUML page in the browser

You might get a `404` error when visiting `https://gitlab.example.com/-/plantuml/`, when the PlantUML
server is set up [in Debian or Ubuntu](#debianubuntu).

This can happen even when the integration is working.
It does not necessarily indicate a problem with your PlantUML server or configuration.

### Configure PlantUML security

PlantUML has features that allow fetching network resources. If you self-host the
PlantUML server, put network controls in place to isolate it.
For example, make use of PlantUML's [security profiles](https://plantuml.com/security).

```plaintext
@startuml
start
    ' ...
    !include http://localhost/
stop;
@enduml
```

## Enable PlantUML integration

After configuring your local PlantUML server, you're ready to enable the PlantUML integration:

1. Sign in to GitLab as an [Administrator](../../user/permissions.md) user.
1. On the left sidebar, at the bottom, select **Admin area**.
1. On the left sidebar, go to **Settings > General** and expand the **PlantUML** section.
1. Select the **Enable PlantUML** checkbox.
1. Set the PlantUML instance as `https://gitlab.example.com/-/plantuml/`,
   and select **Save changes**.

Depending on your PlantUML and GitLab version numbers, you may also need to take
these steps:

- For PlantUML servers running v1.2020.9 and later, such as [plantuml.com](https://plantuml.com),
  you must set the `PLANTUML_ENCODING` environment variable to enable the `deflate`
  compression. In Linux package installations, you can set this value in `/etc/gitlab/gitlab.rb` with
  this command:

  ```ruby
   gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
   ```

  In GitLab Helm chart, you can set it by adding a variable to the
  [global.extraEnv](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/charts/globals.md#extraenv)
  section, like this:

  ```yaml
  global:
  extraEnv:
    PLANTUML_ENCODING: deflate
  ```

- `deflate` is the default encoding type for PlantUML. To use a different encoding type, PlantUML integration
  [requires a header prefix in the URL](https://plantuml.com/text-encoding)
  to distinguish different encoding types.

## Troubleshooting PlantUML configuration

### Rendered diagram URL remains the same after update

Rendered diagrams are cached. To see the updates, try these steps:

- If the diagram is in a Markdown file, make a small change to the Markdown file, and commit it. This triggers a re-render.
- [Clear your GitLab cache](../raketasks/maintenance.md#clear-redis-cache).

If you're still not seeing the updated URL, check the following:

- Ensure the PlantUML server is accessible from your GitLab instance.
- Verify that the PlantUML integration is enabled in your GitLab settings.
- Check the GitLab logs for errors related to PlantUML rendering.
