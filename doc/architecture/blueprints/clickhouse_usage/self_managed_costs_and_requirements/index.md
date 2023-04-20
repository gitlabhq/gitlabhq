---
status: proposed
creation-date: "2023-04-04"
authors: [ "@niskhakova", "@dmakovey" ]
coach: "@grzesiek"
approvers: [ "@dorrino", "@nhxnguyen" ]
owning-stage: "~workinggroup::clickhouse"
participating-stages: ["~section::enablement"]
---

# ClickHouse Self-Managed component costs and maintenance requirements

## Summary

[ClickHouse](https://clickhouse.com/) requires additional cost and maintenance for self-managed customers:

- **Resource allocation cost**: ClickHouse requires a considerable amount of resources to run optimally.
  - [Minimum cost estimation](#minimum-self-managed-component-costs) shows that setting up ClickHouse can be applicable only for very large Reference Architectures: 25k and up.
- **High availability**: ClickHouse SaaS supports HA. No documented HA configuration for self-managed at the moment.
- **Geo setups**: Sync and replication complexity for GitLab Geo setups.
- **Upgrades**: An additional database to maintain and upgrade along with existing Postgres database. This also includes compatibility issues of mapping GitLab version to ClickHouse version and keeping them up-to-date.
- **Backup and restore:** Self-managed customers need to have an engineer who is familiar with backup strategies and disaster recovery process in ClickHouse or switch to ClickHouse SaaS.
- **Monitoring**: ClickHouse can use Prometheus, additional component to monitor and troubleshoot.
- **Limitations**: Azure object storage is not supported. GitLab does not have the documentation or support expertise to assist customers with deployment and operation of self-managed ClickHouse.
- **ClickHouse SaaS**: Customers using a self-managed GitLab instance with regulatory or compliance requirements, or latency concerns likely cannot use ClickHouse SaaS.

### Minimum self-managed component costs

Based on [ClickHouse spec requirements](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/14384#note_1307456092) analysis
and collaborating with ClickHouse team, we identified the following minimal configurations for ClickHouse self-managed:

1. ClickHouse High Availability (HA)
    - ClickHouse - 2 machines with >=16-cores, >=64 GB RAM, SSD, 10 GB Internet. Each machine also runs Keeper.
    - [Keeper](https://clickhouse.com/docs/en/guides/sre/keeper/clickhouse-keeper) - 1 machine with 2 CPU, 4 GB of RAM, SSD with high IOPS
1. ClickHouse non-HA
    - ClickHouse - 1 machine with >=16-cores, >=64 GB RAM, SSD, 10 GB Internet.

The following [cost table](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/14384#note_1324085466) was compiled using the machine CPU and memory requirements for ClickHouse, and comparing them to the
GitLab Reference Architecture sizes and [costs](../../../../administration/reference_architectures/index.md#cost-to-run) from the GCP calculator.

| Reference Architecture  | ClickHouse type | ClickHouse cost / (GitLab cost + ClickHouse cost) |
|-------------|-----------------|-----------------------------------|
| [1k - non HA](https://cloud.google.com/products/calculator#id=a6d6a94a-c7dc-4c22-85c4-7c5747f272ed) | [non-HA](https://cloud.google.com/products/calculator#id=9af5359e-b155-451c-b090-5f0879bb591e)          | 78.01%                            |
| [2k - non HA](https://cloud.google.com/products/calculator#id=0d3aff1f-ea3d-43f9-aa59-df49d27c35ca) | [non-HA](https://cloud.google.com/products/calculator#id=9af5359e-b155-451c-b090-5f0879bb591e)          | 44.50%                            |
| [3k - HA](https://cloud.google.com/products/calculator/#id=15fc2bd9-5b1c-479d-bc46-d5ce096b8107)     | [HA](https://cloud.google.com/products/calculator#id=9909f5af-d41a-4da2-b8cc-a0347702a823)              | 37.87%                            |
| [5k - HA](https://cloud.google.com/products/calculator/#id=9a798136-53f2-4c35-be43-8e1e975a6663)     | [HA](https://cloud.google.com/products/calculator#id=9909f5af-d41a-4da2-b8cc-a0347702a823)              | 30.92%                           |
| [10k - HA](https://cloud.google.com/products/calculator#id=cbe61840-31a1-487f-88fa-631251c2fde5)   | [HA](https://cloud.google.com/products/calculator#id=9909f5af-d41a-4da2-b8cc-a0347702a823)              | 20.47%                            |
| [25k - HA](https://cloud.google.com/products/calculator#id=b4b8b587-508a-4433-adc8-dc506bbe924f)    | [HA](https://cloud.google.com/products/calculator#id=9909f5af-d41a-4da2-b8cc-a0347702a823)              | 14.30%                            |
| [50k - HA](https://cloud.google.com/products/calculator/#id=48b4d817-d6cd-44b8-b069-0ba9a5d123ea)    | [HA](https://cloud.google.com/products/calculator#id=9909f5af-d41a-4da2-b8cc-a0347702a823)              | 8.16%                            |

NOTE:
The ClickHouse Self-Managed component evaluation is the minimum estimation for the costs
with a simplified architecture.

The following components increase the cost, and were not considered in the minimum calculation:

- Disk size - depends on data size, hard to estimate.
- Disk types - ClickHouse recommends [fast SSDs](https://clickhouse.com/docs/ru/operations/tips#storage-subsystem).
- Network usage - ClickHouse recommends using [10 GB network, if possible](https://clickhouse.com/docs/en/operations/tips#network).
- For HA we sum minimum cost across all reference architectures from 3k to 50k users, but HA specs tend to increase with user count.

### Resources

- [Research and understand component costs and maintenance requirements of running a ClickHouse instance with GitLab](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/14384)
- [ClickHouse for Error Tracking on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/library/database/clickhouse/index.md)
