<--

Instructions:

1. Replace all occurrences of X.Y to the release that is targeted as an upgrade stop.
2. Give the issue a title: "X.Y upgrade stop planning"
3. Replace the <deadline date> with the ISO date 10 days before the [release date](https://about.gitlab.com/releases/) (this is always two Fridays before).

-->

This planning issue collects a list of changes that require an upgrade stop to X.Y.

## Notes for all engineering managers

To help to determine whether %"X.Y" is a required stop,
add your issue to the list below before `<deadline date>` (your local time).

You can review the [Common scenarios that require stops](https://docs.gitlab.com/ee/development/database/required_stops.html) and
[avoiding required stops](https://docs.gitlab.com/ee/development/avoiding_required_stops.html) to
confirm. If you are still not sure after reviewing the documentation, leave a
comment with the link to your issue or epic in this issue for others to review.

If your change requires an upgrade stop and cannot wait until %"X.Y", please
reach out to `@dorrino` and `@plu8`.

### List of changes that require an upgrade stop for version X.Y

- <epic or issue link>

## Notes for the issue author only

### After the issue creation

Slack message template:

>>>
The Distribution::Deploy group created an issue (link to this issue) to
determine if X.Y needs to be [a required upgrade
stop](https://docs.gitlab.com/ee/development/avoiding_required_stops.html#causes-of-required-stops). Please review your
upcoming changes and share any may require upgrade stop on the issue (link to
this issue), thank you.
>>>

- [ ] Update "Next Required Stop" bookmark in `#g_distribution` to this issue link.
- [ ] Update [EWIR](https://docs.google.com/document/d/1JBdCl3MAOSdlgq3kzzRmtzTsFWsTIQ9iQg0RHhMht6E/edit#heading=h.9qwiojcv4wzk).
- [ ] Use the previous Slack message template to post to `#engineering-fyi` and cross post to:
  - [ ] `#eng-managers`
  - [ ] `#cto`

### After the decision is made

#### If X.Y is an upgrade stop

Slack message template:

>>>
An update on the next upgrade stop (link to this issue), x.y is a planned
upgrade stop. It is a great opportunity to plan tasks as mentioned on
[Adding required stops](https://docs.gitlab.com/ee/development/database/required_stops.html)
and [Avoiding required stops](https://docs.gitlab.com/ee/development/avoiding_required_stops.html).
>>>

- [ ] Comment on this issue.
- [ ] Update [EWIR](https://docs.google.com/document/d/1JBdCl3MAOSdlgq3kzzRmtzTsFWsTIQ9iQg0RHhMht6E/edit#heading=h.9qwiojcv4wzk).
- [ ] Use the previous Slack message template to post to `#engineering-fyi` and cross post to:
  - [ ] `#eng-managers`
  - [ ] `#cto`
  - [ ] `#whats-happening-at-gitlab`
  - [ ] `#support_self-managed`

#### If X.Y is not an upgrade stop

Slack message template:

>>>
An update on the next upgrade stop (link to this issue), X.Y is NOT a planned upgrade stop.
>>>

- [ ] Comment on this issue.
- [ ] Update [EWIR](https://docs.google.com/document/d/1JBdCl3MAOSdlgq3kzzRmtzTsFWsTIQ9iQg0RHhMht6E/edit#heading=h.9qwiojcv4wzk).
- [ ] Use the previous Slack message template to post to `#engineering-fyi` and cross post to:
  - [ ] `#eng-managers`
  - [ ] `#cto`

/cc @gitlab-org/development-leaders
