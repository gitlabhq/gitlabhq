---
status: accepted
creation-date: "2022-09-08"
authors: [ "@grzesiek", "@marshall007", "@fabiopitino", "@hswimelar" ]
coach: "@andrewn"
approvers: [ "@sgoldstein" ]
owning-stage: "~devops::enablement"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Next Rate Limiting Architecture

## Summary

Introducing reasonable application limits is a very important step in any SaaS
platform scaling strategy. The more users a SaaS platform has, the more
important it is to introduce sensible rate limiting and policies enforcement
that will help to achieve availability goals, reduce the problem of noisy
neighbours for users and ensure that they can keep using a platform
successfully.

This is especially true for GitLab.com. Our goal is to have a reasonable and
transparent strategy for enforcing application limits, which will become a
definition of a responsible usage, to help us with keeping our availability and
user satisfaction at a desired level.

We've been introducing various application limits for many years already, but
we've never had a consistent strategy for doing it. What we want to build now is
a consistent framework used by engineers and product managers, across entire
application stack, to define, expose and enforce limits and policies.

Lack of consistency in defining limits, not being able to expose them to our
users, support engineers and satellite services, has negative impact on our
productivity, makes it difficult to introduce new limits and eventually
prevents us from enforcing responsible usage on all layers of our application
stack.

This blueprint has been written to consolidate our limits and to describe the
vision of our next rate limiting and policies enforcement architecture.

## Goals

**Implement a next architecture for rate limiting and policies definition.**

## Challenges

- We have many ways to define application limits, in many different places.
- It is difficult to understand what limits have been applied to a request.
- It is difficult to introduce new limits, even more to define policies.
- Finding what limits are defined requires performing a codebase audit.
- We don't have a good way to expose limits to satellite services like Registry.
- We enforce a number of different policies via opaque external systems
  (Pipeline Validation Service, Bouncer, Watchtower, Cloudflare, HAProxy).
- There is not standardized way to define policies in a way consistent with defining limits.
- It is difficult to understand when a user is approaching a limit threshold.
- There is no way to automatically notify a user when they are approaching thresholds.
- There is no single way to change limits for a namespace / project / user / customer.
- There is no single way to monitor limits through real-time metrics.
- There is no framework for hierarchical limit configuration (instance / namespace / subgroup / project).
- We allow disabling rate-limiting for some marquee SaaS customers, but this
  increases a risk for those same customers. We should instead be able to set
  higher limits.

## Opportunity

We want to build a new framework, making it easier to define limits, quotas and
policies, and to enforce / adjust them in a controlled way, through robust
monitoring capabilities.

<!-- markdownlint-disable MD029 -->

1. Build a framework to define and enforce limits in GitLab Rails.
2. Build an API to consume limits in satellite service and expose them to users.
3. Extract parts of this framework into a dedicated GitLab Limits Service.

<!-- markdownlint-enable MD029 -->

The most important opportunity here is consolidation happening on multiple
levels:

1. Consolidate on the application limits tooling used in GitLab Rails.
1. Consolidate on the process of adding and managing application limits.
1. Consolidate on the behavior of hierarchical cascade of limits and overrides.
1. Consolidate on the application limits tooling used across entire application stack.
1. Consolidate on the policies enforcement tooling used across entire company.

Once we do that we will unlock another opportunity: to ship the new framework /
tooling as a GitLab feature to unlock these consolidation benefits for our
users, customers and entire wider community audience.

### Limits, quotas and policies

This document aims to describe our technical vision for building the next rate
limiting architecture for GitLab.com. We refer to this architectural evolution
as "the next rate limiting architecture", but this is a mental shortcut,
because we actually want to build a better framework that will make it easier
for us to manage not only rate limits, but also quotas and policies.

Below you can find a short definition of what we understand by a limit, by a
quota and by a policy.

- **Limit:** A constraint on application usage, typically used to mitigate
  risks to performance, stability, and security.
  - _Example:_ API calls per second for a given IP address
  - _Example:_ `git clone` events per minute for a given user
  - _Example:_ maximum artifact upload size of 1 GB
- **Quota:** A global constraint in application usage that is aggregated across an
  entire namespace over the duration of their billing cycle.
  - _Example:_ 400 compute minutes per namespace per month
  - _Example:_ 10 GB transfer per namespace per month
