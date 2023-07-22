---
status: proposed
creation-date: "2023-01-25"
authors: [ "@pedropombeiro", "@vshushlin"]
coach: "@grzesiek"
approvers: [  ]
stage: Verify
group: Runner
participating-stages: []
---

# CI Builds and Runner Fleet metrics database architecture

The CI section envisions new value-added features in GitLab for CI Builds and Runner Fleet focused on observability and automation. However, implementing these features and delivering on the product vision of observability, automation, and AI optimization using the current database architecture in PostgreSQL is very hard because:

- CI-related transactional tables are huge, so any modification to them can increase the load on the database and subsequently cause incidents.
- PostgreSQL is not optimized for running aggregation queries.
- We also want to add more information from the build environment, making CI tables even larger.
- We also need a data model to aggregate data sets for the GitLab CI efficiency machine learning models - the basis of the Runner Fleet AI solution

We want to create a new flexible database architecture which:

- will support known reporting requirements for CI builds and Runner Fleet.
- can be used to ingest data from the CI build environment.

We may also use this database architecture to facilitate development of AI features in the future.

Our recent usability research on navigation and other areas suggests that the GitLab UI is overloaded with information and navigational elements.
This results from trying to add as much information as possible and attempting to place features in the most discoverable places.
Therefore, while developing these new observability features, we will rely on the jobs to be done research, and solution validation, to ensure that the features deliver the most value.

## Runner Fleet

### Metrics - MVC

#### What is the estimated wait time in queue for an instance runner?

The following customer problems should be solved when addressing this question. Most of them are quotes from our usability research

**UI**

- "There is no visibility for expected Runner queue wait times."
- "I got here looking for a view that makes it more obvious if I have a bottleneck on my specific runner."

**Types of metrics**

- "Is it possible to get metrics out of GitLab to check for the runners availability & pipeline wait times?
  Goal - we need the data to evaluate the data to determine if to scale up the Runner fleet so that there is no waiting times for developer’s pipelines."
- "What is the estimated time in the Runner queue before a job can start?"

**Interpreting metrics**

- "What metrics for Runner queue performance should I look at and how do I interpret the metrics and take action?"
- "I want to be able to analyze data on Runner queue performance over time so that I can determine if the reports are from developers are really just rare cases regarding availability."

#### What is the estimated wait time in queue on a group runner?

#### What is the mean estimated wait time in queue for all instance runners?

#### What is the mean estimated wait time in queue for all group runners?

#### Which runners have failures in the past hour?

## Implementation plan

We're currently in the research stage, and working on the [Proof of Concept](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126863)
around Clickhouse. You can follow [this epic](https://gitlab.com/groups/gitlab-org/-/epics/10682) for more up-to-date status.
