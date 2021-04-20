---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Kubernetes Agent identity and authentication **(PREMIUM SELF)**

This page uses the word `agent` to describe the concept of the
GitLab Kubernetes Agent. The program that implements the concept is called `agentk`.
Read the
[architecture page](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)
for more information.

## Agent identity and name

In a GitLab installation, each agent must have a unique, immutable name. This
name must be unique in the project the agent is attached to, and this name must
follow the [DNS label standard from RFC 1123](https://tools.ietf.org/html/rfc1123).
The name must:

- Contain at most 63 characters.
- Contain only lowercase alphanumeric characters or `-`.
- Start with an alphanumeric character.
- End with an alphanumeric character.

Kubernetes uses the
[same naming restriction](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)
for some names.

The regex for names is: `/\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/`.

## Multiple agents in a cluster

A Kubernetes cluster may have 0 or more agents running in it. Each agent likely
has a different configuration. Some may enable features A and B, and some may
enable features B and C. This flexibility enables different groups of people to
use different features of the agent in the same cluster.

For example, [Priyanka (Platform Engineer)](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#priyanka-platform-engineer)
may want to use cluster-wide features of the agent, while
[Sasha (Software Developer)](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#sasha-software-developer)
uses the agent that only has access to a particular namespace.

Each agent is likely running using a
[`ServiceAccount`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/),
a distinct Kubernetes identity, with a distinct set of permissions attached to it.
These permissions enable the agent administrator to follow the
[principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
and minimize the permissions each particular agent needs.

## Kubernetes Agent authentication

When adding a new agent, GitLab provides the user with a bearer access token. The
agent uses this token to authenticate with GitLab. This token is a random string
and does not encode any information in it, but it is secret and must
be treated with care. Store it as a `Secret` in Kubernetes.

Each agent can have 0 or more tokens in a GitLab database. Having several valid
tokens helps you rotate tokens without needing to re-register an agent. Each token
record in the database has the following fields:

- Agent identity it belongs to.
- Token value. Encrypted at rest.
- Creation time.
- Who created it.
- Revocation flag to mark token as revoked.
- Revocation time.
- Who revoked it.
- A text field to store any comments the administrator may want to make about the token for future self.

Tokens can be managed by users with `maintainer` and higher level of
[permissions](../../user/permissions.md).

Tokens are immutable, and only the following fields can be updated:

- Revocation flag. Can only be updated to `true` once, but immutable after that.
- Revocation time. Set to the current time when revocation flag is set, but immutable after that.
- Comments field. Can be updated any number of times, including after the token has been revoked.

The agent sends its token, along with each request, to GitLab to authenticate itself.
For each request, GitLab checks the token's validity:

- Does the token exist in the database?
- Has the token been revoked?

This information may be cached for some time to reduce load on the database.

## Kubernetes Agent authorization

GitLab provides the following information in its response for a given Agent access token:

- Agent configuration Git repository. (The agent doesn't support per-folder authorization.)
- Agent name.

## Create an agent

You can create an agent by following the [user documentation](../../user/clusters/agent/index.md#create-an-agent-record-in-gitlab), or via Rails console:

```ruby
project = ::Project.find_by_full_path("path-to/your-configuration-project")
# agent-name should be the same as specified above in the config.yaml
agent = ::Clusters::Agent.create(name: "<agent-name>", project: project)
token = ::Clusters::AgentToken.create(agent: agent)
token.token # this will print out the token you need to use on the next step
```
