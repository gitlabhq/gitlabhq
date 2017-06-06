> **Article [Type](../../development/writing_documentation.html#types-of-technical-articles):** tutorial ||
> **Level:** intermediary ||
> **Author:** [Fabio busatto](https://gitlab.com/bikebilly) ||
> **Publication date:** AAAA/MM/DD

In this article, we're going to show how we can leverage the power of GitLab CI to compile, test and deploy a Maven application to an Artifactory repository with just a very few lines of configuration.
 
Every time we change our sample application, the Continuos Integration will check that everything is correct, and after a merge to master branch it will automatically push our package, making it ready for use.
 
 
# Create a simple Maven application
 
First of all, we need to create our application. We choose to have a very simple one, but it could be any Maven application. The simplest way is to use Maven itself, we've just to run the following command:
 
```bash
mvn archetype:generate -DgroupId=com.example.app -DartifactId=maven-example-app -Dversion=1.0 -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

Done! Let's move into the maven-example-app directory. Now we've our app to work with.
 
The project structure is quite simple, and we're interested mainly in these resources:
 
`pom.xml`: project object model (POM) file
`src/main/java/com/example/app/App.java`: source of our application (it prints "Hello World!" to stdout)
 
# Test our app locally
 
If we want to be sure the application has been created correctly, we can compile and test it:
 
```bash
mvn compile && mvn test
```

Note: every time we run a `mvn` command it may happen that a bunch of files are downloaded: it's totally normal, and these files are cached so we don't have to download them again next time.
 
At the end of the run, we should see an output like this:
 
```
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 5.614 s
[INFO] Finished at: 2017-06-05T10:50:36+02:00
[INFO] Final Memory: 17M/130M
[INFO] ------------------------------------------------------------------------
```

# Create `.gitlab-ci.yml`
 
A very simple `.gitlab-ci.yml` file that performs build and tests of our application is the following:
 
```yaml
image: maven:latest
 
cache:
  paths:
    - target/
 
build:
  script:
    - mvn compile
 
test:
  script:
    - mvn test
```
 
We want to use the latest docker image available for Maven, that already contains everything we need to perform our tasks. We also want to cache the `.m2` folder in the user homedir: this is the place where all the files automatically download by Maven commands are stored, so we can reuse them between stages. The `target` folder is where our application will be created: Maven runs all the phases in a specific order, so running `mvn test` will automatically run `mvn compile` if needed, but we want to improve performances caching everything that is reused.
 
# Push the code to GitLab
 
Now that we've our app, we want to put it on GitLab! Long story short, we've to create a new project and push the code to it as usual. A new pipeline will run and you've just to wait until it succeed!
 
# Set up Artifactory as the deployment repo
 
## Configure POM file
 
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

## Configure credentials for the repo
 
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
 
# Configure automatic deployment
 
Time to change `.gitlab-ci.yml` and add the deploy stage! Maven has the perfect command for that, but it requires `settings.xml` to be in the correct folder, so we need to move it before executing `mvn deploy` command.
 
The complete file is now this:
 
```yaml
image: maven:latest
 
cache:
  paths:
    - target/
 
Build:
  Stage: build
  script:
    - mvn compile
 
Test:
  Stage: test
  script:
    - mvn test
 
Deploy:
  Stage: deploy
  script:
    - cp .maven-settings.xml ~/.m2/settings.xml
    - mvn deploy
  only:
    - master
```

We're ready to go! Every merge (or push) to master will now trigger the deployment to our Artifactory repository!