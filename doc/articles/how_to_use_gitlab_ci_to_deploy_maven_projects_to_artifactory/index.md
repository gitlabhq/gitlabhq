> **Article [Type](../../development/writing_documentation.html#types-of-technical-articles):** tutorial ||
> **Level:** intermediary ||
> **Author:** [Fabio Busatto](https://gitlab.com/bikebilly) ||
> **Publication date:** AAAA/MM/DD

## Index

- [Introduction](#introduction)

- [Create the simple Maven dependency](#create-the-simple-maven-dependency)
  - [Get the sources](#get-the-sources)
  - [Configure Artifactory deployment](#configure-artifactory-deployment)
  - [Configure GitLab Continuous Integration for `simple-maven-dep`](#configure-gitlab-continuous-integration-for-simple-maven-dep)

- [Create the main Maven application](#create-the-main-maven-application)
  - [Prepare the application](#prepare-the-application)
  - [Configure the Artifactory repository location](#configure-the-artifactory-repository-location)
  - [Configure GitLab Continuous Integration for `simple-maven-app`](#configure-gitlab-continuous-integration-for-simple-maven-app)

-  [Conclusion](#conclusion)

## Introduction

In this article, we're going to see how we can leverage the power of [GitLab Continuous Integration](https://about.gitlab.com/features/gitlab-ci-cd/) to build a [Maven](https://maven.apache.org/) project, deploy it to [Artifactory](https://www.jfrog.com/artifactory/) and then use it from another Maven application as a dependency.

We're going to create two different projects:
- `simple-maven-dep`: the app built and deployed to Artifactory (available at https://gitlab.com/gitlab-examples/maven/simple-maven-dep)
- `simple-maven-app`: the app using the previous one as a dependency (available at https://gitlab.com/gitlab-examples/maven/simple-maven-app)

We assume that we already have a GitLab account on [GitLab.com](https://gitlab.com/), and that we know the basic usage of CI.
We also assume that an Artifactory instance is available and reachable from the Internet, and that we've valid credentials to deploy on it.

## Create the simple Maven dependency

#### Get the sources

First of all, we need an application to work with: in this specific case we're going to make it simple, but it could be any Maven application. This will be our dependency we want to package and deploy to Artifactory, in order to be available to other projects.

For this article we'll use a Maven app that can be cloned from `https://gitlab.com/gitlab-examples/maven/simple-maven-dep.git`, so let's login into our GitLab account and create a new project 
with **Import project from ➔ Repo by URL**. Let's make it `public` so anyone can contribute!

This application is nothing more than a basic class with a stub for a JUnit based test suite.
It exposes a method called `hello` that accepts a string as input, and prints an hello message on the screen.

The project structure is really simple, and we're mainly interested in these two resources:
- `pom.xml`: project object model (POM) configuration file
- `src/main/java/com/example/dep/Dep.java`: source of our application

#### Configure Artifactory deployment

The application is ready to use, but we need some additional steps for deploying it to Artifactory:
1. login to Artifactory with your user's credentials
2. from the main screen, click on the `libs-release-local` item in the **Set Me Up** panel
3. copy to clipboard the configuration snippet under the **Deploy** paragraph
4. change the `url` value in order to have it configurable via secret variables

The snippet should look like this:

```xml
<distributionManagement>
  <repository>
    <id>central</id>
    <name>83d43b5afeb5-releases</name>
    <url>${env.MAVEN_REPO_URL}/libs-release-local</url>
  </repository>
</distributionManagement>
```

Now let's copy the snippet in the `pom.xml` file for our project, just after the `dependencies` section. Easy!

Another step we need to do before we can deploy our dependency to Artifactory is to configure authentication data. It is a simple task, but Maven requires it to stay in a file called `settings.xml` that has to be in the `.m2` subfolder in the user's homedir. Since we want to use GitLab Runner to automatically deploy the application, we should create the file in our project home and set a command line parameter in `.gitlab-ci.yml` to use our location instead of the default one.

For this scope, let's create a folder called `.m2` in the root of our repo. Inside we must create a file named `settings.xml` and copy the following text in it.

```xml
<settings xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd"
    xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <servers>
    <server>
      <id>central</id>
      <username>${env.MAVEN_REPO_USER}</username>
      <password>${env.MAVEN_REPO_KEY}</password>
    </server>
  </servers>
</settings>
```

>**Note**:
`username` and `password` will be replaced by the correct values using secret variables.

We should remember to commit all the changes to our repo!

#### Configure GitLab Continuous Integration for `simple-maven-dep`

Now it's time we set up GitLab CI to automatically build, test and deploy our dependency!  

First of all, we should remember that we need to setup some secret variable for making the deploy happen, so let's go in the **Settings ➔ Pipelines**
and add the following secret variables (replace them with your current values, of course):
- **MAVEN_REPO_URL**: `http://artifactory.example.com:8081/artifactory` (your Artifactory URL)
- **MAVEN_REPO_USER**: `gitlab` (your Artifactory username)
- **MAVEN_REPO_KEY**: `AKCp2WXr3G61Xjz1PLmYa3arm3yfBozPxSta4taP3SeNu2HPXYa7FhNYosnndFNNgoEds8BCS` (your Artifactory API Key)

Now it's time to define stages in our `.gitlab-ci.yml` file: once pushed to our repo it will instruct the GitLab Runner with all the needed commands.

Let's see the content of the file:

```yaml
image: maven:latest

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

cache:
  paths:
    - .m2/repository/
    - target/

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

deploy:
  stage: deploy
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  only:
    - master
```

We're going to use the latest Docker image publicly available for Maven, which already contains everything we need to perform our tasks.
Environment variables are set to instruct Maven to use the homedir of our repo instead of the user's home.
Caching the `.m2/repository` folder, where all the Maven files are stored, and the `target` folder, that is the location where our application will be created,
is useful in order to speed up the process: Maven runs all its phases in a sequential order, so executing `mvn test` will automatically run `mvn compile` if needed,
but we want to improve performances by caching everything that has been already created in a previous stage.
Both `build` and `test` jobs leverage the `mvn` command to compile the application and to test it as defined in the test suite that is part of the repository.

Deploy to Artifactory is done as defined by the secret variables we set up earlier.
The deployment occurs only if we're pushing or merging to `master` branch, so development versions are tested but not published.

Done! We've now our changes in the GitLab repo, and a pipeline has already been started for this commit. Let's go to the **Pipelines** tab and see what happens.
If we've no errors, we can see some text like this at the end of the `deploy` job output log:

```
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 1.983 s

```

>**Note**:
the `mvn` command downloads a lot of files from the Internet, so you'll see a lot of extra activity in the log the first time you run it.

Wow! We did it! Checking in Artifactory will confirm that we've a new artifact available in the `libs-release-local` repo.

## Create the main Maven application

#### Prepare the application

Now that we've our dependency available on Artifactory, we want to use it!

Let's create another application by cloning the one we can find at `https://gitlab.com/gitlab-examples/maven/simple-maven-app.git`, and make it `public` too!  
If you look at the `src/main/java/com/example/app/App.java` file you can see that it imports the `com.example.dep.Dep` class and calls the `hello` method passing `GitLab` as a parameter.

Since Maven doesn't know how to resolve the dependency, we need to modify the configuration.  
Let's go back to Artifactory, and browse the `libs-release-local` repository selecting the `simple-maven-dep-1.0.jar` file.
In the **Dependency Declaration** section of the main panel we can copy the configuration snippet:

```xml
<dependency>
  <groupId>com.example.dep</groupId>
  <artifactId>simple-maven-dep</artifactId>
  <version>1.0</version>
</dependency>
```

Let's just copy this in the `dependencies` section of our `pom.xml` file.

#### Configure the Artifactory repository location

At this point we defined our dependency for the application, but we still miss where we can find the required files.  
We need to create a `.m2/settings.xml` file as we did for our dependency project, and let Maven know the location using environment variables.

Here is how we can get the content of the file directly from Artifactory:
1. from the main screen, click on the `libs-release-local` item in the **Set Me Up** panel
2. click on **Generate Maven Settings**
3. click on **Generate Settings**
3. copy to clipboard the configuration file
4. save the file as `.m2/settings.xml` in your repo

Now we're ready to use our Artifactory repository to resolve dependencies and use `simple-maven-dep` in our application!

#### Configure GitLab Continuous Integration for `simple-maven-app`

We need a last step to have everything in place: configure `.gitlab-ci.yml`.

We want to build, test and run our awesome application, and see if we can get the greeting we expect!

So let's add the `.gitlab-ci.yml` to our repo:

```yaml
image: maven:latest

stages:
  - build
  - test
  - run

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

cache:
  paths:
    - .m2/repository/
    - target/

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

run:
  stage: run
  script:
    - mvn $MAVEN_CLI_OPTS package
    - mvn $MAVEN_CLI_OPTS exec:java -Dexec.mainClass="com.example.app.App"
```

And that's it! In the `run` job output log we will find a friendly hello to GitLab!

## Conclusion

In this article we covered the basic steps to use an Artifactory Maven repository to automatically publish and consume our artifacts.

A similar approach could be used to interact with any other Maven compatible Binary Repository Manager.
You can improve these examples, optimizing the `.gitlab-ci.yml` file to better suit your needs, and adapting to your workflow.

Enjoy GitLab CI with all your Maven projects!