---
comments: false
description: 'Database Testing'
---

# Database Testing

We have identified [common themes of reverted migrations](https://gitlab.com/gitlab-org/gitlab/-/issues/233391) and discovered failed migrations breaking in both production and staging even when successfully tested in a developer environment. We have also experienced production incidents even with successful testing in staging. These failures are quite expensive: they can have a significant effect on availability, block deployments, and generate incident escalations. These escalations must be triaged and either reverted or fixed forward. Often, this can take place without the original author's involvement due to time zones and/or the criticality of the escalation. With our increased deployment speeds and stricter uptime requirements, the need for improving database testing is critical, particularly earlier in the development process (shift left).

From a developer's perspective, it is hard, if not unfeasible, to validate a migration on a large enough dataset before it goes into production.

Our primary goal is to **provide developers with immediate feedback for new migrations and other database-related changes tested on a full copy of the production database**, and to do so with high levels of efficiency (particularly in terms of infrastructure costs) and security.

## Current day

Developers are expected to test database migrations prior to deploying to any environment, but we lack the ability to perform testing against large environments such as GitLab.com. The [developer database migration style guide](../../../development/migration_style_guide.md) provides guidelines on migrations, and we focus on validating migrations during code review and testing in CI and staging.

The [code review phase](../../../development/database_review.md) involves Database Reviewers and Maintainers to manually check the migrations committed. This often involves knowing and spotting problematic patterns and their particular behavior on GitLab.com from experience. There is no large-scale environment available that allows us to test database migrations before they are being merged.

Testing in CI is done on a very small database. We mainly check forward/backward migration consistency, evaluate Rubocop rules to detect well-known problematic behaviors (static code checking) and have a few other, rather technical checks in place (adding the right files etc). That is, we typically find code or other rather simple errors, but cannot surface any data related errors - which are also typically not covered by unit tests either.

Once merged, migrations are being deployed to the staging environment. Its database size is less than 5% of the production database size as of January 2021 and its recent data distribution does not resemble the production site. Oftentimes, we see migrations succeed in staging but then fail in production due to query timeouts or other unexpected problems. Even if we caught problems in staging, this is still expensive to reconcile and ideally we want to catch those problems as early as possible in the development cycle.

Today, we have gained experience with working on a thin-cloned production database (more on this below) and already use it to provide developers with access to production query plans, automated query feedback and suggestions with optimizations. This is built around [Database Lab](https://gitlab.com/postgres-ai/database-lab) and [Joe](https://gitlab.com/postgres-ai/joe), both available through Slack (using ChatOps) and [postgres.ai](https://postgres.ai/).

## Vision

As a developer:

1. I am working on a GitLab code change that includes a data migration and changes a heavy database query.
1. I push my code, create a merge request, and provide an example query in the description.
1. The pipeline executes the data migration and examines the query in a large-scale environment (a copy of GitLab.com).
1. Once the pipeline finishes, the merge request gets detailed feedback and information about the migration and the query I provided. This is based on a full clone of the production database with a state that is very close to production (minutes).

For database migrations, the information gathered from execution on the clone includes:

- Overall runtime.
- Detailed statistics for queries being executed in the migration (normalizing queries and showing their frequencies and execution times as plots).
- Dangerous locks held during the migration (which would cause blocking situations in production).

For database queries, we can automatically gather:

- Query plans along with visualization.
- Execution times and predictions for production.
- Suggestions on optimizations from Joe.
- Memory and IO statistics.

After having gotten that feedback:

1. I can go back and investigate a performance problem with the data migration.
1. Once I have a fix pushed, I can repeat the above cycle and eventually send my merge request for database review. During the database review, the database reviewer and maintainer have all the additional generated information available to them to make an informed decision on the performance of the introduced changes.

This information gathering is done in a protected and safe environment, making sure that there is no unauthorized access to production data and we can safely execute code in this environment.

The intended benefits include:

- Shifting left: Allow developers to understand large-scale database performance and what to expect to happen on GitLab.com in a self-service manner
- Identify errors that are only generated when working against a production scale dataset with real data (with inconsistencies or unexpected patterns)
- Automate the information gathering phase to make it easier for everybody involved in code review (developer, reviewer, maintainer) by providing relevant details automatically and upfront.

## Technology and next steps

We already use Database Lab from [postgres.ai](https://postgres.ai/), which is a thin-cloning technology. We maintain a PostgreSQL replica which is up to date with production data but does not serve any production traffic. This runs Database Lab which allows us to quickly create a full clone of the production dataset (in the order of seconds).

Internally, this is based on ZFS and implements a "thin-cloning technology". That is, ZFS snapshots are being used to clone the data and it exposes a full read/write PostgreSQL cluster based on the cloned data. This is called a *thin clone*. It is rather short lived and is going to be destroyed again shortly after we are finished using it.

It is important to note that a thin clone is fully read/write. This allows us to execute migrations on top of it.

Database Lab provides an API we can interact with to manage thin clones. In order to automate the migration and query testing, we add steps to the `gitlab/gitlab-org` CI pipeline. This triggers automation that performs the following steps for a given merge request:

1. Create a thin-clone with production data for this testing session.
1. Pull GitLab code from the merge request.
1. Execute migrations and gather all necessary information from it.
1. Execute query testing and gather all necessary information from it.
1. Post back the results of the migration and query testing to the merge request.
1. Destroy the thin-clone.

### Short-term

The short-term focus is on testing regular migrations (typically schema changes) and using the existing Database Lab instance from postgres.ai for it.

In order to secure this process and meet compliance goals, the runner environment is treated as a *production* environment and similarly locked down, monitored and audited. Only Database Maintainers have access to the CI pipeline and its job output. Everyone else can only see the results and statistics posted back on the merge request.

We implement a secured CI pipeline on <https://ops.gitlab.net> that adds the execution steps outlined above. The goal is to secure this pipeline in order to solve the following problem:

Make sure we strongly protect production data, even though we allow everyone (GitLab team/developers) to execute arbitrary code on the thin-clone which contains production data.

This is in principle achieved by locking down the GitLab Runner instance executing the code and its containers on a network level, such that no data can escape over the network. We make sure no communication can happen to the outside world from within the container executing the GitLab Rails code (and its database migrations).

Furthermore, we limit the ability to view the results of the jobs (including the output printed from code) to Maintainer and Owner level on the <https://ops.gitlab.net> pipeline and provide only a high level summary back to the original MR. If there are issues or errors in one of the jobs run, the database Maintainer assigned to review the MR can check the original job for more details.

With this step implemented, we already have the ability to execute database migrations on the thin-cloned GitLab.com database automatically from GitLab CI and provide feedback back to the merge request and the developer. The content of that feedback is expected to evolve over time and we can continuously add to this.

We already have an [MVC-style implementation for the pipeline](https://gitlab.com/gitlab-org/database-team/gitlab-com-migrations) for reference and an [example merge request with feedback](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50793#note_477815261) from the pipeline.

The short-term goal is detailed in [this epic](https://gitlab.com/groups/gitlab-org/database-team/-/epics/6).

### Mid-term - Improved feedback, query testing and background migration testing

Mid-term, we plan to expand the level of detail the testing pipeline reports back to the Merge Request and expand its scope to cover query testing, too. By doing so, we use our experience from database code reviews and using thin-clone technology and bring this back closer to the GitLab workflow. Instead of reaching out to different tools (`postgres.ai`, `joe`, Slack, plan visualizations, and so on) we bring this back to GitLab and working directly on the Merge Request.

Secondly, we plan to cover background migrations testing, too. These are typically data migrations that are scheduled to run over a long period of time. The success of both the scheduling phase and the job execution phase typically depends a lot on data distribution - which only surfaces when running these migrations on actual production data. In order to become confident about a background migration, we plan to provide the following feedback:

1. Scheduling phase - query statistics (for example a histogram of query execution times), job statistics (how many jobs, overall duration, and so on), batch sizes.
1. Execution phase - using a few instances of a job as examples, we execute those to gather query and runtime statistics.

### Long-term - incorporate into GitLab product

There are opportunities to discuss for extracting features from this into GitLab itself. For example, annotating the Merge Request with query examples and attaching feedback gathered from the testing run can become a first-class citizen instead of using Merge Request description and comments for it. We plan to evaluate those ideas as we see those being used in earlier phases and bring our experience back into the product.

## An alternative discussed: Anonymization

At the core of this problem lies the concern about executing (potentially arbitrary) code on a production dataset and making sure the production data is well protected. The approach discussed above solves this by strongly limiting access to the output of said code.

An alternative approach we have discussed and abandoned is to "scrub" and anonymize production data. The idea is to remove any sensitive data from the database and use the resulting dataset for database testing. This has a lot of downsides which led us to abandon the idea:

- Anonymization is complex by nature - it is a hard problem to call a "scrubbed clone" actually safe to work with in public. Different data types may require different anonymization techniques (for example, anonymizing sensitive information inside a JSON field) and only focusing on one attribute at a time does not guarantee that a dataset is fully anonymized (for example join attacks or using timestamps in conjunction to public profiles/projects to de-anonymize users by there activity).
- Anonymization requires an additional process to keep track and update the set of attributes considered as sensitive, ongoing maintenance and security reviews every time the database schema changes.
- Annotating data as "sensitive" is error prone, with the wrong anonymization approach used for a data type or one sensitive attribute accidentally not marked as such possibly leading to a data breach.
- Scrubbing not only removes sensitive data, but it also changes data distribution, which greatly affects performance of migrations and queries.
- Scrubbing heavily changes the database contents, potentially updating a lot of data, which leads to different data storage details (think MVC bloat), affecting performance of migrations and queries.

## Who

<!-- vale gitlab.Spelling = NO -->

This effort is owned and driven by the [GitLab Database Team](https://about.gitlab.com/handbook/engineering/development/enablement/database/) with support from the [GitLab.com Reliability Datastores](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/datastores/) team.

| Role                         | Who
|------------------------------|-------------------------|
| Author                       |    Andreas Brandl       |
| Architecture Evolution Coach | Gerardo Lopez-Fernandez |
| Engineering Leader           |    Craig Gomes          |
| Domain Expert                |    Yannis Roussos       |
| Domain Expert                |    Pat Bair             |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Product                      |    Fabian Zimmer       |
| Leadership                   |    Craig Gomes         |
| Engineering                  |    Andreas Brandl      |

<!-- vale gitlab.Spelling = YES -->