- **Policy:** A representation of business logic that is decoupled from application
  code. Decoupled policy definitions allow logic to be shared across multiple services
  and/or "hot-loaded" at runtime without releasing a new version of the application.
  - _Example:_ decode and verify a JWT, determine whether the user has access to the
    given resource based on the JWT scopes and claims
  - _Example:_ deny access based on group-level constraints
    (such as IP allowlist, SSO, and 2FA) across all services

Technically, all of these are limits, because rate limiting is still
"limiting", quota is usually a business limit, and policy limits what you can
do with the application to enforce specific rules. By referring to a "limit" in
this document we mean a limit that is defined to protect business, availability
and security.

### Framework to define and enforce limits

First we want to build a new framework that will allow us to define and enforce
application limits, in the GitLab Rails project context, in a more consistent
and established way. In order to do that, we will need to build a new
abstraction that will tell engineers how to define a limit in a structured way
(presumably using YAML or Cue format) and then how to consume the limit in the
application itself.

We already do have many limits defined in the application, we can use them to
triangulate to find a reasonable abstraction that will consolidate how we
define, use and enforce limits.

We envision building a simple Ruby library here (we can add it to LabKit) that
will make it trivial for engineers to check if a certain limit has been
exceeded or not.

```yaml
name: my_limit_name
actors: user
context: project, group, pipeline
type: rate / second
group: pipeline::execution
limits:
  warn: 2B / day
  soft: 100k / s
  hard: 500k / s
```

```ruby
Gitlab::Limits::RateThreshold.enforce(:my_limit_name) do |threshold|
  actor   = current_user
  context = current_project

  threshold.available do |limit|
    # ...
  end

  threshold.approaching do |limit|
    # ...
  end

  threshold.exceeded do |limit|
    # ...
  end
end
```

In the example above, when `my_limit_name` is defined in YAML, engineers will
be check the current state and execute appropriate code block depending on the
past usage / resource consumption.

Things we want to build and support by default:

1. Comprehensive dashboards showing how often limits are being hit.
1. Notifications about the risk of hitting limits.
1. Automation checking if limits definitions are being enforced properly.
1. Different types of limits - time bound / number per resource etc.
1. A panel that makes it easy to override limits per plan / namespace.
1. Logging that will expose limits applied in Kibana.
1. An automatically generated documentation page describing all the limits.

### Support rate limits based on resources used

One of the problems of our rate limiting system is that values are static
(e.g. 100 requests per minutes) and irrespective of the complexity or resources
used by the operation. For example:

- Firing 100 requests per minute to fetch a simple resource can have very different
  implications than creating a CI pipeline.
- Each pipeline creation action can perform very differently depending on the
  pipeline being created (small MR pipeline VS large scheduled pipeline).
- Paginating resources after an offset of 1000 starts to become expensive on the database.

We should allow some rate limits to be defiened as `computing score / period` where for
computing score we calculate the milliseconds accumulated (for all requests executed
and inflight) within a given period (for example: 1 minute).

This way if a user is sending expensive requests they are likely to hit the rate limit earlier.

### API to expose limits and policies

Once we have an established a consistent way to define application limits we
can build a few API endpoints that will allow us to expose them to our users,
customers and other satellite services that may want to consume them.

Users will be able to ask the API about the limits / thresholds that have been
set for them, how often they are hitting them, and what impact those might have
on their business. This kind of transparency can help them with communicating
their needs to customer success team at GitLab, and we will be able to
communicate how the responsible usage is defined at a given moment.

Because of how GitLab architecture has been built, GitLab Rails application, in
most cases, behaves as a central enterprise service bus (ESB) and there are a
few satellite services communicating with it. Services like container registry,
GitLab Runners, Gitaly, Workhorse, KAS could use the API to receive a set of
application limits those are supposed to enforce. This will still allow us to
define all of them in a single place.

We should, however, avoid the possible negative-feedback-loop, that will put
additional strain on the Rails application when there is a sudden increase in
usage happening. This might be a big customer starting a new automation that
traverses our API or a Denial of Service attack. In such cases, the additional
traffic will reach GitLab Rails and subsequently also other satellite services.
Then the satellite services may need to consult Rails again to obtain new
instructions / policies around rate limiting the increased traffic. This can
put additional strain on Rails application and eventually degrade performance
even more. In order to avoid this problem, we should extract the API endpoints
to separate service (see the section below) if the request rate to those
endpoints depends on the volume of incoming traffic. Alternatively we can keep
those endpoints in Rails if the increased traffic will not translate into
increase of requests rate or increase in resources consumption on these API
endpoints on the Rails side.

