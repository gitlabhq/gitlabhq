# GitLab Integration

GitLab integrates with multiple third-party services to allow external issue trackers and external authentication.

See the documentation below for details on how to configure these services.

- [External issue tracker](external-issue-tracker.md) Redmine, JIRA, etc.
- [LDAP](ldap.md) Set up sign in via LDAP
- [OmniAuth](omniauth.md) Sign in via Twitter, GitHub, GitLab, and Google via OAuth.
- [SAML](saml.md) Configure GitLab as a SAML 2.0 Service Provider
- [Slack](slack.md) Integrate with the Slack chat service
- [OAuth2 provider](oauth_provider.md) OAuth2 application creation
- [Gmail actions buttons](gmail_action_buttons_for_gitlab.md) Adds GitLab actions to messages

GitLab Enterprise Edition contains [advanced JIRA support](http://doc.gitlab.com/ee/integration/jira.html) and [advanced Jenkins support](http://doc.gitlab.com/ee/integration/jenkins.html).

## Project services

Integration with services such as Campfire, Flowdock, Gemnasium, HipChat, Pivotal Tracker, and Slack are available in the form of a Project Service.
You can find these within GitLab in the Services page under Project Settings if you are at least a master on the project.
Project Services are a bit like plugins in that they allow a lot of freedom in adding functionality to GitLab, for example there is also a service that can send an email every time someone pushes new commits.
Because GitLab is open source we can ship with the code and tests for all plugins.
This allows the community to keep the plugins up to date so that they always work in newer GitLab versions.
For an overview of what projects services are available without logging in please see the [project_services directory](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/models/project_services).
