---
stage: Verify
group: Pipeline Execution
title: Contribute to Verify stage codebase
---

## What are we working on in Verify?

Verify stage is working on a comprehensive Continuous Integration platform
integrated into the GitLab product. Our goal is to empower our users to make
great technical and business decisions, by delivering a fast, reliable, secure
platform that verifies assumptions that our users make, and check them against
the criteria defined in CI/CD configuration. They could be unit tests, end-to-end
tests, benchmarking, performance validation, code coverage enforcement, and so on.

Feedback delivered by GitLab CI/CD makes it possible for our users to make well
informed decisions about technological and business choices they need to make
to succeed. Why is Continuous Integration a mission critical product?

GitLab CI/CD is our platform to deliver feedback to our users and customers.

They contribute their continuous integration configuration files
`.gitlab-ci.yml` to describe the questions they want to get answers for. Each
time someone pushes a commit or triggers a pipeline we need to find answers for
very important questions that have been asked in CI/CD configuration.

Failing to answer these questions or, what might be even worse, providing false
answers, might result in a user making a wrong decision. Such wrong decisions
can have very severe consequences.

## Core principles of our CI/CD platform

Data produced by the platform should be:

1. Accurate.
1. Durable.
1. Accessible.

The platform itself should be:

1. Reliable.
1. Secure.
1. Deterministic.
1. Trustworthy.
1. Fast.
1. Simple.

Since the inception of GitLab CI/CD, we have lived by these principles,
and they serve us and our users well. Some examples of these principles are that:

- The feedback delivered by GitLab CI/CD and data produced by the platform should be accurate.
  If a job fails and we notify a user that it was successful, it can have severe negative consequences.
- Feedback needs to be available when a user needs it and data cannot disappear unexpectedly when engineers need it.
- It all doesn't matter if the platform is not secure and we
  are leaking credentials or secrets.
- When a user provides a set of preconditions in a form of CI/CD configuration, the result should be deterministic each time a pipeline runs, because otherwise the platform might not be trustworthy.
- If it is fast, simple to use and has a great UX it will serve our users well.

## Building things in Verify

### Measure before you optimize, and make data-informed decisions

It is very difficult to optimize something that you cannot measure. How would you
know if you succeeded, or how significant the success was? If you are working on
a performance or reliability improvement, make sure that you measure things before
you optimize them.

The best way to measure stuff is to add a Prometheus metric. Counters, gauges, and
histograms are great ways to quickly get approximated results. Unfortunately this
is not the best way to measure tail latency. Prometheus metrics, especially histograms,
are usually approximations.

If you have to measure tail latency, like how slow something could be or how
large a request payload might be, consider adding custom application logs and
always use structured logging.

It's useful to use profiling and flamegraphs to understand what the code execution
path truly looks like!

### Strive for simple solutions, avoid clever solutions

It is sometimes tempting to use a clever solution to deliver something more
quickly. We want to avoid shipping clever code, because it is usually more
difficult to understand and maintain in the long term. Instead, we want to
focus on boring solutions that make it easier to evolve the codebase and keep the
contribution barrier low. We want to find solutions that are as simple as
possible.

### Do not confuse boring solutions with easy solutions

Boring solutions are sometimes confused with easy solutions. Very often the
opposite is true. An easy solution might not be simple - for example, a complex
new library can be included to add a very small functionality that otherwise
could be implemented quickly - it is easier to include this library than to
build this thing, but it would bring a lot of complexity into the product.

On the other hand, it is also possible to over-engineer a solution when a simple,
well tested, and well maintained library is available. In that case using the
library might make sense. We recognize that we are constantly balancing simple
and easy solutions, and that finding the right balance is important.

### "Simple" is not mutually exclusive with "flexible"

Building simple things does not mean that more advanced and flexible solutions
will not be available. A good example here is an expanding complexity of
writing `.gitlab-ci.yml` configuration. For example, you can use a simple
method to define an environment name:

```yaml
deploy:
  environment: production
  script: cap deploy
```

But the `environment` keyword can be also expanded into another level of
configuration that can offer more flexibility.

```yaml
deploy:
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://prod.example.com
  script: cap deploy
```

This kind of approach shields new users from the complexities of the platform,
but still allows them to go deeper if they need to. This approach can be
applied to many other technical implementations.

### Make things observable

GitLab is a DevOps platform. We popularize DevOps because it helps companies
be more efficient and achieve better results. One important component of
DevOps culture is to take ownership over features and code that you are
building. It is very difficult to do that when you don't know how your features
perform and behave in the production environment.

This is why we want to make our features and code observable. It
should be written in a way that an author can understand how well or how poorly
the feature or code behaves in the production environment. We usually accomplish
that by introducing the proper mix of Prometheus metrics and application
loggers.

**TODO** document when to use Prometheus metrics, when to use loggers. Write a
few sentences about histograms and counters. Write a few sentences highlighting
importance of metrics when doing incremental rollouts.

### Protect customer data

