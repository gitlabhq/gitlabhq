# GitLab Maven Packages repository

## Configure project to use GitLab Maven Repository URL

To download packages from GitLab, you need `repository` section in your `pom.xml`.

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</repositories>
```

To upload packages to GitLab, you need a `distributionManagement` section in your `pom.xml`.

```xml
<distributionManagement>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.com/api/v4/projects/PROJECT_ID/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

In both examples, replace `PROJECT_ID` with your project ID. 
If you have a private GitLab installation, replace `gitlab.com` with your domain name.

## Configure repository access

If a project is private, credentials will need to be provided for authorization.
The preferred way to do this, is by using a [personal access tokens][pat].
You can add a corresponding section to your `settings.xml` file:


```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Private-Token</name>
            <value>REPLACE_WITH_YOUR_PRIVATE_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```  

## Create maven packages with GitLab CI

Once you have your repository configured to use GitLab Maven Packages repository, 
you can configure GitLab CI to build new packages automatically. The example below 
shows you how to create a new package each time the master branch is updated.

1\. Create a `ci_settings.xml` file specially for GitLab CI and put it into your repository. 

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Job-Token</name>
            <value>CI_JOB_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

2\. Add `deploy` section to your `.gitlab-ci.yml` file.

```
deploy:
  script:
    - 'cp ci_settings.xml /root/.m2/settings.xml'
    - 'sed -i "s/CI_JOB_TOKEN/${CI_JOB_TOKEN}/g" /root/.m2/settings.xml'
    - 'mvn deploy'
  only:
    - master
  image: maven:3.3.9-jdk-8
```

[pat]: ../profile/personal_access_tokens.md
