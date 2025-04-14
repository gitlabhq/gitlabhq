---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Risks in GitLab Duo Workflow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta

{{< /details >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

Workflow is a beta product and users should consider their
circumstances before using this tool. It is subject to [the GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
Workflow is an AI Agent that is given some ability to perform actions on the user's behalf. AI tools based on LLMs are
inherently unpredictable and you should take appropriate precautions.

Workflow in VS Code runs workflows on your local workstation or in a Docker container.
Running Duo Workflow inside of a Docker container is not a security measure but a
convenience to reduce the amount of disruption to your usual development
environment. All the documented risks should be considered before using this
product. The following risks are important to understand:

1. Workflow has access to the local file system of the
   project where you started running Workflow. Workflow respects your local `.gitignore` file,
   but it can still access files that are not committed to the project and not called out in `.gitignore`.
   Such files can contain credentials (for example, `.env` files).
1. Workflow also gets access to a time-limited `ai_workflows` scoped GitLab
   OAuth token with your user's identity. This token can be used to access
  GitLab APIs on your behalf. This token is limited to the duration of
   the workflow and only has access to certain APIs in GitLab.
   Without user approval, Workflow will only perform read operations but the token can still,
   by design, perform write operations on the users behalf. You should consider
   the access your user has in GitLab before running Workflow.
1. You should not give Workflow any additional credentials or secrets, in
   goals or messages, as there is a chance it might end up using those in code
   or other API calls.

Risks specifically when using Docker to isolate Workflow:

1. Our supported Docker servers are running in a VM. We do not support Docker
   Engine running on the host as this offers less isolation. Because Docker
   Engine is the most common way to run Docker on Linux we will likely not
   support many Linux setups by default, but instead we'll require them to
   install an additional Docker runtime to use Workflow.
1. This VM running on your local workstation likely has access to your local
   network, unless you have created additional firewall rules to prevent it.
   Local network access may be an issue if you are running local development
   servers on your host that you would not want reachable by the workflow
   commands. Local network access may also be risky in a corporate intranet
   environment where you have internal resources that you do not want
   accessible by Workflow.
1. The VM may be able to consume a lot of CPU, RAM and storage based on the
   limits configured with your Docker VM installation.
1. Depending on the configuration of the VM in your Docker installation it may
   also have access to other hardware on your host.
1. Unpatched installations of Docker may contain vulnerabilities that could
   eventually lead to code execution escaping the VM to the host or accessing
   resources on the host that you didn't intend.
1. Each version of Docker has different ways of mounting directories into the
   containers. Workflow only mounts the directory for the project you have
   open in VS Code but depending on how your Docker installation works and
   whether or not you are running other containers there may still be some
   risks it could access other parts of your file system.
1. All your Docker containers usually run in a single VM. So this
   may mean that Workflow containers are running in the same VM as other
   non Workflow containers. While the containers are isolated to some
   degree this isolation is not as strict as VM level isolation
