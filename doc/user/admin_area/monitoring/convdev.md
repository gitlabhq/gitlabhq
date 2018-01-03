# Conversational Development Index

> [Introduced][ce-30469] in GitLab 9.3.

Conversational Development Index (ConvDev) gives you an overview of your entire
instance's feature usage, from idea to production. It looks at your usage in the
past 30 days, averaged over the number of active users in that time period. It also
provides a lead score per feature, which is calculated based on GitLab's analysis
of top performing instances, based on [usage ping data][ping] that GitLab has
collected. Your score is compared to the lead score, expressed as a percentage.
The overall index score is an average over all your feature scores.

![ConvDev index](img/convdev_index.png)

The page also provides helpful links to articles and GitLab docs, to help you
improve your scores.

Your GitLab instance's usage ping must be activated in order to use this feature.
Usage ping data is aggregated on GitLab's servers for analysis. Your usage
information is **not sent** to any other GitLab instances.

If you have just started using GitLab, it may take a few weeks for data to be
collected before this feature is available.

This feature is accessible only to a system admin, at
**Admin area > Overview > ConvDev Index**.

[ce-30469]: https://gitlab.com/gitlab-org/gitlab-ce/issues/30469
[ping]: ../settings/usage_statistics.md#usage-ping
