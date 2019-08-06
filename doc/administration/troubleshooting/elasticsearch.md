# Troubleshooting ElasticSearch

Troubleshooting ElasticSearch requires:

- Knowledge of common terms.
- Establishing within which category the problem fits.

## Common terminology

- **Lucene**: A full-text search library written in Java.
- **Near Realtime (NRT)**: Refers to the slight latency from the time to index a
  document to the time when it becomes searchable.
- **Cluster**: A collection of one or more nodes that work together to hold all
  the data, providing indexing and search capabilities.
- **Node**: A single server that works as part of a cluster.
- **Index**: A collection of documents that have somewhat similar characteristics.
- **Document**: A basic unit of information that can be indexed.
- **Shards**: Fully-functional and independent subdivisions of indices. Each shard is actually
  a Lucene index.
- **Replicas**: Failover mechanisms that duplicate indices.

## Troubleshooting workflows

The type of problem will determine what steps to take. The possible troubleshooting workflows are for:

- Search results.
- Indexing.
- Integration.
- Performance.

### Search Results workflow

The following workflow is for ElasticSearch search results issues:

```mermaid
graph TD;
  B --> |No| B1
  B --> |Yes| B4
  B1 --> B2
  B2 --> B3
  B4 --> B5
  B5 --> |Yes| B6
  B5 --> |No| B7
  B7 --> B8
  B{Is GitLab using<br>ElasticSearch for<br>searching?}
  B1[Check Admin Area > Integrations<br>to ensure the settings are correct]
  B2[Perform a search via<br>the rails console]
  B3[If all settings are correct<br>and it still doesn't show ElasticSearch<br>doing the searches, escalate<br>to GitLab support.]
  B4[Perform<br>the same search via the<br>ElasticSearch API]
  B5{Are the results<br>the same?}
  B6[This means it is working as intended.<br>Speak with GitLab support<br>to confirm if the issue lies with<br>the filters.]
  B7[Check the index status of the project<br>containing the missing search<br>results.]
  B8(Indexing Troubleshooting)
```

### Indexing workflow

The following workflow is for ElasticSearch indexing issues:

```mermaid
graph TD;
  C --> |Yes| C1
  C1 --> |Yes| C2
  C1 --> |No| C3
  C3 --> |Yes| C4
  C3 --> |No| C5
  C --> |No| C6
  C6 --> |No| C10
  C7 --> |GitLab| C8
  C7 --> |ElasticSearch| C9
  C6 --> |Yes| C7
  C10 --> |No| C12
  C10 --> |Yes| C11
  C12 --> |Yes| C13
  C12 --> |No| C14
  C14 --> |Yes| C15
  C14 --> |No| C16
  C{Is the problem with<br>creating an empty<br>index?}
  C1{Does the gitlab-production<br>index exist on the<br>ElasticSearch instance?}
  C2(Try to manually<br>delete the index on the<br>ElasticSearch instance and<br>retry creating an empty index.)
  C3{Can indices be made<br>manually on the ElasticSearch<br>instance?}
  C4(Retry the creation of an empty index)
  C5(It is best to speak with an<br>ElasticSearch admin concerning the<br>instance's inability to create indices.)
  C6{Is the indexer presenting<br>errors during indexing?}
  C7{Is the error a GitLab<br>error or an ElasticSearch<br>error?}
  C8[Escalate to<br>GitLab support]
  C9[You will want<br>to speak with an<br>ElasticSearch admin.]
  C10{Does the index status<br>show 100%?}
  C11[Escalate to<br>GitLab support]
  C12{Does re-indexing the project<br> present any GitLab errors?}
  C13[Rectify the GitLab errors and<br>restart troubleshooting, or<br>escalate to GitLab support.]
  C14{Does re-indexing the project<br>present errors on the <br>ElasticSearch instance?}
  C15[It would be best<br>to speak with an<br>ElasticSearch admin.]
  C16[This is likely a bug/issue<br>in GitLab and will require<br>deeper investigation. Escalate<br>to GitLab support.]
```

### Integration workflow

The following workflow is for ElasticSearch integration issues:

```mermaid
graph TD;
  D --> |No| D1
  D --> |Yes| D2
  D2 --> |No| D3
  D2 --> |Yes| D4
  D4 --> |No| D5
  D4 --> |Yes| D6
  D{Is the error concerning<br>the beta indexer?}
  D1[It would be best<br>to speak with an<br>ElasticSearch admin.]
  D2{Is the ICU development<br>package installed?}
  D3>This package is required.<br>Install the package<br>and retry.]
  D4{Is the error stemming<br>from the indexer?}
  D5[This would indicate an OS level<br> issue. It would be best to<br>contact your sysadmin.]
  D6[This is likely a bug/issue<br>in GitLab and will require<br>deeper investigation. Escalate<br>to GitLab support.]
```

