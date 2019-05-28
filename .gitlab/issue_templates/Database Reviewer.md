#### Database Reviewer Checklist

Thank you for becoming a ~database reviewer! Please work on the list
below to complete your setup. For any question, reach out to #database
an mention `@abrandl`.

- [ ] Change issue title to include your name: `Database Reviewer Checklist: Your Name`
- [ ] Review general [code review guide](https://docs.gitlab.com/ee/development/code_review.html)
- [ ] Review [database review documentation](https://about.gitlab.com/handbook/engineering/workflow/code-review/database.html)
- [ ] Familiarize with [migration helpers](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/database/migration_helpers.rb) and review usage in existing migrations
- [ ] Read [database migration style guide](https://docs.gitlab.com/ee/development/migration_style_guide.html)
- [ ] Familiarize with best practices in [database guides](https://docs.gitlab.com/ee/development/#database-guides)
- [ ] Watch [Optimising Rails Database Queries: Episode 1](https://www.youtube.com/watch?v=79GurlaxhsI)
- [ ] Read [Understanding EXPLAIN plans](https://docs.gitlab.com/ee/development/understanding_explain_plans.html)
- [ ] Review [database best practices](https://docs.gitlab.com/ee/development/#best-practices)
- [ ] Review how we use [database instances restored from a backup](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd) for testing and make sure you're set up to execute pipelines (check [README.md](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/blob/master/README.md) and reach out to @abrandl since this is currently subject to being changed)
- [ ] Get yourself added to [`@gl-database`](https://gitlab.com/groups/gl-database/-/group_members) group and respond to @-mentions to the group (reach out to any maintainer on the group to get added). You will get TODOs on gitlab.com for group mentions.
- [ ] Make sure you have proper access to at least a read-only replica in staging and production
- [ ] Indicate in `data/team.yml` your role as a database reviewer ([example MR](https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/19600/diffs)). Assign MR to your manager for merge.
- [ ] Send one MR to improve the [review documentation](https://about.gitlab.com/handbook/engineering/workflow/code-review/database.html) or the [issue template](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab/issue_templates/Database%20Reviewer.md)

Note that *approving and accepting* merge requests is *restricted* to
Database Maintainers only. As a reviewer, pass the MR to a maintainer
for approval.

You're all set! Watch out for TODOs on GitLab.com.

###### Where to go for questions?

Reach out to `#database` on Slack and mention `@abrandl` for any questions.

cc @abrandl

/label ~meta ~database
