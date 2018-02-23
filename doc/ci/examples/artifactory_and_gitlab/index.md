---
redirect_from: 'https://docs.gitlab.com/ee/articles/artifactory_and_gitlab/index.html'
author: Fabio Busatto
author_gitlab: bikebilly
level: intermediary
article_type: tutorial
date: 2017-08-15
---

# How to deploy Maven projects to Artifactory with GitLab CI/CD

## Introduction

In this article, we will show how you can leverage the power of [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/)
to build a [Maven](https://maven.apache.org/) project, deploy it to [Artifactory](https://www.jfrog.com/artifactory/), and then use it from another Maven application as a dependency.

You'll create two different projects:

- `simple-maven-dep`: the app built and deployed to Artifactory (available at https://gitlab.com/gitlab-examples/maven/simple-maven-dep)
- `simple-maven-app`: the app using the previous one as a dependency (available at https://gitlab.com/gitlab-examples/maven/simple-maven-app)

We assume that you already have a GitLab account on [GitLab.com](https://gitlab.com/), and that you know the basic usage of Git and [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/).
We also assume that an Artifactory instance is available and reachable from the internet, and that you have valid credentials to deploy on it.

## Create the simple Maven dependency

First of all, you need an application to work with: in this specific case we will
use a simple one, but it could be any Maven application. This will be the
dependency you want to package and deploy to Artifactory, in order to be
available to other projects.

### Prepare the dependency application

For this article you'll use a Maven app that can be cloned from our example
project:

1. Log in to your GitLab account
1. Create a new project by selecting **Import project from ➔ Repo by URL**
1. Add the following URL:

    ```
    https://gitlab.com/gitlab-examples/maven/simple-maven-dep.git
    ```
1. Click **Create project**

This application is nothing more than a basic class with a stub for a JUnit based test suite.
It exposes a method called `hello` that accepts a string as input, and prints a hello message on the screen.

The project structure is really simple, and you should consider these two resources:

- `pom.xml`: project object model (POM) configuration file
- `src/main/java/com/example/dep/Dep.java`: source of our application

### Configure the Artifactory deployment

The application is ready to use, but you need some additional steps to deploy it to Artifactory:

1. Log in to Artifactory with your user's credentials.
1. From the main screen, click on the `libs-release-local` item in the **Set Me Up** panel.
1. Copy to clipboard the configuration snippet under the **Deploy** paragraph.
1. Change the `url` value in order to have it configurable via secret variables.
1. Copy the snippet in the `pom.xml` file for your project, just after the
   `dependencies` section. The snippet should look like this:

    ```xml
    <distributionManagement>
      <repository>
        <id>central</id>
        <name>83d43b5afeb5-releases</name>
        <url>${env.MAVEN_REPO_URL}/libs-release-local</url>
      </repository>
    </distributionManagement>
    ```

Another step you need to do before you can deploy the dependency to Artifactory
is to configure the authentication data. It is a simple task, but Maven requires
it to stay in a file called `settings.xml` that has to be in the `.m2` subdirectory
in the user's homedir.

Since you want to use GitLab Runner to automatically deploy the application, you
should create the file in the project's home directory and set a command line
parameter in `.gitlab-ci.yml` to use the custom location instead of the default one:

1. Create a folder called `.m2` in the root of your repository
1. Create a file called `settings.xml` in the `.m2` folder
1. Copy the following content into a `settings.xml` file:

    ```xml
    <settings xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd"
        xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <servers>
        <server>
          <id>central</id>
          <username>${env.MAVEN_REPO_USER}</username>
          <password>${env.MAVEN_REPO_PASS}</password>
        </server>
      </servers>
    </settings>
    ```

    Username and password will be replaced by the correct values using secret variables.

### Configure GitLab CI/CD for `simple-maven-dep`

Now it's time we set up [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/) to automatically build, test and deploy the dependency!

GitLab CI/CD uses a file in the root of the repo, named `.gitlab-ci.yml`, to read the definitions for jobs
that will be executed by the configured GitLab Runners. You can read more about this file in the [GitLab Documentation](https://docs.gitlab.com/ee/ci/yaml/).

First of all, remember to set up secret variables for your deployment. Navigate to your project's **Settings > CI/CD** page
and add the following secret variables (replace them with your current values, of course):

- **MAVEN_REPO_URL**: `http://artifactory.example.com:8081/artifactory` (your Artifactory URL)
- **MAVEN_REPO_USER**: `gitlab` (your Artifactory username)
- **MAVEN_REPO_PASS**: `AKCp2WXr3G61Xjz1PLmYa3arm3yfBozPxSta4taP3SeNu2HPXYa7FhNYosnndFNNgoEds8BCS` (your Artifactory Encrypted Password)

Now it's time to define jobs in `.gitlab-ci.yml` and push it to the repo:

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

GitLab Runner will use the latest [Maven Docker image](https://hub.docker.com/_/maven/), which already contains all the tools and the dependencies you need to manage the project,
in order to run the jobs.

Environment variables are set to instruct Maven to use the `homedir` of the repo instead of the user's home when searching for configuration and dependencies.

Caching the `.m2/repository folder` (where all the Maven files are stored), and the `target` folder (where our application will be created), is useful for speeding up the process
by running all Maven phases in a sequential order, therefore, executing `mvn test` will automatically run `mvn compile` if necessary.

Both `build` and `test` jobs leverage the `mvn` command to compile the application and to test it as defined in the test suite that is part of the application.

Deploy to Artifactory is done as defined by the secret variables we have just set up.
The deployment occurs only if we're pushing or merging to `master` branch, so that the development versions are tested but not published.

Done! Now you have all the changes in the GitLab repo, and a pipeline has already been started for this commit. In the **Pipelines** tab you can see what's happening.
If the deployment has been successful, the deploy job log will output:

```
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 1.983 s
```

>**Note**:
the `mvn` command downloads a lot of files from the internet, so you'll see a lot of extra activity in the log the first time you run it.

Yay! You did it! Checking in Artifactory will confirm that you have a new artifact available in the `libs-release-local` repo.

## Create the main Maven application

Now that you have the dependency available on Artifactory, it's time to use it!
Let's see how we can have it as a dependency to our main application.

### Prepare the main application

We'll use again a Maven app that can be cloned from our example project:

1. Create a new project by selecting **Import project from ➔ Repo by URL**
1. Add the following URL:

    ```
    https://gitlab.com/gitlab-examples/maven/simple-maven-app.git
    ```
1. Click **Create project**

This one is a simple app as well. If you look at the `src/main/java/com/example/app/App.java`
file you can see that it imports the `com.example.dep.Dep` class and calls the `hello` method passing `GitLab` as a parameter.

Since Maven doesn't know how to resolve the dependency, you need to modify the configuration:

1. Go back to Artifactory
1. Browse the `libs-release-local` repository
1. Select the `simple-maven-dep-1.0.jar` file
1. Find the configuration snippet from the **Dependency Declaration** section of the main panel
1. Copy the snippet in the `dependencies` section of the `pom.xml` file.
   The snippet should look like this:

    ```xml
    <dependency>
      <groupId>com.example.dep</groupId>
      <artifactId>simple-maven-dep</artifactId>
      <version>1.0</version>
    </dependency>
    ```

### Configure the Artifactory repository location

At this point you defined the dependency for the application, but you still miss where you can find the required files.
You need to create a `.m2/settings.xml` file as you did for the dependency project, and let Maven know the location using environment variables.

Here is how you can get the content of the file directly from Artifactory:

1. From the main screen, click on the `libs-release-local` item in the **Set Me Up** panel
1. Click on **Generate Maven Settings**
1. Click on **Generate Settings**
1. Copy to clipboard the configuration file
1. Save the file as `.m2/settings.xml` in your repo

Now you are ready to use the Artifactory repository to resolve dependencies and use `simple-maven-dep` in your main application!

### Configure GitLab CI/CD for `simple-maven-app`

You need a last step to have everything in place: configure the `.gitlab-ci.yml` file for this project, as you already did for `simple-maven-dep`.

You want to leverage [GitLab CI/CD](https://about.gitlab.com/features/gitlab-ci-cd/) to automatically build, test and run your awesome application,
and see if you can get the greeting as expected!

All you need to do is to add the following `.gitlab-ci.yml` to the repo:

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

It is very similar to the configuration used for `simple-maven-dep`, but instead of the `deploy` job there is a `run` job.
Probably something that you don't want to use in real projects, but here it is useful to see the application executed automatically.

And that's it! In the `run` job output log you will find a friendly hello to GitLab!

## Conclusion

In this article we covered the basic steps to use an Artifactory Maven repository to automatically publish and consume artifacts.

A similar approach could be used to interact with any other Maven compatible Binary Repository Manager.
Obviously, you can improve these examples, optimizing the `.gitlab-ci.yml` file to better suit your needs, and adapting to your workflow.
