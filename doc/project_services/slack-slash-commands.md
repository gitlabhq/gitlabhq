# Slack slash commands

**NOTE:** At this time Slack slash commands for GitLab are experimental are it is
likely to change in the future.

When using Slack you could already use the [Slack service](slack.md) to
notify your team on events on your GitLab instance. With Slack slash commands there
is now a way for you to request data from GitLab.

GitLab provides support for `/issue`, `/merge-request`, `/pipeline`, and `/snippet`
commands.

## Configuration

To enable a slash command for your project, visit the **Integrations** page on your project.
When creating a new integration you will have to list


For configuring Slack slash commands for your project, you will have to register
a custom slash command for your Slack app.


A GitLab administrator can add a service template that sets a default for each
project. This makes it much easier to configure individual projects.

After the template is created, the template details will be pre-filled on a
project's Service page.

## Enable a Service template

In GitLab's Admin area, navigate to **Service Templates** and choose the
service template you wish to create.

For example, in the image below you can see Redmine.

![Redmine service template](img/services_templates_redmine_example.png)





---


[slack-service-docs]: ./slack
