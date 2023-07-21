---
status: proposed
creation-date: "2023-07-05"
authors: [ "@grzesiek", "@fabiopitino" ]
coach: [ ]
owners: [ ]
---

# Modular Monolith: PoCs

Modularization of our monolith is a complex project. There will be many
unknowns. One thing that can help us mitigate the risks and deliver key
insights are Proof-of-Concepts that we could deliver early on, to better
understand what will need to be done.

## Inter-module communicaton

A PoC that we plan to deliver is a PoC of inter-module communication. We do
recognize the need to separate modules, but still allow them to communicate
together using a well defined interface. Modules can communicate through a
facade classes (like libraries usually do), or through eventing system. Both
ways are important.

The main question is: how do we want to define the interface and how to design
the communication channels?

It is one of our goals to make it possible to plug modules out, and operate
some of them as separate services. This will make it easier deploy GitLab.com
in the future and scale key domains. One possible way to achieve this goal
would be to design the inter-module communication using a protobuf as an
interface and gRPC as a communication channel. When modules are plugged-in, we
would bypass gRPC and serialization and use in-process communication primitives
(while still using protobuf as an interface). When a module gets plugged-out,
gRPC would carry messages between modules.

## Use Packwerk to enforce module boundaries

Packwerk is a static analyzer that helps defining and enforcing module boundaries
in Ruby.

[In this PoC merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98801)
we demonstrate a possible directory structure of the monolith broken down into separate
modules.

The PoC also aims to solve the problem of EE extensions (and JH too) allowing the
Rails autoloader to be tweaked depending on whether to load only the Core codebase or
any extensions.

The PoC also attempted to only move a small part of the `Ci::` namespace into a
`components/ci` Packwerk package. This seems to be the most iterative approach
explored so far.

There are different approaches we could use to adopt Packwerk. Other PoC's also
explored are the [large extraction of CI package](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88899)
and [moving the 2 main CI classes into a package](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90595).

All 3 PoC's have a lot in common, from the introduction of Packwerk packages and configurations
to setting paths for the autoloader to work with any packages. What changes between the
various merge requests is the approach on choosing which files to move first.

The main goals of the PoC were:

- understand if Packwerk can be used on the GitLab codebase.
- understand the learning curve for developers.
- verify support for EE and JH extensions.
- allow gradual modularization.

### Positive results

- Using Packwerk would be pretty simple on GitLab since it's designed primarily to work
  on Rails codebases.
- We can change the organization of the domain code to be module-oriented instead of following
  the MVC pattern. It requires small initial changes to allow the Rails autoloading
  to support the new directory structure, which is by the way not imposed by Packwerk.
  After that, registering a new top-level package/bounded-context would be a 1 LOC change.
- Using the correct directory structure indicated in the [PoC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98801)
  allows packages to contain all the code, including EE and JH extensions.
- Gradual modularization is possible and we can have any degree of modularization as we want,
  from initial no enforcement down to complete isolation simulating an in-memory micro-service environment.
- Moving files into a Packwerk package doesn't necessarily mean renaming constants.
  While this is not advisable long term, its an extra flexibility that the tool provides.
  - For example: If we are extracting the `Ci::` module into a Packwerk package there can be
    constants that belong to the CI domain but are not namespaced, like `CommitStatus` or
    that have a different namespace, like `Gitlab::Ci::`.
    Packwerk allows such constants to be moved inside the `ci` package and correctly flags
    boundary violations.
  - Packwerk enhancements from RubyAtScale tooling allow to enforce that all constants inside
    a package share the same Ruby namespace. We eventually would want to leverage that.
- RubyAtScale provides also tools to track metrics about modularization and adoption which we
  would need to monitor and drive as an engineering organization.
- Packwerk has IDE extensions (e.g. for VSCode) to provide realtime feedback on violations
  (like Rubocop). It can also be run via CLI during the development workflow against a single
  package. It could be integrated into pre-push Git hooks or Danger during code reviews.

### Challenges

Some of these challenges are not specific to Packwerk as tool/approach. They were observed
during the PoC and are more generically related to the process of modularization:

- There is no right or wrong approach when introducing Packwerk packages. We need to define
  clear guidelines to give developers the tools to make the best decision:
  - Sometimes it could be creating an empty package and move files in it gradually.
  - Sometimes it could be wrapping an already well designed and isolated part of the codebase.
  - Sometimes it could be creating a new package from scratch.
- As we move code to a different directory structure we need to involve JiHu as they manage
  extensions following the current directory structure.
  We may have modules that are partially migrated and we need to ensure JiHu is up-to-date
  with the current progresses.
- After privacy/dependency checks are enabled, Packwerk will log a lot of violations
  (like Rubocop TODOs) since constant references in a Rails codebase are very entangled.
  - The team owning the package needs to define a vision for the package.
    What would the package look like once all violations have been fixed?
    This may mean specifying where the package fits in the
    [context map](https://www.oreilly.com/library/view/what-is-domain-driven/9781492057802/ch04.html)
    of the system. How the current package should be used by another package `A` and how
    it should use other packages.
  - The vision above should tell developers how they should fix these violations over time.
    Should they make a specific constant public? Should the package list another package as its
    dependencies? Should events be used in some scenarios?
  - Teams will likely need guidance in doing that. We may need to have a team of engineers, like
    maintainers with a very broad understanding of the domains, that will support engineering
    teams in this effort.
- Changes to CI configurations on tuning Knapsack and selective testing were ignored durign the
  PoC.

## Frontend sorting hat

Frontend sorting-hat is a PoC for combining multiple domains to render a full
page of GitLab (with menus, and items that come from multiple separate
domains).

## Frontend assets aggregation

Frontend assets aggregation is a PoC for a possible separation of micro-frontends.
