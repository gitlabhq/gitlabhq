---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Feature flags process

## Feature flags for user applications

This document only covers feature flags used in the development of GitLab
itself. Feature flags in deployed user applications can be found at
[Feature Flags feature documentation](../../operations/feature_flags.md).

## Feature flags in GitLab development

The following highlights should be considered when deciding if feature flags
should be leveraged:

- By default, the feature flags should be **off**.
- Feature flags should remain in the codebase for as short period as possible
  to reduce the need for feature flag accounting.
- The person operating with feature flags is responsible for clearly communicating
  the status of a feature behind the feature flag with responsible stakeholders. The
  issue description should be updated with the feature flag name and whether it is
  defaulted on or off as soon it is evident that a feature flag is needed.
- Merge requests that make changes hidden behind a feature flag, or remove an
  existing feature flag because a feature is deemed stable must have the
  ~"feature flag" label assigned.
- When development of a feature will be spread across multiple merge
  requests, you can use the following workflow:

  1. [Create a new feature flag](development.md#create-a-new-feature-flag)
     which is **off** by default, in the first merge request which uses the flag.
     Flags [should not be added separately](development.md#risk-of-a-broken-master-main-branch).
  1. Submit incremental changes via one or more merge requests, ensuring that any
     new code added can only be reached if the feature flag is **on**.
     You can keep the feature flag enabled on your local GDK during development.
  1. When the feature is ready to be tested, enable the feature flag for
     a specific project and ensure that there are no issues with the implementation.
  1. When the feature is ready to be announced, create a merge request that adds
     documentation about the feature, including [documentation for the feature flag itself](../documentation/feature_flags.md),
     and a changelog entry. In the same merge request either flip the feature flag to
     be **on by default** or remove it entirely in order to enable the new behavior.

One might be tempted to think that feature flags will delay the release of a
feature by at least one month (= one release). This is not the case. A feature
flag does not have to stick around for a specific amount of time
(e.g. at least one release), instead they should stick around until the feature
is deemed stable. Stable means it works on GitLab.com without causing any
problems, such as outages.

Please also read the [development guide for feature flags](development.md).

### Including a feature behind feature flag in the final release

In order to build a final release and present the feature for self-managed
users, the feature flag should be at least defaulted to **on**. If the feature
is deemed stable and there is confidence that removing the feature flag is safe,
consider removing the feature flag altogether. It's _strongly_ recommended that
the feature flag is [enabled **globally** on **production**](controls.md#enabling-a-feature-for-gitlabcom) for **at least one day**
before making this decision. Unexpected bugs are sometimes discovered during this period.

The process for enabling features that are disabled by default can take 5-6 days
from when the merge request is first reviewed to when the change is deployed to
GitLab.com. However, it is recommended to allow 10-14 days for this activity to
account for unforeseen problems.

Feature flags must be [documented according to their state (enabled/disabled)](../documentation/feature_flags.md),
and when the state changes, docs **must** be updated accordingly.

NOTE:
Take into consideration that such action can make the feature available on
GitLab.com shortly after the change to the feature flag is merged.

Changing the default state or removing the feature flag has to be done before
the 22nd of the month, _at least_ 3-4 working days before, in order for the change
to be included in the final self-managed release.

In addition to this, the feature behind feature flag should:

- Run in all GitLab.com environments for a sufficient period of time. This time
  period depends on the feature behind the feature flag, but as a general rule of
  thumb 2-4 working days should be sufficient to gather enough feedback.
- The feature should be exposed to all users within the GitLab.com plan during
  the above mentioned period of time. Exposing the feature to a smaller percentage
  or only a group of users might not expose a sufficient amount of information to aid in
  making a decision on feature stability.

While rare, release managers may decide to reject picking or revert a change in
a stable branch, even when feature flags are used. This might be necessary if
the changes are deemed problematic, too invasive, or there simply isn't enough
time to properly measure how the changes behave on GitLab.com.

### The cost of feature flags

When reading the above, one might be tempted to think this procedure is going to
add a lot of work. Fortunately, this is not the case, and we'll show why. For
this example we'll specify the cost of the work to do as a number, ranging from
0 to infinity. The greater the number, the more expensive the work is. The cost
does _not_ translate to time, it's just a way of measuring complexity of one
change relative to another.

Let's say we are building a new feature, and we have determined that the cost of
this is 10. We have also determined that the cost of adding a feature flag check
in a variety of places is 1. If we do not use feature flags, and our feature
works as intended, our total cost is 10. This however is the best case scenario.
Optimizing for the best case scenario is guaranteed to lead to trouble, whereas
optimizing for the worst case scenario is almost always better.

To illustrate this, let's say our feature causes an outage, and there's no
immediate way to resolve it. This means we'd have to take the following steps to
resolve the outage:

1. Revert the release.
1. Perform any cleanups that might be necessary, depending on the changes that
   were made.
1. Revert the commit, ensuring the "master" branch remains stable. This is
   especially necessary if solving the problem can take days or even weeks.
1. Pick the revert commit into the appropriate stable branches, ensuring we
   don't block any future releases until the problem is resolved.

As history has shown, these steps are time consuming, complex, often involve
many developers, and worst of all: our users will have a bad experience using
GitLab.com until the problem is resolved.

Now let's say that all of this has an associated cost of 10. This means that in
the worst case scenario, which we should optimize for, our total cost is now 20.

If we had used a feature flag, things would have been very different. We don't
need to revert a release, and because feature flags are disabled by default we
don't need to revert and pick any Git commits. In fact, all we have to do is
disable the feature, and in the worst case, perform cleanup. Let's say that
the cost of this is 2. In this case, our best case cost is 11: 10 to build the
feature, and 1 to add the feature flag. The worst case cost is now 13:

- 10 to build the feature.
- 1 to add the feature flag.
- 2 to disable and clean up.

Here we can see that in the best case scenario the work necessary is only a tiny
bit more compared to not using a feature flag. Meanwhile, the process of
reverting our changes has been made significantly and reliably cheaper.

In other words, feature flags do not slow down the development process. Instead,
they speed up the process as managing incidents now becomes _much_ easier. Once
continuous deployments are easier to perform, the time to iterate on a feature
is reduced even further, as you no longer need to wait weeks before your changes
are available on GitLab.com.

### The benefits of feature flags

It may seem like feature flags are configuration, which goes against our [convention-over-configuration](https://about.gitlab.com/handbook/product/product-principles/#convention-over-configuration)
principle. However, configuration is by definition something that is user-manageable.
Feature flags are not intended to be user-editable. Instead, they are intended as a tool for Engineers
and Site Reliability Engineers to use to de-risk their changes. Feature flags are the shim that gets us
to Continuous Delivery with our mono repo and without having to deploy the entire codebase on every change. 
Feature flags are created to ensure that we can safely rollout our work on our terms.
If we use Feature Flags as a configuration, we are doing it wrong and are indeed in violation of our
principles. If something needs to be configured, we should intentionally make it configuration from the
first moment.

Some of the benefits of using development-type feature flags are:

1. It enables Continuous Delivery for GitLab.com.
1. It significantly reduces Mean-Time-To-Recovery.
1. It helps engineers to monitor and reduce the impact of their changes gradually, at any scale,
   allowing us to be more metrics-driven and execute good DevOps practices, [shifting some responsibility "left"](https://devops.com/why-its-time-for-site-reliability-engineering-to-shift-left/).
1. Controlled feature rollout timing: without feature flags, we would need to wait until a specific
   deployment was complete (which at GitLab could be at any time).
1. Increased psychological safety: when a feature flag is used, an engineer has the confidence that if anything goes wrong they can quickly disable the code and minimize the impact of a change that might be risky.
1. Improved throughput: when a change is less risky because a flag exists, theoretical tests about
   scalability can potentially become unnecessary or less important. This allows an engineer to
   potentially test a feature on a small project, monitor the impact, and proceed. The alternative might
   be to build complex benchmarks locally, or on staging, or on another GitLab deployment, which has an
   outsized impact on the time it can take to build and release a feature.
