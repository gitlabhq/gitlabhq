---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# PlantUML & GitLab

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/8537) in GitLab 8.16.

When [PlantUML](https://plantuml.com) integration is enabled and configured in
GitLab you can create diagrams in AsciiDoc and Markdown documents
created in snippets, wikis, and repositories.

## PlantUML Server

Before you can enable PlantUML in GitLab; set up your own PlantUML
server to generate the diagrams.

### Docker

With Docker, you can just run a container like this:

```shell
docker run -d --name plantuml -p 8080:8080 plantuml/plantuml-server:tomcat
```

The **PlantUML URL** is the hostname of the server running the container.

When running GitLab in Docker, it must have access to the PlantUML container.
You can achieve that by using [Docker Compose](https://docs.docker.com/compose/).
A basic `docker-compose.yml` file could contain:

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

In this scenario, PlantUML is accessible to GitLab at the URL
`http://plantuml:8080/`.

### Debian/Ubuntu

You can also install and configure a PlantUML server in Debian/Ubuntu distributions using Tomcat.

First you need to create a `plantuml.war` file from the source code:

```shell
sudo apt-get install graphviz openjdk-8-jdk git-core maven
git clone https://github.com/plantuml/plantuml-server.git
cd plantuml-server
mvn package
```

The above sequence of commands generates a `.war` file you can deploy with Tomcat:

```shell
sudo apt-get install tomcat8
sudo cp target/plantuml.war /var/lib/tomcat8/webapps/plantuml.war
sudo chown tomcat8:tomcat8 /var/lib/tomcat8/webapps/plantuml.war
sudo service tomcat8 restart
```

After the Tomcat service restarts, the PlantUML service is ready and
listening for requests on port 8080:

```plaintext
http://localhost:8080/plantuml
```

To change these defaults, edit the `/etc/tomcat8/server.xml` file.

NOTE:
The default URL is different when using this approach. The Docker-based image
makes the service available at the root URL, with no relative path. Adjust
the configuration below accordingly.

### Making local PlantUML accessible using custom GitLab setup

The PlantUML server runs locally on your server, so it is not accessible
externally by default. As such, it is necessary to catch external PlantUML
calls and redirect them to the local server.

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

```shell
sudo gitlab-ctl reconfigure
```

Note that the redirection through GitLab must be configured
when running [GitLab with TLS](https://docs.gitlab.com/omnibus/settings/ssl.html)
due to PlantUML's use of the insecure HTTP protocol. Newer browsers such
as [Google Chrome 86+](https://www.chromestatus.com/feature/4926989725073408)
do not load insecure HTTP resources on a page served over HTTPS.

### Security

PlantUML has features that allow fetching network resources.

```plaintext
@startuml
start
    ' ...
    !include http://localhost/
stop;
@enduml
```

**If you self-host the PlantUML server, network controls should be put in place to isolate it.**

## GitLab

You need to enable PlantUML integration from Settings under Admin Area. To do
that, sign in with an Administrator account, and then do following:

1. In GitLab, go to **Admin Area > Settings > General**.
1. Expand the **PlantUML** section.
1. Select the **Enable PlantUML** check box.
1. Set the PlantUML instance as `https://gitlab.example.com/-/plantuml/`.

NOTE:
If you are using a PlantUML server running v1.2020.9 and
above (for example, [plantuml.com](https://plantuml.com)), set the `PLANTUML_ENCODING`
environment variable to enable the `deflate` compression. On Omnibus GitLab,
this can be set in `/etc/gitlab.rb`:

```ruby
gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
```

From GitLab 13.1 and later, PlantUML integration now
[requires a header prefix in the URL](https://github.com/plantuml/plantuml/issues/117#issuecomment-6235450160)
to distinguish different encoding types.

## Creating Diagrams

With PlantUML integration enabled and configured, we can start adding diagrams to
our AsciiDoc snippets, wikis, and repositories using delimited blocks:

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

   You can also use the `uml::` directive for compatibility with
   [`sphinxcontrib-plantuml`](https://pypi.org/project/sphinxcontrib-plantuml/),
   but GitLab only supports the `caption` option.

The above blocks are converted to an HTML image tag with source pointing to the
PlantUML instance. If the PlantUML server is correctly configured, this should
render a nice diagram instead of the block:

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

Inside the block you can add any of the diagrams PlantUML supports, such as:

- [Sequence](https://plantuml.com/sequence-diagram)
- [Use Case](https://plantuml.com/use-case-diagram)
- [Class](https://plantuml.com/class-diagram)
- [Activity](https://plantuml.com/activity-diagram-legacy)
- [Component](https://plantuml.com/component-diagram)
- [State](https://plantuml.com/state-diagram),
- [Object](https://plantuml.com/object-diagram)

You do not need to use the PlantUML
diagram delimiters `@startuml`/`@enduml`, as these are replaced by the AsciiDoc `plantuml` block.

Some parameters can be added to the AsciiDoc block definition:

- `format`: Can be either `png` or `svg`. Note that `svg` is not supported by
  all browsers so use with care. The default is `png`.
- `id`: A CSS ID added to the diagram HTML tag.
- `width`: Width attribute added to the image tag.
- `height`: Height attribute added to the image tag.

Markdown does not support any parameters and always uses PNG format.