Making data produced by our CI/CD platform durable is important. We recognize that
data generated in the CI/CD by users and customers is
something important and we must protect it. This data is not only important
because it can contain important information, we also do have compliance and
auditing responsibilities.

Therefore we must take extra care when we are writing migrations
that permanently removes data from our database, or when we are define
new retention policies.

As a general rule, when you are writing code that is supposed to remove
data from the database, file system, or object storage, you should get an extra pair
of eyes on your changes. When you are defining a new retention policy, you
should double check with PMs and EMs.

### Get your design reviewed

When you are designing a subsystem for pipeline processing and transitioning
CI/CD statuses, request an additional opinion on the design from a Verify maintainer (`@gitlab-org/maintainers/cicd-verify`)
as early as possible and hold others accountable for doing the same. Having your
design reviewed by a Verify maintainer helps to identify any blind spots you might
have overlooked as early as possible and possibly leads to a better solution.

By having the design reviewed before any development work is started, it also helps to
make merge request review more efficient. You would be less likely to encounter
significantly differing opinions or change requests during the maintainer review
if the design has been reviewed by a Verify maintainer. As a result, the merge request
could be merged sooner.

### Get your changes reviewed

When your merge request is ready for reviews you must assign reviewers and then
maintainers. Depending on the complexity of a change, you might want to involve
the people that know the most about the codebase area you are changing. We do
have many domain experts and maintainers in Verify and it is absolutely
acceptable to ask them to review your code when you are not certain if a
reviewer or maintainer assigned by the Reviewer Roulette has enough context
about the change.

The reviewer roulette offers useful suggestions, but as assigning the right
reviewers is important it should not be done automatically every time. It might
not make sense to assign someone who knows nothing about the area you are
updating, because their feedback might be limited to code style and syntax.
Depending on the complexity and impact of a change, assigning the right people
to review your changes might be very important.

If you don't know who to assign, consult `git blame` or ask in the `#s_verify`
Slack channel (GitLab team members only).

There are two kinds of changes / merge requests that require additional
attention from reviews and an additional reviewer:

1. Merge requests changing code around pipelines / stages / builds statuses.
1. Merge requests changing code around authentication / security features.

In both cases engineers are expected to request a review from a maintainer and
a domain expert. If maintainer is the domain expert, involving another person
is recommended.

### Incremental rollouts

After your merge request is merged by a maintainer, it is time to release it to
users and the wider community. We usually do this with feature flags.
While not every merge request needs a feature flag, most merge
requests in Verify should have [feature flags](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags).

If you already follow the advice on this page, you probably already have a
few metrics and perhaps a few loggers added that make your new code observable
in the production environment. You can now use these metrics to incrementally
roll out your changes!

A typical scenario involves enabling a few features in a few internal projects
while observing your metrics or loggers. Be aware that there might be a
small delay involved in ingesting logs in Elastic or Kibana. After you confirm
the feature works well with internal projects you can start an
incremental rollout for other projects.

Avoid using "percent of time" incremental rollouts. These are error prone,
especially when you are checking feature flags in a few places in the codebase
and you have not memoized the result of a check in a single place.

### Do not cause our Universe to implode

During one of the first GitLab Contributes events we had a discussion about the importance
of keeping CI/CD pipeline, stage, and job statuses accurate. We considered a hypothetical
scenario relating to a software being built by one of our [early customers](https://about.gitlab.com/blog/2016/11/23/gitlab-adoption-growing-at-cern/)

> What happens if software deployed to the [Large Hadron Collider (LHC)](https://en.wikipedia.org/wiki/Large_Hadron_Collider),
> breaks because of a bug in GitLab CI/CD that showed that a pipeline
> passed, but this data was not accurate and the software deployed was actually
> invalid? A problem like this could cause the LHC to malfunction, which
> could generate a new particle that would then cause the universe to implode.

That would be quite an undesirable outcome of a small bug in GitLab CI/CD status
processing. Take extra care when you are working on CI/CD statuses,
we don't want to implode our Universe!

This is an extreme and unlikely scenario, but presenting data that is not accurate
can potentially cause a myriad of problems through the
[butterfly effect](https://en.wikipedia.org/wiki/Butterfly_effect).
There are much more likely scenarios that
can have disastrous consequences. GitLab CI/CD is being used by companies
building medical, aviation, and automotive software. Continuous Integration is
a mission critical part of software engineering.

### Definition of Done

In Verify, we follow our Development team's [Definition of Done](../merge_request_workflow.md#definition-of-done).
We also want to keep things efficient and [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) when we answer questions
and solve problems for our users.

For any issue that is resolved because the solution is supported with existing `.gitlab-ci.yml` syntax,
create a project in the [`ci-sample-projects`](https://gitlab.com/gitlab-org/ci-sample-projects) group
that demonstrates the solution.

The project must have:

- A simple title.
- A clear description.
- A `README.md` with:
  - A link to the resolved issue. You should also direct users to collaborate in the
    resolved issue if any questions arise.
  - A link to any relevant documentation.
  - A detailed explanation of what the example is doing.
