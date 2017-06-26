> **Article [Type](../../development/writing_documentation.html#types-of-technical-articles):** tutorial ||
> **Level:** intermediary ||
> **Author:** [Fabio Busatto](https://gitlab.com/bikebilly) ||
> **Publication date:** AAAA/MM/DD

## Index

1. [Get a simple Maven application](#get-a-simple-maven-application)
1. [Configure Continuous Integration with `.gitlab-ci.yml`](#configure-continuous-integration-with-gitlab-ciyml)
1. [Set up Artifactory as the deployment repo](#set-up-artifactory-as-the-deployment-repo)
1. [Configure automatic deployment](#configure-automatic-deployment)

In this article, we're going to see how we can leverage the power of GitLab Continuous Integration features to compile and test a Maven application,
and finally deploy it to an Artifactory repository with just a very few lines of configuration.

Every time we change our sample application, GitLab checks that the new version is still bug free, and after merging to `master` branch it will automatically push the new package
to the remote Artifactory repository, making it ready to use.

## Get a simple Maven application

First of all, we need an application to work with: in this specific case we're going to make it simple, but it could be any Maven application.

For this article we'll use a Maven app that can be cloned at `https://gitlab.com/gitlab-examples/maven/simple-maven-app.git`, so let's login into our GitLab account and create a new project 
with `Import project from` -> `Repo by URL`.

This application is nothing more than a basic Hello World with a stub for a JUnit based test suite. It was created with the `maven-archetype-quickstart` Maven template.
The project structure is really simple, and we're mainly interested in these two resources:
- `pom.xml`: project object model (POM) file - here we've the configuration for our project
- `src/main/java/com/example/app/App.java`: source of our application - it prints "Hello World!" to stdout

## Configure Continuous Integration with `.gitlab-ci.yml`

Now that we've our application, we need to define stages that will build and test it automatically. In order to achieve this result, we create a file named `.gitlab-ci.yml` in the root of our git repository, once pushed this file will instruct the runner with all the commands needed.

Let's see the content of the file:

```yaml
image: maven:latest

cache:
  paths:
    - target/

build:
  stage: build
  script:
    - mvn compile

test:
  stage: test
  script:
    - mvn test
```
We want to use the latest Docker image publicly available for Maven, which already contains everything we need to perform our tasks. Caching the `target` folder, that is the location where our application will be created, is useful in order to speed up the process: Maven runs all its phases in a specific order, so executing `mvn test` will automatically run `mvn compile` if needed, but we want to improve performances caching everything that is already created in a previous step. Both `build` and `test` jobs leverage the `mvn` command to compile the application and to test it as defined in the test suite that is part of the repository.

If you're creating the file using the GitLab UI, you just have to commit directly into `master`. Otherwise, if you cloned locally your brand new project, commit and push to remote.

Done! We've now our changes in the GitLab repo, and a pipeline has already been started for this commit. Let's wait until the pipeline ends, and we should see something like the following text in the job output log.

```
Running com.example.app.AppTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.049 sec

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 13.165 s
[INFO] Finished at: 2017-06-26T14:26:43Z
[INFO] Final Memory: 17M/147M
[INFO] ------------------------------------------------------------------------
Creating cache default...
Created cache
Job succeeded
```

**Note**: the `mvn` command downloads a lot of files from the internet, so you'll see a lot of extra activity in the log.

## Set up Artifactory as the deployment repo
 
### Configure POM file

Next step is to setup our project to use Artifactory as its repository for artifacts deployment: in order to complete this, we need access to the Artifactory instance.
So, first of all let's select the `libs-release-local` repository in the `Set Me Up` section, and copy to clipboard the configuration snipped marked as `Deploy`. This is the "address" of our repo, and it is needed by Maven to push artifacts during the `deploy` stage.
Now let's go back to our project and edit the pom.xml file: we have to add the snipped we just copied from Artifactory into the project section, so we can paste it after the dependencies.
The final POM will look like this:
 
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example.app</groupId>
  <artifactId>maven-example-app</artifactId>
  <packaging>jar</packaging>
  <version>1.0</version>
  <name>maven-example-app</name>
  <url>http://maven.apache.org</url>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <distributionManagement>
    <repository>
      <id>central</id>
      <name>0072a36394cd-releases</name>
      <url>http://localhost:8081/artifactory/libs-release-local</url>
    </repository>
  </distributionManagement>
</project>
```

### Configure credentials for the repo
 
One last step is required to actully deploy artifacts to Artifactory: we need to configure credentials for our repo, and best practices want us to create an API key for this task, so we don't have to expose our account password.
Let's go back to Artifactory, edit the account settings and generate a new API key. For security reasons, we don't want to expose directly this key into the `.gitlab-ci.yml, so we're going to create secret variables REPO_USERNAME and REPO_PASSWORD containing the username and the key in our GitLab project settings.
 
[screenshot of secret variables window]
 
We must now include these credentials in the `~/.m2/settings.xml` file, so let's create a file named `.maven-settings.xml` in our project folder with the following content:
 
```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
  <servers>
    <server>
      <username>${REPO_USERNAME}</username>
      <password>${REPO_PASSWORD}</password>
      <id>central</id>
    </server>
  </servers>
</settings>
```

Note that `id` must have the same value as the related `id` field of the `repository` section in `pom.xml`.
 
## Configure automatic deployment
 
Time to change `.gitlab-ci.yml` and add the deploy stage! Maven has the perfect command for that, but it requires `settings.xml` to be in the correct folder, so we need to move it before executing `mvn deploy` command.
 
The complete file is now this:
 
```yaml
image: maven:latest
 
cache:
  paths:
    - target/
 
build:
  stage: build
  script:
    - mvn compile
 
test:
  stage: test
  script:
    - mvn test
 
deploy:
  stage: deploy
  script:
    - cp .maven-settings.xml ~/.m2/settings.xml
    - mvn deploy
  only:
    - master
```
We're ready to go! Every merge (or push) to master will now trigger the deployment to our Artifactory repository!