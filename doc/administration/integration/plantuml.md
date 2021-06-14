---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# PlantUML and GitLab **(FREE)**

When [PlantUML](https://plantuml.com) integration is enabled and configured in
GitLab, you can create diagrams in snippets, wikis, and repositories. To set up
the integration, you must:

1. [Configure your PlantUML server](#configure-your-plantuml-server).
1. [Configure local PlantUML access](#configure-local-plantuml-access).
1. [Configure PlantUML security](#configure-plantuml-security).
1. [Enable the integration](#enable-plantuml-integration).

After completing the integration, PlantUML converts `plantuml`
blocks to an HTML image tag, with the source pointing to the PlantUML instance. The PlantUML
diagram delimiters `@startuml`/`@enduml` aren't required, as these are replaced
by the `plantuml` block:

- **Markdown**

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

- **AsciiDoc**

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

- `format`: Can be either `png` (default) or `svg`. Use `svg` with care, as it's
  not supported by all browsers, and isn't supported by Markdown.
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
docker run -d --name plantuml -p 8080:8080 plantuml/plantuml-server:tomcat
```

The **PlantUML URL** is the hostname of the server running the container.

When running GitLab in Docker, it must have access to the PlantUML container.
To achieve that, use [Docker Compose](https://docs.docker.com/compose/).
In this basic `docker-compose.yml` file, PlantUML is accessible to GitLab at the URL
`http://plantuml:8080/`:

```yaml
version: "3"
services:
  gitlab:
    image: 'gitlab/gitlab-ee:12.2.5-ee.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
```

### Debian/Ubuntu

You can install and configure a PlantUML server in Debian/Ubuntu distributions
using Tomcat:

1. Run these commands to create a `plantuml.war` file from the source code:

   ```shell
   sudo apt-get install graphviz openjdk-8-jdk git-core maven
   git clone https://github.com/plantuml/plantuml-server.git
   cd plantuml-server
   mvn package
   ```

1. Deploy the `.war` file from the previous step with these commands:

   ```shell
   sudo apt-get install tomcat8
   sudo cp target/plantuml.war /var/lib/tomcat8/webapps/plantuml.war
   sudo chown tomcat8:tomcat8 /var/lib/tomcat8/webapps/plantuml.war
   sudo service tomcat8 restart
   ```

The Tomcat service should restart. After the restart is complete, the
PlantUML service is ready and listening for requests on port 8080:
`http://localhost:8080/plantuml`

To change these defaults, edit the `/etc/tomcat8/server.xml` file.

NOTE:
The default URL is different when using this approach. The Docker-based image
makes the service available at the root URL, with no relative path. Adjust
the configuration below accordingly.

## Configure local PlantUML access

The PlantUML server runs locally on your server, so it can't be accessed
externally by default. Your server must catch external PlantUML
calls to `https://gitlab.example.com/-/plantuml/` and redirect them to the
local PlantUML server. Depending on your setup, the URL is either of the
following:

- `http://plantuml:8080/`
- `http://localhost:8080/plantuml/`

If you're running [GitLab with TLS](https://docs.gitlab.com/omnibus/settings/ssl.html)
you must configure this redirection, because PlantUML uses the insecure HTTP protocol.
Newer browsers such as [Google Chrome 86+](https://www.chromestatus.com/feature/4926989725073408)
don't load insecure HTTP resources on pages served over HTTPS.

To enable this redirection:

1. Add the following line in `/etc/gitlab/gitlab.rb`, depending on your setup method:

   ```ruby
   # Docker deployment
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

   # Built from source
   nginx['custom_gitlab_server_config'] = "location /-/plantuml { \n rewrite ^/-/(plantuml.*) /$1 break;\n proxy_cache off; \n proxy_pass http://localhost:8080/plantuml; \n}\n"
   ```

1. To activate the changes, run the following command:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Configure PlantUML security

PlantUML has features that allow fetching network resources. If you self-host the
PlantUML server, put network controls in place to isolate it.

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
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, go to **Settings > General** and expand the **PlantUML** section.
1. Select the **Enable PlantUML** check box.
1. Set the PlantUML instance as `https://gitlab.example.com/-/plantuml/`,
   and click **Save changes**.

Depending on your PlantUML and GitLab version numbers, you may also need to take
these steps:

- For PlantUML servers running v1.2020.9 and above, such as [plantuml.com](https://plantuml.com),
  you must set the `PLANTUML_ENCODING` environment variable to enable the `deflate`
  compression. In Omnibus GitLab, you can set this value in `/etc/gitlab.rb` with
  this command:

  ```ruby
   gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
   ```

- For GitLab versions 13.1 and later, PlantUML integration now
  [requires a header prefix in the URL](https://github.com/plantuml/plantuml/issues/117#issuecomment-6235450160)
  to distinguish different encoding types.