### Performance workflow

The following workflow is for ElasticSearch performance issues:

```mermaid
graph TD;
  F --> |Yes| F1
  F --> |No| F2
  F2 --> |No| F3
  F2 --> |Yes| F4
  F4 --> F5
  F5 --> |No| F6
  F5 --> |Yes| F7
  F{Is the ElasticSearch instance<br>running on the same server<br>as the GitLab instance?}
  F1(This is not advised and will cause issues.<br>We recommend moving the ElasticSearch<br>instance to a different server.)
  F2{Does the ElasticSearch<br>server have at least 8<br>GB of RAM and 2 CPU<br>cores?}
  F3(According to ElasticSearch, a non-prod<br>server needs these as a base requirement.<br>Production often requires more. We recommend<br>you increase the server specifications.)
  F4(Obtain the <br>cluster health information)
  F5(Does it show the<br>status as green?)
  F6(We recommend you speak with<br>an ElasticSearch admin<br>about implementing sharding.)
  F7(Escalate to<br>GitLab support.)
```

## Troubleshooting walkthrough

Most ElasticSearch troubleshooting can be broken down into 4 categories:

- [Troubleshooting search results](#troubleshooting-search-results)
- [Troubleshooting indexing](#troubleshooting-indexing)
- [Troubleshooting integration](#troubleshooting-integration)
- [Troubleshooting performance](#troubleshooting-performance)

Generally speaking, if it does not fall into those four categories, it is either:

- Something GitLab support needs to look into.
- Not a true ElasticSearch issue.

Exercise caution. Issues that appear to be ElasticSearch problems can be OS-level issues.

### Troubleshooting search results

Troubleshooting search result issues is rather straight forward on ElasticSearch.

The first step is to confirm GitLab is using ElasticSearch for the search function.
To do this:

1. Confirm the integration is enabled in **Admin Area > Settings > Integrations**.
1. Confirm searches utilize ElasticSearch by accessing the rails console
   (`sudo gitlab-rails console`) and running the following commands:

   ```rails
   u = User.find_by_email('email_of_user_doing_search')
   s = SearchService.new(u, {:search => 'search_term'})
   pp s.search_objects.class.name
   ```

The ouput from the last command is the key here. If it shows:

- `ActiveRecord::Relation`, **it is not** using ElasticSearch.
- `Kaminari::PaginatableArray`, **it is** using ElasticSearch.

| Not using ElasticSearch  | Using ElasticSearch          |
|--------------------------|------------------------------|
| `ActiveRecord::Relation` | `Kaminari::PaginatableArray` |

If all the settings look correct and it is still not using ElasticSearch for the search function, it is best to escalate to GitLab support. This could be a bug/issue.

Moving past that, it is best to attempt the same search using the [ElasticSearch Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) and compare the results from what you see in GitLab.

If the results:

- Sync up, then there is not a technical "issue" per se. Instead, it might be a problem
  with the ElasticSearch filters we are using. This can be complicated, so it is best to
  escalate to GitLab support to check these and guide you on the potential on whether or
  not a feature request is needed.
- Do not match up, this indicates a problem with the documents generated from the
  project. It is best to re-index that project and proceed with
  [Troubleshooting indexing](#troubleshooting-indexing).

### Troubleshooting indexing

Troubleshooting indexing issues can be tricky. It can pretty quickly go to either GitLab
support or your ElasticSearch admin.

The best place to start is to determine if the issue is with creating an empty index.
If it is, check on the ElasticSearch side to determine if the `gitlab-production` (the
name for the GitLab index) exists. If it exists, manually delete it on the ElasticSearch
side and attempt to recreate it from the
[`create_empty_index`](../../integration/elasticsearch.md#gitlab-elasticsearch-rake-tasks)
rake task.

If you still encounter issues, try creating an index manually on the ElasticSearch
instance. The details of the index aren't important here, as we want to test if indices
can be made. If the indices:

- Cannot be made, speak with your ElasticSearch admin.
- Can be made, Escalate this to GitLab support.

If the issue is not with creating an empty index, the next step is to check for errors
during the indexing of projects. If errors do occur, they will either stem from the indexing:

- On the GitLab side. You need to rectify those. If they are not
  something you are familiar with, contact GitLab support for guidance.
- Within the ElasticSearch instance itself. See if the error is [documented and has a fix](../../integration/elasticsearch.md#troubleshooting). If not, speak with your ElasticSearch admin.

If the indexing process does not present errors, you will want to check the status of the indexed projects. You can do this via the following rake tasks:

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../integration/elasticsearch.md#gitlab-elasticsearch-rake-tasks) (shows the overall status)
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../integration/elasticsearch.md#gitlab-elasticsearch-rake-tasks) (shows specific projects that are not indexed)

If:

- Everything is showing at 100%, escalate to GitLab support. This could be a potential
  bug/issue.
- You do see something not at 100%, attempt to reindex that project. To do this,
  run `sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`.

If reindexing the project shows:

- Errors on the GitLab side, escalate those to GitLab support.
- ElasticSearch errors or doesn't present any errors at all, reach out to your
  ElasticSearch admin to check the instance.

### Troubleshooting integration

Troubleshooting integration tends to be pretty straight forward, as there really isn't
much to "integrate" here.

If the issue is:

- Not concerning the beta indexer, it is almost always an
  ElasticSearch-side issue. This means you should reach out to your ElasticSearch admin
  regarding the error(s) you are seeing. If you are unsure here, it never hurts to reach
  out to GitLab support.
- With the beta indexer, check if the ICU development package is installed.
  This is a required package so make sure you install it.

Beyond that, you will want to review the error. If it is:

- Specifically from the indexer, this could be a bug/issue and should be escalated to
  GitLab support.
- An OS issue, you will want to reach out to your systems administrator.

### Troubleshooting performance

Troubleshooting performance can be difficult on ElasticSearch. There is a ton of tuning
that *can* be done, but the majority of this falls on shoulders of a skilled
ElasticSearch administrator.

Generally speaking, ensure:

* The ElasticSearch server **is not** running on the same node as GitLab.
* The ElasticSearch server have enough RAM and CPU cores.
* That sharding **is** being used.

Going into some more detail here, if ElasticSearch is running on the same server as GitLab, resource contention is **very** likely to occur. Ideally, ElasticSearch, which requires ample resources, should be running on its own server (maybe coupled with logstash and kibana).

When it comes to ElasticSearch, RAM is the key resource. ElasticSearch themselves recommend:

- **At least** 8 GB of RAM for a non-production instance.
- **At least** 16 GB of RAM for a production instance.
- Ideally, 64 GB of RAM.

For CPU, ElasticSearch recommends at least 2 CPU cores, but ElasticSearch states common
setups use up to 8 cores. For more details on server specs, check out
[ElasticSearch's hardware guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html).

Beyond the obvious, sharding comes into play. Sharding is a core part of ElasticSearch.
It allows for horizontal scaling of indices, which is helpful when you are dealing with
a large amount of data.

With the way GitLab does indexing, there is a **huge** amount of documents being
indexed. By utilizing sharding, you can speed up ElasticSearch's ability to locate
data, since each shard is a Lucene index.

If you are not using sharding, you are likely to hit issues when you start using
ElasticSearch in a production environment.

Keep in mind that an index with only one shard has **no scale factor** and will
likely encounter issues when called upon with some frequency.

If you need to know how many shards, read
[ElasticSearch's documentation on capacity planning](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html),
as the answer is not straight forward.

The easiest way to determine if sharding is in use is to check the output of the
[ElasticSearch Health API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html):

- Red means the cluster is down.
- Yellow means it is up with no sharding/replication.
- Green means it is healthy (up, sharding, replicating).

For production use, it should always be green.

Beyond these steps, you get into some of the more complicated things to check,
such as merges and caching. These can get complicated and it takes some time to
learn them, so it is best to escalate/pair with an ElasticSearch expert if you need to
dig further into these.

Feel free to reach out to GitLab support, but this is likely to be something a skilled
ElasticSearch admin has more experience with.

## Common issues

All common issues [should be documented](../../integration/elasticsearch.md#troubleshooting). If not,
feel free to update that page with issues you encounter and solutions.

## Replication

Setting up ElasticSearch isn't too bad, but it can be a bit finnicky and time consuming.

The eastiest method is to spin up a docker container with the required version and
bind ports 9200/9300 so it can be used.

The following is an example of running a docker container of ElasticSearch v7.2.0:

```bash
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.2.0
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.2.0
```

From here, you can:

- Grab the IP of the docker container (use `docker inspect <container_id>`)
- Use `<IP.add.re.ss:9200>` to communicate with it.

This is a quick method to test out ElasticSearch, but by no means is this a
production solution.
