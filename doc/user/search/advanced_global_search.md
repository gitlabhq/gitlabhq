# Advanced Global Search

>
- [Introduced][ee-109] in GitLab [Enterprise Edition Starter][ee] 8.4.
- This is the user documentation. To install and configure Elasticsearch,
  visit the [admin docs](../../integration/elasticsearch.md).

Leverage Elasticsearch for faster, more advanced code search across your entire
GitLab instance.

## Overview

The Advanced Global Search in GitLab is a powerful search service that saves
you time. Instead of creating duplicate code and wasting time, you can
now search for code within other teams that can help your own project.

GitLab leverages the search capabilities of Elasticsearch and enables it when
searching in:

- GitLab application
- Issues
- Merge requests
- Milestones
- Notes (comments)
- Projects
- Repositories
- Snippets
- Wiki

## Use cases

1. If you are looking to enable innersourcing, with Global code search ...
1. You want to keep GitLab's search fast when dealing with huge amount of data.

## Searching globally

Just use the search as before and GitLab will show you matching code from each
project you have access to.

![Advanced Global Search](img/advanced_global_search.png)

You can also use the [Advanced Syntax Search](advanced_search_syntax.md) which
provides some useful queries.

[ee-1305]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1305
[aws-elastic]: http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-gsg.html
[aws-iam]: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
[aws-instance-profile]: http://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli
[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
[ee]: https://about.gitlab.com/gitlab-ee/
