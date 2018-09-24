# Rolling out changes using feature flags

[Feature flags](feature_flags.md) can be used to gradually roll out changes, be
it a new feature, or a performance improvement. By using feature flags, we can
comfortably measure the impact of our changes, while still being able to easily
disable those changes, without having to revert an entire release.

## When to use feature flags

Starting with GitLab 11.4, developers are required to use feature flags for
non-trivial changes. Such changes include:

* New features (e.g. a new merge request widget, epics, etc).
* Complex performance improvements that may require additional testing in
  production, such as rewriting complex queries.
* Invasive changes to the user interface, such as a new navigation bar or the
  removal of a sidebar.
* Adding support for importing projects from a third-party service.

In all cases, those working on the changes can best decide if a feature flag is
necessary. For example, changing the color of a button doesn't need a feature
flag, while changing the navigation bar definitely needs one. In case you are
uncertain if a feature flag is necessary, simply ask about this in the merge
request, and those reviewing the changes will likely provide you with an answer.

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

## The cost of feature flags

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
Optimising for the best case scenario is guaranteed to lead to trouble, whereas
optimising for the worst case scenario is almost always better.

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
the worst case scenario, which we should optimise for, our total cost is now 20.

If we had used a feature flag, things would have been very different. We don't
need to revert a release, and because feature flags are disabled by default we
don't need to revert and pick any Git commits. In fact, all we have to do is
disable the feature, and _maybe_ perform some cleanup. Let's say that the cost
of this is 1. In this case, our best case cost is 11: 10 to build the feature,
and 1 to add the feature flag. The worst case cost is now 12: 10 to build the
feature, 1 to add the feature flag, and 1 to disable it.

Here we can see that in the best case scenario the work necessary is only a tiny
bit more compared to not using a feature flag. Meanwhile, the process of
reverting our changes has been made significantly cheaper, to the point of being
trivial.

In other words, feature flags do not slow down the development process. Instead,
they speed up the process as managing incidents now becomes _much_ easier. Once
continuous deployments are easier to perform, the time to iterate on a feature
is reduced even further, as you no longer need to wait weeks before your changes
are available on GitLab.com.

## Rolling out changes

The procedure of using feature flags is straightforward, and similar to not
using them. You add the necessary tests (make sure to test both the on and off
states of your feature flag(s)), make sure they all pass, have the code
reviewed, etc. You then submit your merge request, and add the ~"feature flag"
label. This label is used to signal to release managers that your changes are
hidden behind a feature flag and that it is safe to pick the MR into a stable
branch, without the need for an exception request.

When the changes are deployed it is time to start rolling out the feature to our
users. The exact procedure of rolling out a change is unspecified, as this can
vary from change to change. However, in general we recommend rolling out changes
incrementally, instead of enabling them for everybody right away. We also
recommend you to _not_ enable a feature _before_ the code is being deployed.
This allows you to separate rolling out a feature from a deploy, making it
easier to measure the impact of both separately.

GitLab's feature library (using
[Flipper](https://github.com/jnunemaker/flipper), and covered in the [Feature
Flags](feature_flags.md) guide) supports rolling out changes to a percentage of
users. This in turn can be controlled using [GitLab
chatops](https://docs.gitlab.com/ee/ci/chatops/).

For example, to enable a feature for 25% of all users, run the following in
Slack:

```
/chatops run feature set new_navigation_bar 25
```

This will enable the feature for GitLab.com, with `new_navigation_bar` being the
name of the feature. We can also enable the feature for <https://dev.gitlab.org>
or <https://staging.gitlab.com>:

```
/chatops run feature set new_navigation_bar 25 --dev
/chatops run feature set new_navigation_bar 25 --staging
```

If you are not certain what percentages to use, simply use the following steps:

1. 25%
1. 50%
1. 75%
1. 100%

Between every step you'll want to wait a little while and monitor the
appropriate graphs on <https://dashboards.gitlab.net>. The exact time to wait
may differ. For some features a few minutes is enough, while for others you may
want to wait several hours or even days. This is entirely up to you, just make
sure it is clearly communicated to your team, and the Production team if you
anticipate any potential problems.

Once a change is deemed stable, submit a new merge request to remove the
feature flag. This ensures the change is available to all users and self-hosted
instances. Make sure to add the ~"feature flag" label to this merge request so
release managers are aware the changes are hidden behind a feature flag. If the
merge request has to be picked into a stable branch (e.g. after the 7th), make
sure to also add the appropriate "Pick into X" label (e.g. "Pick into 11.4").

One might be tempted to think this will delay the release of a feature by at
least one month (= one release). This is not the case. A feature flag does not
have to stick around for a specific amount of time (e.g. at least one release),
instead they should stick around until the feature is deemed stable. Stable
means it works on GitLab.com without causing any problems, such as outages. In
most cases this will translate to a feature (with a feature flag) being shipped
in RC1, followed by the feature flag being removed in RC2. This in turn means
the feature will be stable by the time we publish a stable package around the
22nd of the month.
