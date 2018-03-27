# PlantUML & GitLab

> [Introduced][ce-8537] in GitLab 8.16.

When [PlantUML](http://plantuml.com) integration is enabled and configured in
GitLab we are able to create simple diagrams in AsciiDoc and Markdown documents
created in snippets, wikis, and repos.

## PlantUML Server

Before you can enable PlantUML in GitLab; you need to set up your own PlantUML
server that will generate the diagrams.

### Docker

With Docker, you can just run a container like this:

`docker run -d --name plantuml -p 8080:8080 plantuml/plantuml-server:tomcat`

The **PlantUML URL** will be the hostname of the server running the container.

### Debian/Ubuntu

Installing and configuring your
own PlantUML server is easy in Debian/Ubuntu distributions using Tomcat.

First you need to create a `plantuml.war` file from the source code:

```
sudo apt-get install graphviz openjdk-7-jdk git-core maven
git clone https://github.com/plantuml/plantuml-server.git
cd plantuml-server
mvn package
```

The above sequence of commands will generate a WAR file that can be deployed
using Tomcat:

```
sudo apt-get install tomcat7
sudo cp target/plantuml.war /var/lib/tomcat7/webapps/plantuml.war
sudo chown tomcat7:tomcat7 /var/lib/tomcat7/webapps/plantuml.war
sudo service tomcat7 restart
```

Once the Tomcat service restarts the PlantUML service will be ready and
listening for requests on port 8080:

```
http://localhost:8080/plantuml
```

you can change these defaults by editing the `/etc/tomcat7/server.xml` file.


## GitLab

You need to enable PlantUML integration from Settings under Admin Area. To do
that, login with an Admin account and do following:

 - in GitLab go to **Admin Area** and then **Settings**
 - scroll to bottom of the page until PlantUML section
 - check **Enable PlantUML** checkbox
 - set the PlantUML instance as **PlantUML URL**

## Creating Diagrams

With PlantUML integration enabled and configured, we can start adding diagrams to
our AsciiDoc snippets, wikis and repos using delimited blocks:

- **Markdown**

    <pre>
    ```plantuml
    Bob -> Alice : hello
    Alice -> Bob : Go Away
    ```
    </pre>

- **AsciiDoc**

    <pre>
    [plantuml, format="png", id="myDiagram", width="200px"]
    --
    Bob->Alice : hello
    Alice -> Bob : Go Away
    --
    </pre>

- **reStructuredText**

    <pre>
    .. plantuml::
       :caption: Caption with **bold** and *italic*

       Bob -> Alice: hello
       Alice -> Bob: Go Away
    </pre>

    You can also use the `uml::` directive for compatibility with [sphinxcontrib-plantuml](https://pypi.python.org/pypi/sphinxcontrib-plantuml), but please note that we currently only support the `caption` option.

The above blocks will be converted to an HTML img tag with source pointing to the
PlantUML instance. If the PlantUML server is correctly configured, this should
render a nice diagram instead of the block:

![PlantUML Integration](../img/integration/plantuml-example.png)

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

[ce-8537]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8537
