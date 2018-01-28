---
last_updated: 2017-10-05
---

# Migrating from MySQL to PostgreSQL

> **Note:** This guide assumes you have a working Omnibus GitLab instance with
> MySQL and want to migrate to bundled PostgreSQL database.

## Prerequisites

First, we'll need to enable the bundled PostgreSQL database with up-to-date
schema. Next, we'll use [pgloader](http://pgloader.io) to migrate the data
from the old MySQL database to the new PostgreSQL one.

Here's what you'll need to have installed:

- pgloader 3.4.1+
- Omnibus GitLab
- MySQL

## Enable bundled PostgreSQL database

1. Stop GitLab:

    ``` bash
    sudo gitlab-ctl stop
    ```

1. Edit `/etc/gitlab/gitlab.rb` to enable bundled PostgreSQL:

    ```
    postgresql['enable'] = true
    ```

1. Edit `/etc/gitlab/gitlab.rb` to use the bundled PostgreSQL. Please check
   all the settings beginning with `db_`, such as `gitlab_rails['db_adapter']`
   and alike. You could just comment all of them out so that we'll just use
   the defaults.

1. [Reconfigure GitLab] for the changes to take effect:

    ``` bash
    sudo gitlab-ctl reconfigure
    ```

1. Start Unicorn and PostgreSQL so that we can prepare the schema:

    ``` bash
    sudo gitlab-ctl start unicorn
    sudo gitlab-ctl start postgresql
    ```

1. Run the following commands to prepare the schema:

    ``` bash
    sudo gitlab-rake db:create db:migrate
    ```

1. Stop Unicorn to prevent other database access from interfering with the loading of data:

    ``` bash
    sudo gitlab-ctl stop unicorn
    ```

After these steps, you'll have a fresh PostgreSQL database with up-to-date schema.

## Migrate data from MySQL to PostgreSQL

Now, you can use pgloader to migrate the data from MySQL to PostgreSQL:

1. Save the following snippet in a `commands.load` file, and edit with your
   database `username`, `password` and `host`:

    ```
    LOAD DATABASE
         FROM mysql://username:password@host/gitlabhq_production
         INTO postgresql://gitlab-psql@unix://var/opt/gitlab/postgresql:/gitlabhq_production

    WITH include no drop, truncate, disable triggers, create no tables,
         create no indexes, preserve index names, no foreign keys,
         data only

    ALTER SCHEMA 'gitlabhq_production' RENAME TO 'public'

    ;
    ```

1. Start the migration:

    ``` bash
    sudo -u gitlab-psql pgloader commands.load
    ```

