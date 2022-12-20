---
status: ongoing
creation-date: "2022-11-15"
authors: [ "@vtak" ]
coach: "@grzesiek"
approvers: [ "@ericschurter", "@oregand" ]
owning-stage: "~devops::create"
participating-stages: []
---

# Remote Development

## Summary

Remote Development is a new architecture for our software-as-a-service platform that provides a more consistent user experience writing code hosted in GitLab. It may also provide additional features in the future, such as a purely browser-based workspace and the ability to connect to an already running VM/Container or to use a GitLab-hosted VM/Container.

## Web IDE and Remote Development

It is important to note that `Remote Development !== Web IDE`, and this is something we want to be explicit about in this document as the terms can become conflated when they shouldn't. Our new Web IDE is a separate ongoing effort that is running in parallel to Remote Development.

These two separate categories do have some overlap as it is a goal to allow a user to connect a running workspace to the Web IDE, **but** this does not mean the two are dependent on one another.

You can use the [Web IDE](../../../user/project/web_ide/index.md) to commit changes to a project directly from your web browser without installing any dependencies or cloning any repositories. The Web IDE, however, lacks a native runtime environment on which you would compile code, run tests, or generate real-time feedback in the IDE. For a more complete IDE experience, you can pair the Web IDE with a Remote Development workspace that has been properly configured to run as a host.

![WebIDERD](img/remote_dev_15_7_1.png)

## Long-term vision