#### Decoupled Limits Service

At some point we may decide that it is time to extract a stateful backend
responsible for storing metadata around limits, all the counters and state
required, and exposing API, out of Rails.

It is impossible to make a decision about extracting such a decoupled limits
service yet, because we will need to ship more proof-of-concept work, and
concrete iterations to inform us better about when and how we should do that. We
will depend on the Evolution Architecture practice to guide us towards either
extracting Decoupled Limits Service or not doing that at all.

As we evolve this blueprint, we will document our findings and insights about
how this service should look like, in this section of the document.

### GitLab Policy Service

_Disclaimer_: Extracting a GitLab Policy Service might be out of scope
of the current workstream organized around implementing this blueprint.

Not all limits can be easily described in YAML. There are some more complex
policies that require a bit more sophisticated approach and a declarative
programming language used to enforce them. One example of such a language might be
[Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) language.
It is a standardized way to define policies in
[OPA - Open Policy Agent](https://www.openpolicyagent.org/). At GitLab we are
already using OPA in some departments. We envision the need to additional
consolidation to not only consolidate on the tooling we are using internally at
GitLab, but to also transform the Next Rate Limiting Architecture into
something we can make a part of the product itself.

Today, we already do have a policy service we are using to decide whether a
pipeline can be created or not. There are many policies defined in
[Pipeline Validation Service](https://gitlab.com/gitlab-org/modelops/anti-abuse/pipeline-validation-service).
There is a significant opportunity here in transforming Pipeline Validation
Service into a general purpose GitLab Policy Service / GitLab Policy Agent that
will be well integrated into the GitLab product itself.

Generalizing Pipeline Validation Service into GitLab Policy Service can bring a
few interesting benefits:

1. Consolidate on our tooling across the company to improve efficiency.
1. Integrate our GitLab Rails limits framework to resolve policies using the policy service.
1. Do not struggle to define complex policies in YAML and hack evaluating them in Ruby.
1. Build a policy for GraphQL queries limiting using query execution cost estimation.
1. Make it easier to resolve policies that do not need "hierarchical limits" structure.
1. Make GitLab Policy Service part of the product and integrate it into the single application.

We envision using GitLab Policy Service to be place to define policies that do
not require knowing anything about the hierarchical structure of the limits.
There are limits that do not need this, like IP addresses allow-list, spam
checks, configuration validation etc.

We defined "Policy" as a stateless, functional-style, limit. It takes input
arguments and evaluates to either true or false. It should not require a global
counter or any other volatile global state to get evaluated. It may still
require to have a globally defined rules / configuration, but this state is not
volatile in a same way a rate limiting counter may be, or a megabytes consumed
to evaluate quota limit.

#### Policies used internally and externally

The GitLab Policy Service might be used in two different ways:

1. Rails limits framework will use it as a source of policies enforced internally.
1. The policy service feature will be used as a backend to store policies defined by users.

These are two slightly different use-cases: first one is about using
internally-defined policies to ensure the stability / availability of a GitLab
instance (GitLab.com or self-managed instance). The second use-case is about
making GitLab Policy Service a feature that users will be able to build on top
of.

Both use-cases are valid but we will need to make technical decision about how
to separate them. Even if we decide to implement them both in a single service,
we will need to draw a strong boundary between the two.

The same principle might apply to Decouple Limits Service described in one of
the sections of this document above.

#### The two limits / policy services

It is possible that GitLab Policy Service and Decoupled Limits Service can
actually be the same thing. It, however, depends on the implementation details
that we can't predict yet, and the decision about merging these services
together will need to be informed by subsequent iterations' feedback.

## Hierarchical limits

GitLab application aggregates users, projects, groups and namespaces in a
hierarchical way. This hierarchical structure has been designed to make it
easier to manage permissions, streamline workflows, and allow users and
customers to store related projects, repositories, and other artifacts,
together.

It is important to design the new rate limiting framework in a way that it
built on top of this hierarchical structure and engineers, customers, SREs and
other stakeholders can understand how limits are being applied, enforced and
overridden within the hierarchy of namespaces, groups and projects.

We want to reduce the cognitive load required to understand how limits are
being managed within the existing permissions structure. We might need to build
a simple and easy-to-understand formula for how our application decides which
limits and thresholds to apply for a given request and a given actor:

> GitLab will read default limits for every operation, all overrides configured
> and will choose a limit with the highest precedence configured. A limit
> precedence needs to be explicitly configured for every override, a default
> limit has precedence 100.

One way in which we can simplify limits management in general is to:

1. Have default limits / thresholds defined in YAML files with a default precedence 100.
1. Allow limits to be overridden through the API, store overrides in the database.
1. Every limit / threshold override needs to have an integer precedence value provided.
1. Build an API that will take an actor and expose limits applicable for it.
1. Build a dashboard showing actors with non-standard limits / overrides.
1. Build a observability around this showing in Kibana when non-standard limits are being used.

The points above represent an idea to use precedence score (or Z-Index for
limits), but there may be better solutions, like just defining a direction of
overrides - a lower limit might always override a limit defined higher in the
hierarchy. Choosing a proper solution will require a thoughtful research.

## Principles

1. Try to avoid building rate limiting framework in a tightly coupled way.
1. Build application limits API in a way that it can be easily extracted to a separate service.
1. Build application limits definition in a way that is independent from the Rails application.
1. Build tooling that produce consistent behavior and results across programming languages.
1. Build the new framework in a way that we can extend to allow self-managed administrators to customize limits.
1. Maintain consistent features and behavior across SaaS and self-managed codebase.
1. Be mindful about a cognitive load added by the hierarchical limits, aim to reduce it.

## Phases and iterations

1. **Compile examples of current most important application limits (Owning Team)**
   - Owning Team (in collaboration with Stage Groups) compiles a list of the
     most important application limits used in Rails today.

1. **Implement Rate Limiting Framework in Rails (Owning Team)**
   - Triangulate rate limiting abstractions based on the data gathered in Phase 1.
   - Develop YAML model for limits.
   - Build Rails SDK.
   - Create examples showcasing usage of the new rate limits SDK.

1. **Team fan out of Rails SDK (Stage Groups)**
   - Individual stage groups begin using the SDK built in Phase 2 for new limit and policies.
   - Stage groups begin replacing historical ad hoc limit implementations with the SDK.
   - (Owning team) Provides means to monitor and observe the progress of the replacement effort. Ideally this is broken down to the `feature_category` level to drive group-level buy-in.

1. **Enable Satellite Services to Use the Rate Limiting Framework (Owning Team)**
   - Determine if the goals of Phase 4 are best met by either:
     - Extracting the Rails rate limiting service into a decoupled service.
     - Implementing a separate Go library which uses the same backend (for example, Redis) for rate limiting.

1. **SDK for Satellite Services (Owning Team)**
   - Build Go SDK.
   - Create examples showcasing usage of the new rate limits SDK.

1. **Team fan out for Satellite Services (Stage Groups)**
   - Individual stage groups begin using the SDK built in Phase 5 for new limit and policies.
   - Stage groups begin replacing historical ad hoc limit implementations with the SDK.

## Status

Request For Comments.

## Timeline

- 2022-04-27: [Rate Limit Architecture Working Group](https://handbook.gitlab.com/handbook/company/working-groups/rate-limit-architecture/) started.
- 2022-06-07: Working Group members [started submitting technical proposals](https://gitlab.com/gitlab-org/gitlab/-/issues/364524) for the next rate limiting architecture.
- 2022-06-15: We started [scoring proposals](https://docs.google.com/spreadsheets/d/1DFHU1kSdTnpydwM5P2RK8NhVBNWgEHvzT72eOhB8F9E) submitted by Working Group members.
- 2022-07-06: A fourth, [consolidated proposal](https://gitlab.com/gitlab-org/gitlab/-/issues/364524#note_1017640650), has been submitted.
- 2022-07-12: Started working on the design document following [Architecture Evolution Workflow](https://handbook.gitlab.com/handbook/engineering/architecture/workflow/).
- 2022-09-08: The initial version of the blueprint has been merged.
