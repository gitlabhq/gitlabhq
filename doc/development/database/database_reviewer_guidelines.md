---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Database Reviewer Guidelines

This page includes introductory material for new database reviewers.

If you are interested in getting an application update reviewed,
check the [database review guidelines](../database_review.md).

## Scope of work done by a database reviewer

Database reviewers are domain experts who have substantial experience with databases,
`SQL`, and query performance optimization.

A database review is required whenever an application update [touches the database](../database_review.md#general-process).

The database reviewer is tasked with reviewing the database specific updates and
making sure that any queries or modifications will perform without issues
at the scale of GitLab.com.

For more information on the database review process, check the [database review guidelines](../database_review.md).

## How to apply for becoming a database reviewer

Team members are encouraged to self-identify as database domain experts and add it to their [team profile](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/team.yml)

```yaml
projects:
  gitlab:
    - reviewer database
```

Assign the MR which adds your expertise to the `team.yml` file to a database maintainer
or the [Database Team's Engineering Manager](https://about.gitlab.com/handbook/engineering/development/enablement/database/).

Once the `team.yml` update is merged, the [Reviewer roulette](../code_review.md#reviewer-roulette)
may recommend you as a database reviewer.

## Resources for database reviewers

As a database reviewer, join the internal `#database` Slack channel and ask questions or discuss
database related issues with other database reviewers and maintainers.

There is also an optional database office hours call held bi-weekly, alternating between
European/US and APAC friendly hours. You can join the office hours call and bring topics
that require a more in-depth discussion between the database reviewers and maintainers:

- [Database Office Hours Agenda](https://docs.google.com/document/d/1wgfmVL30F8SdMg-9yY6Y8djPSxWNvKmhR5XmsvYX1EI/edit).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [YouTube playlist with past recordings](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp-kqXeiF7fF7cFYaKtdqXM).

You should also join the [#database-lab](../understanding_explain_plans.md#database-lab-engine)
Slack channel and get familiar with how to use Joe, the Slackbot that provides developers
with their own clone of the production database.

Understanding and efficiently using `EXPLAIN` plans is at the core of the database review process.
The following guides provide a quick introduction and links to follow on more advanced topics:

- Guide on [understanding EXPLAIN plans](../understanding_explain_plans.md).
- [Explaining the unexplainable series in `depesz`](https://www.depesz.com/tag/unexplainable/).

We also have licensed access to The Art of PostgreSQL available, if you are interested in getting access please check out the
[issue (confidential)](https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/23).

Finally, you can find various guides in the [Database guides](index.md) page that cover more specific
topics and use cases. The most frequently required during database reviewing are the following:

- [Migrations style guide](../migration_style_guide.md) for creating safe SQL migrations.
- [Avoiding downtime in migrations](../avoiding_downtime_in_migrations.md).
- [SQL guidelines](../sql.md) for working with SQL queries.

## How to apply for becoming a database maintainer

Once a database reviewer feels confident on switching to a database maintainer,
they can update their [team profile](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/team.yml)
to a `trainee_maintainer database`:

```yaml
projects:
  gitlab:
    - trainee_maintainer database
```

The first step is to a create a [Trainee Database Maintainer Issue](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/new?issuable_template=trainee-database-maintainer).
Use and follow the process described in the 'Trainee database maintainer' template.

Note that [trainee maintainers](https://about.gitlab.com/handbook/engineering/workflow/code-review/#trainee-maintainer)
are three times as likely to be picked by the [Danger bot](../dangerbot.md) as other reviewers.

## What to do if you feel overwhelmed

Similar to all types of reviews, [unblocking others is always a top priority](https://about.gitlab.com/handbook/values/#global-optimization).
Database reviewers are expected to [review assigned merge requests in a timely manner](../code_review.md#review-turnaround-time)
or let the author know as soon as possible and help them find another reviewer or maintainer.

We are doing reviews to help the rest of the GitLab team and, at the same time, get exposed
to more use cases, get a lot of insights and hone our database and data management skills.

If you are feeling overwhelmed, think you are at capacity, and are unable to accept any more
reviews until some have been completed, communicate this through your GitLab status by setting
the `:red_circle:` emoji and mentioning that you are at capacity in the status text.
