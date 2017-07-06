# Performance Bar

A Performance Bar can be displayed, to dig into the performance of a page. When
activated, it looks as follows:

![Performance Bar](img/performance_bar.png)

It allows you to:

- see the current host serving the page
- see the timing of the page (backend, frontend)
- the number of DB queries, the time it took, and the detail of these queries
![SQL profiling using the Performance Bar](img/performance_bar_sql_queries.png)
- the number of calls to Redis, and the time it took
- the number of background jobs created by Sidekiq, and the time it took
- the number of Ruby GC calls, and the time it took
- profile the code used to generate the page, line by line
![Line profiling using the Performance Bar](img/performance_bar_line_profiling.png)

## Enable the Performance Bar via the Admin panel

GitLab Performance Bar is disabled by default. To enable it for a given group,
navigate to the Admin area in **Settings > Profiling - Performance Bar**
(`/admin/application_settings`).

The only required setting you need to set is the full path of the group that
will be allowed to display the Performance Bar.
Make sure _Enable the Performance Bar_ is checked and hit
**Save** to save the changes.

---

![GitLab Performance Bar Admin Settings](img/performance_bar_configuration_settings.png)

---

## Enable the Performance Bar via the API

Under the hood, the Performance Bar activation is done via the `performance_bar`
[Feature Flag](../../../development/features_flags.md).

That means you can also enable or disable it via the
[Features API](../../../api/features.md#set-or-create-a-feature).

### For the `performance_team` feature group

The `performance_team` feature group maps to the group specified in your [Admin
area](#enable-the-performance-bar-via-the-admin-panel).

```
curl --data "feature_group=performance_team" --data "value=true" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/features/performance_bar
```

### For specific users

It's also possible to enable the Performance Bar for specific users in addition
to a group, or even instead of a group:

```
curl --data "user=my_username" --data "value=true" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/features/performance_bar
```

[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
