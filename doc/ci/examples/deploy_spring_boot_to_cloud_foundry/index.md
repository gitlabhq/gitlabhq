# Deploy a Spring Boot application to Cloud Foundry with GitLab CI/CD

> **Article [Type](../../../development/writing_documentation.html#types-of-technical-articles):** tutorial ||
> **Level:** intermediary ||
> **Author:** [Dylan Griffith](https://gitlab.com/DylanGriffith) ||
> **Publication date:** 2017-11-23

## Introduction

In this article, we'll demonstrate how to deploy a [Spring
Boot](https://projects.spring.io/spring-boot/) application to [Cloud
Foundry (CF)](https://www.cloudfoundry.org/) with GitLab CI/CD using the [Continuous
Deployment](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#continuous-deployment)
method.

All the code for this project can be found in this [GitLab
repo](https://gitlab.com/DylanGriffith/spring-gitlab-cf-deploy-demo).

## Prerequisites

_We assume you are familiar with Java and Git but would like to learn how to
automate the deployment of Spring Boot Applications to Cloud Foundry using
GitLab CI/CD._

To follow along with this tutorial you will need the following:

- A working [Java Development Kit
  (JDK)](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
  installed
- An account on [Pivotal Web Services (PWS)](https://run.pivotal.io/) or any
  other Cloud Foundry instance

NOTE: You will need to replace the `api.run.pivotal.io` URL in the all below
commands with the [API
URL](https://docs.cloudfoundry.org/running/cf-api-endpoint.html) of your CF
instance if you're not deploying to PWS.

## Install CF CLI And Login

The latest installation instructions for your system can be found at [the repo
for the CF CLI](https://github.com/cloudfoundry/cli#downloads).

You can login to CF via command line:

```
cf login -a api.run.pivotal.io
```

## Create Your Project

To start your Spring Boot application you can go to the [Spring
Initializr](https://start.spring.io/) and select the components you want. For
the purposes of simplicity, we're going to just create a simple web app with a
"Hello, world!" route in it so we need only select "Web" from dependencies. You
can pick any other dependencies you may need and choose the build tools you
like but in this tutorial we'll use the options below:

![Spring Initializr settings](img/spring_initializr_settings.png)

After selecting all the dependencies you can then download the zip file
containing your application. After you unzip the application and `cd` into the
directory you can start the app with:

```sh
./gradlew bootRun
```

Let's now add a simple HTTP endpoint to our application to see something
working. We can do this by using the [Rest
Controller](https://spring.io/guides/gs/rest-service/#_create_a_resource_controller).
Add the following class to your application:

```java
// HelloController.java
package net.gitlabcfdeploy.helloworld;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("/")
    public String hello() {
        return "Hello, world!";
    }
}
```

You can now restart the application by killing the previous `./gradlew bootRun`
command with `ctrl+c` and then running it again. You should now be able to see
the "Hello, world!" message when you visit `http://localhost:8080/`.

## Configure Your Cloud Foundry Deployment

In order to deploy our application we will first need to build a JAR file.
This is a java executable that we will upload to Cloud Foundry that includes
our entire Spring Boot application. The project already includes the necessary
build steps to create this JAR using [gradle](https://gradle.org/).  In order
to ensure the JAR path is consistent, you can update the `build.gradle` file and
add the following to the bottom of the file:

```
jar{
    archiveName 'helloworld.jar'
}
```

First compile the JAR for your spring boot application:

```bash
./gradlew assemble
```

To deploy to Cloud Foundry we need to add a `manifest.yml` file. This
is the configuration for the CF CLI we will use to deploy the application. We
will create this in the root directory of our project with the following
content:

```yaml
---
applications:
- name: gitlab-hello-world
  random-route: true
  memory: 1G
  path: ./build/libs/helloworld.jar
```

Now that we have our `manifest.yml` we can now test our deployment by running:

```bash
cf push
```

Once the app is finished deploying it will display the URL your application:

```
requested state: started
instances: 1/1
usage: 1G x 1 instances
urls: gitlab-hello-world-undissembling-hotchpot.cfapps.io
last uploaded: Mon Nov 6 10:02:25 UTC 2017
stack: cflinuxfs2
buildpack: client-certificate-mapper=1.2.0_RELEASE container-security-provider=1.8.0_RELEASE java-buildpack=v4.5-offline-https://github.com/cloudfoundry/java-buildpack.git#ffeefb9 java-main java-opts jvmkill-agent=1.10.0_RELEASE open-jdk-like-jre=1.8.0_1...

     state     since                    cpu      memory         disk           details
#0   running   2017-11-06 09:03:22 PM   120.4%   291.9M of 1G   137.6M of 1G
```

You can then visit your deployed application (in my case,
https://gitlab-hello-world-undissembling-hotchpot.cfapps.io/) and you should
see the "Hello, world!" message.

## Push Your App To GitLab

Create your GitLab repo (e.g., `https://gitlab.com/username/my-repo.git`) then
push to it locally:

```bash
git init
git remote add origin git@gitlab.com:username/my-repo.git
git add .
git commit -m "Initial commit"
git push -u origin master
```

## Configure GitLab CI/CD To Deploy Your Application

Now we need to add the the GitLab CI/CD configuration file
([`.gitlab-ci.yml`](../../yaml/README.md)) to our
project's root. This is how GitLab figures out what commands need to be run whenever
code is pushed to our repository. We will add the following `.gitlab-ci.yml`
file to the root directory of the repository, GitLab will detect it
automatically and run the steps defined once we push our code:

```yaml
image: java:8

stages:
  - build
  - deploy

build:
  stage: build
  script: ./gradlew assemble
  artifacts:
    paths:
      - build/libs/helloworld.jar

production:
  stage: deploy
  script:
  - curl --location "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" | tar zx
  - ./cf login -u $CF_USERNAME -p $CF_PASSWORD -a api.run.pivotal.io
  - ./cf push
  only:
  - master
```

We've used the `java:8` [docker
image](../../docker/using_docker_images.md) to build
our application as it provides the up to date Java 8 JDK on [Docker
Hub](https://hub.docker.com/). We've also added the [`only`
clause](../../yaml/README.md#only-and-except-simplified)
to ensure our deployments only happen when we push to the master branch.

Now, since the steps defined in `.gitlab-ci.yml` require credentials to login
to CF, you'll need to add your CF credentials as [environment
variables](../../variables/README.md#predefined-variables-environment-variables)
on GitLab CI/CD. To set the environment variables navigate from your project
using the navigation left sidebar to **Settings > CI/CD** and expand **Secret
Variables**. Name the variables `CF_USERNAME` and `CF_PASSWORD` and set them to
the correct values.

![Secret Variable Settings in GitLab](img/cloud_foundry_secret_variables.png)

Now when the repo is next pushed we should see the build running on GitLab (under
**CI/CD > Pipelines**) and it should deploy to CF for us.

NOTE: It is considered best practice for security to create a separate deploy
user for your application and add their credentials to GitLab instead of using
a developer's credentials.

## Conclusion

This guide demonstrates the setup necessary to take a Spring Boot application
and deploy it to Cloud Foundry in an automated way using GitLab CI/CD.