As a [new Software Developer to a team such as Sasha](https://about.gitlab.com/handbook/product/personas/#sasha-software-developer) with no local development environment, I should be able to:

- Navigate to a repository on GitLab.com or self-managed.
- Click a button that will provide a list of current workspaces for this repository.
- Click a button that will create a new workspace or select an existing workspace from a list.
- Go through a configuration wizard that will let me select various options for my workspace (memory/CPU).
- Start up a workspace from the Web IDE and within a minute have a fully interactive terminal panel at my disposal.
- Make code changes, run tests, troubleshoot based on the terminal output, and commit new changes.
- Submit MRs of any kind without having to clone the repository locally or to manually update a local development environment.

## User Flow Diagram

![User Flow](img/remote_dev_15_7.png)

## Terminology

We use the following terms to describe components and properties of the Remote Development architecture.

### Remote Development

Remote Development allows you to use a secure development environment in the cloud that you can connect to from your local machine through a web browser or a client-based solution with the purpose of developing a software product there.

#### Remote Development properties

- Separate your development environment to avoid impacting your local machine configuration.
- Make it easy for new contributors to get started and keep everyone on a consistent environment.
- Use tools or runtimes not available on your local OS or manage multiple versions of them.
- Access an existing development environment from multiple machines or locations.

Discouraged synonyms: VS Code for web, Remote Development Extension, browser-only WebIDE, Client only WebIDE

### Workspace

Container/VM-based developer machines providing all the tools and dependencies needed to code, build, test, run, and debug applications.

#### Workspace properties

- Workspaces should be isolated from each other by default and are responsible for managing the lifecycle of their components. This isolation can be multi-layered: namespace isolation, network isolation, resources isolation, node isolation, sandboxing containers, etc. ([reference](https://kubernetes.io/docs/concepts/security/multi-tenancy/)).
- A workspace should contain project components as well as editor components.
- A workspace should be a combination of resources that support cloud-based development environment.
- Workspaces are constrained by the amount of resources provided to them.

### Legacy Web IDE

The current production [Web IDE](../../../user/project/web_ide/index.md).

#### Legacy Web IDE properties

An advanced editor with commit staging that currently supports:

- [Live Preview](../../../user/project/web_ide/index.md#live-preview)
- [Interactive Web Terminals](../../../user/project/web_ide/index.md#interactive-web-terminals-for-the-web-ide)

### Web IDE

VS Code for web - replacement of our current legacy Web IDE.

#### Web IDE properties

A package for bootstrapping GitLab context-aware Web IDE that:

- Is built on top of Microsoft's VS Code. We customize and add VS Code features in the [GitLab fork of the VS Code project](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork).
- Can be configured in a way that it connects to the workspace rather than only using the browser. When connected to a workspace, a user should be able to do the following from the Web IDE:
  - Edit, build, or debug on a different OS than they are running locally.
  - Make use of larger or more specialized hardware than their local machine for development.
  - Separate developer environments to avoid conflicts, improve security, and speed up onboarding.

### Remote Development Extension for Desktop

Something that plugs into the desktop IDE and connects you to the workspace.

#### Remote Development Extension for Desktop properties

- Allows you to open any folder in a workspace.
- Should be desktop IDE agnostic.
- Should have access to local files or APIs.

## Goals

### A consistent experience

Organizations should have the same user experience on our SaaS platform as they do on a self-managed GitLab instance. We want to abstract away the user's development environment to avoid impacting their local machine configuration. We also want to provide support for developing on the same operating system you deploy to or use larger or more specialized hardware.

A major goal is that each member of a development team should have the same development experience minus any specialized local configuration. This will also make it easy for new contributors to get started and keep everyone on a consistent environment.

### Increased availability

A workspace should allow access to an existing development environment from multiple machines and locations across a single or multiple teams. It should also allow a user to make use of tools or runtimes not available on their local OS or manage multiple versions of them.

Additionally, Remote Development workspaces could provide a way to implement disaster recovery if we are able to leverage the capabilities of [Pods](../../../architecture/blueprints/pods/index.md).

### Scalability

As an organization begins to scale, they quickly realize the need to support additional types of projects that might require extensive workflows. Remote Development workspaces aim to solve that issue by abstracting away the burden of complex machine configuration, dependency management, and possible data-seeding issues.

To facilitate working on different features across different projects, Remote Development should allow each user to provision multiple workspaces to enable quick context switching.

Eventually, we should be able to allow users to vertically scale their workspaces with more compute cores, memory, and other resources. If a user is currently working against a 2 CPU and 4 GB RAM workspace but comes to find they need more CPU, they should be able to upgrade their compute layer to something more suitable with a click or CLI command within the workspace.

### Provide built-in security and enterprise readiness

As Remote Development becomes a viable replacement for Virtual Desktop Infrastructure solutions, they must be secure and support enterprise requirements, such as role-based access control and the ability to remove all source code from developer machines.

### Accelerate project and developer onboarding

As a zero-install development environment that runs in your browser, Remote Development makes it easy for anyone to join your team and contribute to a project.

### Regions

GitLab.com is only hosted within the United States of America. Organizations located in other regions have voiced demand for local SaaS offerings. BYO infrastructure helps work in conjunction with [GitLab Regions](https://gitlab.com/groups/gitlab-org/-/epics/6037) because a user's workspace may be deployed within different geographies. The ability to deploy workspaces to different geographies might also help to solve data residency and compliance problems.

## High-level architecture problems to solve

A number of technical issues need to be resolved to implement a stable Remote Development offering. This section will be expanded.

- Who is our main persona for BYO infrastructure?
- How do users authenticate?
- How do we support more than one IDE?
- How are workspaces provisioned?
- How can workspaces implement disaster recovery capabilities?
- If we cannot use SSH, what are the viable alternatives for establishing a secure WebSocket connection?
- Are we running into any limitations in functionality with the Web IDE by not having it running in the container itself? For example, are we going to get code completion, linting, and language server type features to work with our approach?
- How will our environments be provisioned, managed, created, destroyed, etc.?
- To what extent do we need to provide the user with a UI to interact with the provisioned environments?
- How will the files inside the workspace get live updated based on changes in the Web IDE? Are we going to use a [CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)-like setup to patch files in a container? Are we going to generate a diff and send it though a WebSocket connection?

## Iteration plan

We can't ship the entire Remote Development architecture in one go - it is too large. Instead, we are adopting an iteration plan that provides value along the way.

- Use GitLab Agent for Kubernetes Remote Development Module.
- Integrate Remote Development with the UI and Web IDE.
- Improve security and usability.

### High-level approach

The nuts and bolts are being worked out at [Remote Development GA4K Architecture](https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/architecture.md) to keep a SSoT. Once we have hammered out the details, we'll replace this section with the diagram in the above repository.

### Iteration 0: [GitLab Agent for Kubernetes Remote Development Module (plumbing)](https://gitlab.com/groups/gitlab-org/-/epics/9138)

#### Goals

- Use the [GitLab Agent](../../../user/clusters/agent/index.md) integration.
- Create a workspace in a Kubernetes cluster based on a `devfile` in a public repository.
- Install the IDE and dependencies as defined.
- Report the status of the environment (via the terminal or through an endpoint).
- Connect to an IDE in the workspace.

#### Requirements

- Remote environment running on a Kubernetes cluster based on a `devfile` in a repo.

These are **not** part of Iteration 0:

- Authentication/authorization with GitLab and a user.
- Integration of Remote Development with the GitLab UI and Web IDE.
- Using GA4K instead of an Ingress controller.

#### Assumptions

- We will use [`devworkspace-operator` v0.17.0 (latest version)](https://github.com/devfile/devworkspace-operator/releases/tag/v0.17.0). A prerequisite is [`cert-manager`](https://github.com/devfile/devworkspace-operator#with-yaml-resources).
- We have an Ingress controller ([Ingress-NGINX](https://github.com/kubernetes/ingress-nginx)), which is accessible over the network.
- The initial server is stubbed.

#### Success criteria

- Using GA4K to communicate with the Kubernetes API from the `remote_dev` agent module.
- All calls to the Kubernetes API are done through GA4K.
- A workspace in a Kubernetes cluster created using DevWorkspace Operator.

### Iteration 1: [Rails endpoints, authentication, and authorization](https://gitlab.com/groups/gitlab-org/-/epics/9323)

#### Goals

- Add endpoints in Rails to accept work from a user.
- Poll Rails for work from KAS.
- Add authentication and authorization to the workspaces created in the Kubernetes cluster.
- Extend the GA4K `remote_dev` agent module to accept more types of work (get details of a workspace, list workspaces for a user, etc).
- Build an editor injector for the GitLab fork of VS Code.

#### Requirements

- [GitLab Agent for Kubernetes Remote Development Module (plumbing)](https://gitlab.com/groups/gitlab-org/-/epics/9138) is complete.

These are **not** part of Iteration 1:

- Integration of Remote Development with the GitLab UI and Web IDE.
- Using GA4K instead of an Ingress controller.

#### Assumptions

- TBA

#### Success criteria

- Poll Rails for work from KAS.
- Rails endpoints to create/delete/get/list workspaces.
- All requests are correctly authenticated and authorized except where the user has requested the traffic to be public (for example, opening a server while developing and making it public).
- A user can create a workspace, start a server on that workspace, and have that traffic become private/internal/public.
- We are using the GitLab fork of VS Code as an editor.

### Iteration 2: [Integrate Remote Development with the UI and Web IDE](https://gitlab.com/groups/gitlab-org/-/epics/9169)

#### Goals

- Allow users full control of their workspaces via the GitLab UI.

#### Requirements

- [GitLab Agent for Kubernetes Remote Development Module](https://gitlab.com/groups/gitlab-org/-/epics/9138).

These are **not** part of Iteration 2:

- Usability improvements
- Security improvements

#### Success criteria

- Be able to list/create/delete/stop/start/restart workspaces from the UI.
- Be able to create workspaces for the user in the Web IDE.
- Allow the Web IDE terminal to connect to different containers in the workspace.
- Configure DevWorkspace Operator for user-expected configuration (30-minute workspace timeout, a separate persistent volume for each workspace that is deleted when the workspace is deleted, etc.).

### Iteration 3: [Improve security and usability](https://gitlab.com/groups/gitlab-org/-/epics/9170)

#### Goals

- Improve security and usability of our Remote Development solution.

#### Requirements

- [Integrate Remote Development with the UI and Web IDE](https://gitlab.com/groups/gitlab-org/-/epics/9169) is complete.

#### Assumptions

- We are allowing for internal feedback and closed/early customer feedback that can be iterated on.
- We have explored or are exploring the feasibility of using GA4K with Ingresses in [Solving Ingress problems for Remote Development](https://gitlab.com/gitlab-org/gitlab/-/issues/378998).
- We have explored or are exploring Kata containers for providing root access to workspace users in [Investigate Kata Containers / Firecracker / gVisor](https://gitlab.com/gitlab-org/gitlab/-/issues/367043).
- We have explored or are exploring how Ingress/Egress requests cannot be misused from [resources within or outside the cluster](https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/securing-the-workspace.md) (security hardening).

#### Success criteria

Add options to:

- Create different classes of workspaces (1gb-2cpu, 4gb-8cpu, etc.).
- Vertically scale up workspace resources.
- Inject secrets from a GitLab user/group/repository.
- Configure timeouts of workspaces at multiple levels.
- Allow users to expose endpoints in their workspace (for example, not allow anyone in the organization to expose any endpoint publicly).

## Market analysis

We have conducted a market analysis to understand the broader market and what others can offer us by way of open-source libraries, integrations, or partnership opportunities. We have broken down the effort into a set of issues where we investigate each potential competitor/pathway/partnership as a spike.

- [Market analysis](https://gitlab.com/groups/gitlab-org/-/epics/8131)
- [YouTube results](https://www.youtube.com/playlist?list=PL05JrBw4t0KrRQhnSYRNh1s1mEUypx67-)

### Next Steps

While our spike proved fruitful, we have paused this investigation until we reach our goals in [Viable Maturity](https://gitlab.com/groups/gitlab-org/-/epics/9190).

## Che versus a custom-built solution

After an investigation into using [Che](https://gitlab.com/gitlab-org/gitlab/-/issues/366052) as our backend to accelerate Remote Development, we ultimately opted to [write our own custom-built solution](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97449#note_1131215629).

Some advantages of us opting to write our own custom-built solution are:

- We can still use the core DevWorkspace Operator and build on top of it.
- It is easier to add support for other configurations apart from `devfile` in the future if the need arises.
- We have the ability to choose which tech stack to use (for example, instead of using Traefik which is used in Che, explore NGINX itself or use GitLab Agent for Kubernetes).

## Links

- [Remote Development presentation](https://docs.google.com/presentation/d/1XHH_ZilZPufQoWVWViv3evipI-BnAvRQrdvzlhBuumw/edit#slide=id.g131f2bb72e4_0_8)
- [Category Strategy epic](https://gitlab.com/groups/gitlab-org/-/epics/7419)
- [Minimal Maturity epic](https://gitlab.com/groups/gitlab-org/-/epics/9189)
- [Viable Maturity epic](https://gitlab.com/groups/gitlab-org/-/epics/9190)
- [Complete Maturity epic](https://gitlab.com/groups/gitlab-org/-/epics/9191)
- [Bi-weekly sync](https://docs.google.com/document/d/1hWVvksIc7VzZjG-0iSlzBnLpyr-OjwBVCYMxsBB3h_E/edit#)
- [Market analysis and architecture](https://gitlab.com/groups/gitlab-org/-/epics/8131)
- [GA4K Architecture](https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/architecture.md)
- [BYO infrastructure](https://gitlab.com/groups/gitlab-org/-/epics/8290)
- [Browser runtime](https://gitlab.com/groups/gitlab-org/-/epics/8291)
- [GitLab-hosted infrastructure](https://gitlab.com/groups/gitlab-org/-/epics/8292)
- [Browser runtime spike](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/58).
- [Remote Development direction](https://about.gitlab.com/direction/create/editor/remote_development)
- [Ideal user journey](https://about.gitlab.com/direction/create/editor/remote_development/#ideal-user-journey)
