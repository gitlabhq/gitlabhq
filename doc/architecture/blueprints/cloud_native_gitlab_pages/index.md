---
status: implemented
creation-date: "2019-05-16"
authors: [ "@grzesiek" ]
coach: [ "@ayufan", "@grzesiek" ]
approvers: [ "@ogolowinski", "@dcroft", "@vshushlin" ]
owning-stage: "~devops::release"
participating-stages: []
---

# GitLab Pages New Architecture

GitLab Pages is an important component of the GitLab product. It is mostly
being used to serve static content, and has a limited set of well defined
responsibilities. That being said, unfortunately it has become a blocker for
GitLab.com Kubernetes migration.

Cloud Native and the adoption of Kubernetes has been recognised by GitLab to be
one of the top two biggest tailwinds that are helping us grow faster as a
company behind the project.

This effort is described in more detail
[in the infrastructure team handbook page](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/kubernetes/gitlab-com/).

GitLab Pages is tightly coupled with NFS and to unblock Kubernetes
migration a significant change to GitLab Pages' architecture is required. This
is an ongoing work that we have started more than a year ago. This blueprint
might be useful to understand why it is important, and what is the roadmap.

## How GitLab Pages Works

GitLab Pages is a daemon designed to serve static content, written in
[Go](https://go.dev/).

Initially, GitLab Pages has been designed to store static content on a local
shared block storage (NFS) in a hierarchical group > project directory
structure. Each directory, representing a project, was supposed to contain a
configuration file and static content that GitLab Pages daemon was supposed to
read and serve.

```mermaid
graph LR
  A(GitLab Rails) -- Writes new pages deployment --> B[(NFS)]
  C(GitLab Pages) -. Reads static content .-> B
```

This initial design has become outdated because of a few reasons - NFS coupling
being one of them - and we decided to replace it with more "decoupled
service"-like architecture. The new architecture, that we are working on, is
described in this blueprint.

## NFS coupling

In 2017, we experienced serious problems of scaling our NFS infrastructure. We
even tried to replace NFS with
[CephFS](https://docs.ceph.com/docs/master/cephfs/) - unsuccessfully.

Since that time it has become apparent that the cost of operations and
maintenance of a NFS cluster is significant and that if we ever decide to
migrate to Kubernetes
[we need to decouple GitLab from a shared local storage and NFS](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/426#note_375646396).

1. NFS might be a single point of failure
1. NFS can only be reliably scaled vertically
1. Moving to Kubernetes means increasing the number of mount points by an order
   of magnitude
1. NFS depends on extremely reliable network which can be difficult to provide
   in Kubernetes environment
1. Storing customer data on NFS involves additional security risks

Moving GitLab to Kubernetes without NFS decoupling would result in an explosion
of complexity, maintenance cost and enormous, negative impact on availability.

## New GitLab Pages Architecture

- GitLab Pages sources domains' configuration from the GitLab internal
  API, instead of reading `config.json` files from a local shared storage.
- GitLab Pages serves static content from Object Storage.

```mermaid
graph TD
  A(User) -- Pushes pages deployment --> B{GitLab}
  C((GitLab Pages)) -. Reads configuration from API .-> B
  C -. Reads static content .-> D[(Object Storage)]
  C -- Serves static content --> E(Visitors)
```

This new architecture has been briefly described in
[the blog post](https://about.gitlab.com/blog/2020/08/03/how-gitlab-pages-uses-the-gitlab-api-to-serve-content/)
too.

## Iterations

1. ✓ Redesign GitLab Pages configuration source to use the GitLab API
1. ✓ Evaluate performance and build reliable caching mechanisms
1. ✓ Incrementally rollout the new source on GitLab.com
1. ✓ Make GitLab Pages API domains configuration source enabled by default
1. Enable experimentation with different servings through feature flags
1. Triangulate object store serving design through meaningful experiments
1. Design pages migration mechanisms that can work incrementally
1. Gradually migrate towards object storage serving on GitLab.com

[GitLab Pages Architecture](https://gitlab.com/groups/gitlab-org/-/epics/1316)
epic with detailed roadmap is also available.
