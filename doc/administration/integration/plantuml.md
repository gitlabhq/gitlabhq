# PlantUML & GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/8537) in GitLab 8.16.

When [PlantUML](http://plantuml.com) integration is enabled and configured in
GitLab we are able to create simple diagrams in AsciiDoc and Markdown documents
created in snippets, wikis, and repos.

## PlantUML Server

Before you can enable PlantUML in GitLab; you need to set up your own PlantUML
server that will generate the diagrams.

### Docker

With Docker, you can just run a container like this:

```sh
docker run -d --name plantuml -p 8080:8080 plantuml/plantuml-server:tomcat
```

The **PlantUML URL** will be the hostname of the server running the container.

When running GitLab in Docker, it will need to have access to the PlantUML container.
The easiest way to achieve that is by using [Docker Compose](https://docs.docker.com/compose/).

A simple `docker-compose.yml` file would be:

```yaml
version: "3"
services:
  gitlab:
    image: 'gitlab/gitlab-ce:12.2.5-ce.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
```

In this scenario, PlantUML will be accessible for GitLab at the URL
`http://plantuml:8080/`.

### Debian/Ubuntu

Installing and configuring your
own PlantUML server is easy in Debian/Ubuntu distributions using Tomcat.

First you need to create a `plantuml.war` file from the source code:

```sh
sudo apt-get install graphviz openjdk-8-jdk git-core maven
git clone https://github.com/plantuml/plantuml-server.git
cd plantuml-server
mvn package
```

The above sequence of commands will generate a WAR file that can be deployed
using Tomcat:

```shell
sudo apt-get install tomcat8
sudo cp target/plantuml.war /var/lib/tomcat8/webapps/plantuml.war
sudo chown tomcat8:tomcat8 /var/lib/tomcat8/webapps/plantuml.war
sudo service tomcat8 restart
```

Once the Tomcat service restarts the PlantUML service will be ready and
listening for requests on port 8080:

```text
http://localhost:8080/plantuml
```

you can change these defaults by editing the `/etc/tomcat8/server.xml` file.

Note that the default URL is different than when using the Docker-based image,
where the service is available at the root of URL with no relative path. Adjust
the configuration below accordingly.

### Making local PlantUML accessible using custom GitLab setup

The PlantUML server runs locally on your server, so it is not accessible
externally. As such, it is necessary to catch external PlantUML calls and
redirect them to the local server.

The idea is to redirect each call to `https://gitlab.example.com/-/plantuml/`
to the local PlantUML server `http://plantuml:8080/` or `http://localhost:8080/plantuml/`, depending on your setup.

To enable the redirection, add the following line in `/etc/gitlab/gitlab.rb`:

```ruby
# Docker deployment
nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

# Built from source
nginx['custom_gitlab_server_config'] = "location /-/plantuml { \n rewrite ^/-/(plantuml.*) /$1 break;\n proxy_cache off; \n proxy_pass http://localhost:8080/plantuml; \n}\n"
```

To activate the changes, run the following command:

```sh
sudo gitlab-ctl reconfigure
```

## GitLab

You need to enable PlantUML integration from Settings under Admin Area. To do
that, login with an Admin account and do following:

- In GitLab, go to **Admin Area > Settings > Integrations**.
- Expand the **PlantUML** section.
- Check **Enable PlantUML** checkbox.
- Set the PlantUML instance as `https://gitlab.example.com/-/plantuml/`.

## Creating Diagrams

With PlantUML integration enabled and configured, we can start adding diagrams to
our AsciiDoc snippets, wikis and repos using delimited blocks:

- **Markdown**

  ~~~markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ~~~

- **AsciiDoc**

  ```text
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  Bob->Alice : hello
  Alice -> Bob : hi
  ----
  ```

- **reStructuredText**

  ```text
  .. plantuml::
     :caption: Caption with **bold** and *italic*

     Bob -> Alice: hello
     Alice -> Bob: hi
  ```

   You can also use the `uml::` directive for compatibility with [sphinxcontrib-plantuml](https://pypi.org/project/sphinxcontrib-plantuml/), but please note that we currently only support the `caption` option.

The above blocks will be converted to an HTML img tag with source pointing to the
PlantUML instance. If the PlantUML server is correctly configured, this should
render a nice diagram instead of the block:

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

Inside the block you can add any of the supported diagrams by PlantUML such as
[Sequence](http://plantuml.com/sequence-diagram), [Use Case](http://plantuml.com/use-case-diagram),
[Class](http://plantuml.com/class-diagram), [Activity](http://plantuml.com/activity-diagram-legacy),
[Component](http://plantuml.com/component-diagram), [State](http://plantuml.com/state-diagram),
and [Object](http://plantuml.com/object-diagram) diagrams. You do not need to use the PlantUML
diagram delimiters `@startuml`/`@enduml` as these are replaced by the AsciiDoc `plantuml` block.

Some parameters can be added to the AsciiDoc block definition:

- *format*: Can be either `png` or `svg`. Note that `svg` is not supported by
  all browsers so use with care. The default is `png`.
- *id*: A CSS id added to the diagram HTML tag.
- *width*: Width attribute added to the img tag.
- *height*: Height attribute added to the img tag.

Markdown does not support any parameters and will always use PNG format.