1. Once the migration finishes, you should see a summary table that looks like
the following:


    ```
                                     table name       read   imported     errors      total time
    -----------------------------------------------  ---------  ---------  ---------  --------------
                                    fetch meta data        119        119          0          0.388s
                                           Truncate        119        119          0          1.134s
    -----------------------------------------------  ---------  ---------  ---------  --------------
                               public.abuse_reports          0          0          0          0.490s
                                 public.appearances          0          0          0          0.488s
                                   public.approvals          0          0          0          0.273s
                        public.application_settings          1          1          0          0.266s
                                   public.approvers          0          0          0          0.339s
                             public.approver_groups          0          0          0          0.357s
                                public.audit_events          1          1          0          0.410s
                                 public.award_emoji          0          0          0          0.441s
                                      public.boards          0          0          0          0.505s
                          public.broadcast_messages          0          0          0          0.498s
                                  public.chat_names          0          0          0          0.576s
                                  public.chat_teams          0          0          0          0.617s
                                   public.ci_builds          0          0          0          0.611s
                          public.ci_group_variables          0          0          0          0.620s
                                public.ci_pipelines          0          0          0          0.599s
                       public.ci_pipeline_schedules          0          0          0          0.622s
              public.ci_pipeline_schedule_variables          0          0          0          0.573s
                       public.ci_pipeline_variables          0          0          0          0.594s
                                  public.ci_runners          0          0          0          0.533s
                          public.ci_runner_projects          0          0          0          0.584s
                        public.ci_sources_pipelines          0          0          0          0.564s
                                   public.ci_stages          0          0          0          0.595s
                                 public.ci_triggers          0          0          0          0.569s
                         public.ci_trigger_requests          0          0          0          0.596s
                                public.ci_variables          0          0          0          0.565s
                      public.container_repositories          0          0          0          0.605s
    public.conversational_development_index_metrics          0          0          0          0.571s
                                 public.deployments          0          0          0          0.607s
                                      public.emails          0          0          0          0.602s
                        public.deploy_keys_projects          0          0          0          0.557s
                                      public.events        160        160          0          0.677s
                                public.environments          0          0          0          0.567s
                                    public.features          0          0          0          0.639s
                        public.events_for_migration        160        160          0          0.582s
                               public.feature_gates          0          0          0          0.579s
                        public.forked_project_links          0          0          0          0.660s
                                   public.geo_nodes          0          0          0          0.686s
                               public.geo_event_log          0          0          0          0.626s
             public.geo_repositories_changed_events          0          0          0          0.677s
                    public.geo_node_namespace_links          0          0          0          0.618s
               public.geo_repository_renamed_events          0          0          0          0.696s
                                    public.gpg_keys          0          0          0          0.704s
               public.geo_repository_deleted_events          0          0          0          0.638s
                             public.historical_data          0          0          0          0.729s
               public.geo_repository_updated_events          0          0          0          0.634s
                              public.index_statuses          0          0          0          0.746s
                              public.gpg_signatures          0          0          0          0.667s
                             public.issue_assignees         80         80          0          0.769s
                                  public.identities          0          0          0          0.655s
                               public.issue_metrics         80         80          0          0.781s
                                      public.issues         80         80          0          0.720s
                                      public.labels          0          0          0          0.795s
                                 public.issue_links          0          0          0          0.707s
                            public.label_priorities          0          0          0          0.793s
                                        public.keys          0          0          0          0.734s
                                 public.lfs_objects          0          0          0          0.812s
                                 public.label_links          0          0          0          0.725s
                                    public.licenses          0          0          0          0.813s
                            public.ldap_group_links          0          0          0          0.751s
                                     public.members         52         52          0          0.830s
                        public.lfs_objects_projects          0          0          0          0.738s
               public.merge_requests_closing_issues          0          0          0          0.825s
                                       public.lists          0          0          0          0.769s
                  public.merge_request_diff_commits          0          0          0          0.840s
                       public.merge_request_metrics          0          0          0          0.837s
                              public.merge_requests          0          0          0          0.753s
                         public.merge_request_diffs          0          0          0          0.771s
                                  public.namespaces         30         30          0          0.874s
                    public.merge_request_diff_files          0          0          0          0.775s
                                       public.notes          0          0          0          0.849s
                                  public.milestones         40         40          0          0.799s
                         public.oauth_access_grants          0          0          0          0.979s
                        public.namespace_statistics          0          0          0          0.797s
                          public.oauth_applications          0          0          0          0.899s
                       public.notification_settings         72         72          0          0.818s
                         public.oauth_access_tokens          0          0          0          0.807s
                               public.pages_domains          0          0          0          0.958s
                       public.oauth_openid_requests          0          0          0          0.832s
                      public.personal_access_tokens          0          0          0          0.965s
                                    public.projects          8          8          0          0.987s
                                  public.path_locks          0          0          0          0.925s
                                       public.plans          0          0          0          0.923s
                            public.project_features          8          8          0          0.985s
                      public.project_authorizations         66         66          0          0.969s
                         public.project_import_data          8          8          0          1.002s
                          public.project_statistics          8          8          0          1.001s
                         public.project_group_links          0          0          0          0.949s
                         public.project_mirror_data          0          0          0          0.972s
        public.protected_branch_merge_access_levels          0          0          0          1.017s
                          public.protected_branches          0          0          0          0.969s
         public.protected_branch_push_access_levels          0          0          0          0.991s
                              public.protected_tags          0          0          0          1.009s
          public.protected_tag_create_access_levels          0          0          0          0.985s
                         public.push_event_payloads          0          0          0          1.041s
                                  public.push_rules          0          0          0          0.999s
                             public.redirect_routes          0          0          0          1.020s
                              public.remote_mirrors          0          0          0          1.034s
                                    public.releases          0          0          0          0.993s
                           public.schema_migrations        896        896          0          1.057s
                                      public.routes         38         38          0          1.021s
                                    public.services          0          0          0          1.055s
                          public.sent_notifications          0          0          0          1.003s
                          public.slack_integrations          0          0          0          1.022s
                                   public.spam_logs          0          0          0          1.024s
                                    public.snippets          0          0          0          1.058s
                               public.subscriptions          0          0          0          1.069s
                                    public.taggings          0          0          0          1.099s
                                    public.timelogs          0          0          0          1.104s
                        public.system_note_metadata          0          0          0          1.038s
                                        public.tags          0          0          0          1.034s
                           public.trending_projects          0          0          0          1.140s
                                     public.uploads          0          0          0          1.129s
                                       public.todos         80         80          0          1.085s
                         public.users_star_projects          0          0          0          1.153s
                           public.u2f_registrations          0          0          0          1.061s
                                   public.web_hooks          0          0          0          1.179s
                                       public.users         26         26          0          1.163s
                          public.user_agent_details          0          0          0          1.068s
                               public.web_hook_logs          0          0          0          1.080s
    -----------------------------------------------  ---------  ---------  ---------  --------------
                            COPY Threads Completion          4          4          0          2.008s
                                    Reset Sequences        113        113          0          0.304s
                                   Install Comments          0          0          0          0.000s
    -----------------------------------------------  ---------  ---------  ---------  --------------
                                  Total import time       1894       1894          0         12.497s
    ```

    If there is no output for more than 30 minutes, it's possible pgloader encountered an error. See
    the [troubleshooting guide](#Troubleshooting) for more details.

1. Start GitLab:

    ``` bash
    sudo gitlab-ctl start
    ```

Now, you can verify that everything worked by visiting GitLab.

## Troubleshooting

### Permissions

Note that the PostgreSQL user that you use for the above MUST have **superuser** privileges. Otherwise, you may see
a similar message to the following:

```
debugger invoked on a CL-POSTGRES-ERROR:INSUFFICIENT-PRIVILEGE in thread
    #<THREAD "lparallel" RUNNING {10078A3513}>:
      Database error 42501: permission denied: "RI_ConstraintTrigger_a_20937" is a system trigger
    QUERY: ALTER TABLE ci_builds DISABLE TRIGGER ALL;
    2017-08-23T00:36:56.782000Z ERROR Database error 42501: permission denied: "RI_ConstraintTrigger_c_20864" is a system trigger
    QUERY: ALTER TABLE approver_groups DISABLE TRIGGER ALL;
```

### Experiencing 500 errors after the migration

If you experience 500 errors after the migration, try to clear the cache:

``` bash
sudo gitlab-rake cache:clear
```

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
