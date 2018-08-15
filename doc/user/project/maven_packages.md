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

[pat]: ../profile/personal_access_tokens.md
