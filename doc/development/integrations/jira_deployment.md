---
stage: Plan
group: Project Management
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Local Jira deployment testing
---

GitLab integrates with multiple Jira deployment types. When testing Jira integrations,
you might need to replicate these environments locally:

- [Jira Cloud](https://developer.atlassian.com/cloud/jira/platform/) - The Atlassian SaaS solution
- [Jira Data Center](https://www.atlassian.com/enterprise/data-center/jira) - Self-hosted solution 
([end of support in 2029](https://www.atlassian.com/licensing/data-center-end-of-life#data-center-eol-general-questions))
- [Jira Server](https://www.atlassian.com/licensing/server-end-of-support) - End of support reached
on February 15, 2024. Testing is not recommended.

## Jira Cloud

Atlassian provides [free instances for development and testing](https://developer.atlassian.com/platform/marketplace/getting-started/#free-developer-instances-to-build-and-test-your-app).

For authentication, create a [Jira Cloud API token](../../integration/jira/configure.md#create-a-jira-cloud-api-token).

## Jira Data Center

Atlassian provides [download archives](https://www.atlassian.com/software/jira/download-archives) for all versions.
For quick local testing, use this Docker Compose configuration:

```yaml
# docker-compose.yaml
services:
  jira:
    image: atlassian/jira-software:11.3 # most recent LTS version
    container_name: jira
    ports:
      - "8080:8080"
    environment:
      - ATL_PROXY_NAME=localhost
      - ATL_PROXY_PORT=8080
      - ATL_TOMCAT_SCHEME=http
      - ATL_JDBC_URL=jdbc:postgresql://postgres:5432/jiradb
      - ATL_JDBC_USER=jira
      - ATL_JDBC_PASSWORD=${JIRA_DB_PASSWORD}
      - ATL_DB_TYPE=postgres72
      - ATL_DB_DRIVER=org.postgresql.Driver
      - JVM_MINIMUM_MEMORY=1024m
      - JVM_MAXIMUM_MEMORY=2048m
    volumes:
      - jira-data:/var/atlassian/application-data/jira
    depends_on:
      - postgres
    networks:
      - atlassian

  postgres:
    image: postgres:14
    container_name: jira-postgres
    environment:
      - POSTGRES_DB=jiradb
      - POSTGRES_USER=jira
      - POSTGRES_PASSWORD=${JIRA_DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - atlassian

volumes:
  jira-data:
  postgres-data:

networks:
  atlassian:
    driver: bridge
```

Create a `.env` file with your database password:

```plaintext
JIRA_DB_PASSWORD=<JIRA_DB_PASSWORD>
```

### Setup steps

1. Start the containers: `docker-compose up -d`.
1. In your browser, go to `http://localhost:8080`.
1. Complete the initial setup wizard to configure your instance name and URL.
1. Get a short-lived license from [Atlassian's developer documentation site](https://developer.atlassian.com/platform/marketplace/timebomb-licenses-for-testing-server-apps/#data-center-host-product-licenses), such as the `10 user Jira Software Data Center license, expires in 3 hours` key.
1. Create an administrator account.
1. Create a **basic software development** project, and populate it with example issues in various states.

### Authentication for GitLab integration

Use either the administrator username/password or generate a personal access token in Jira.
