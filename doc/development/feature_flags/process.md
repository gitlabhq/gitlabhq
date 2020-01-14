# Feature flags process

## Feature flags for user applications

This document only covers feature flags used in the development of GitLab
itself. Feature flags in deployed user applications can be found at
[Feature Flags feature documentation](../../user/project/operations/feature_flags.md).

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

One might be tempted to think that feature flags will delay the release of a
feature by at least one month (= one release). This is not the case. A feature
flag does not have to stick around for a specific amount of time
(e.g. at least one release), instead they should stick around until the feature
is deemed stable. Stable means it works on GitLab.com without causing any
problems, such as outages.

### When to use feature flags

Starting with GitLab 11.4, developers are required to use feature flags for
non-trivial changes. Such changes include:

- New features (e.g. a new merge request widget, epics, etc).
- Complex performance improvements that may require additional testing in
  production, such as rewriting complex queries.
- Invasive changes to the user interface, such as a new navigation bar or the
  removal of a sidebar.
- Adding support for importing projects from a third-party service.

In all cases, those working on the changes can best decide if a feature flag is
necessary. For example, changing the color of a button doesn't need a feature
flag, while changing the navigation bar definitely needs one. In case you are
uncertain if a feature flag is necessary, simply ask about this in the merge
request, and those reviewing the changes will likely provide you with an answer.

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

### Including a feature behind feature flag in the final release

In order to build a final release and present the feature for self-hosted
users, the feature flag should be at least defaulted to **on**. If the feature
is deemed stable and there is confidence that removing the feature flag is safe,
consider removing the feature flag altogether.

The process for enabling features that are disabled by default can take 5-6 days
from when the merge request is first reviewed to when the change is deployed to
GitLab.com. However, it is recommended to allow 10-14 days for this activity to
account for unforeseen problems.

NOTE: **Note:**
Take into consideration that such action can make the feature available on
GitLab.com shortly after the change to the feature flag is merged.

Changing the default state or removing the feature flag has to be done before
the 22nd of the month, _at least_ 2 working days before, in order for the change
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
feature, and 1 to add the feature flag. The worst case cost is now 13: 10 to
build the feature, 1 to add the feature flag, and 2 to disable and clean up.

Here we can see that in the best case scenario the work necessary is only a tiny
bit more compared to not using a feature flag. Meanwhile, the process of
reverting our changes has been made significantly and reliably cheaper.

In other words, feature flags do not slow down the development process. Instead,
they speed up the process as managing incidents now becomes _much_ easier. Once
continuous deployments are easier to perform, the time to iterate on a feature
is reduced even further, as you no longer need to wait weeks before your changes
are available on GitLab.com.
