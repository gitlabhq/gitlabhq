---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Cron
---

Cron syntax is used to schedule when jobs should run.

You may need to use a cron syntax string to
create a [pipeline schedule](../../ci/pipelines/schedules.md),
or to prevent unintentional releases by setting a
[deploy freeze](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).

## Cron syntax

Cron scheduling uses a series of five numbers, separated by spaces:

```plaintext
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# │ │ │ │ │
# │ │ │ │ │
# * * * * * <command to execute>
```

(Source: [Wikipedia](https://en.wikipedia.org/wiki/Cron))

In cron syntax, the asterisk (`*`) means 'every,' so the following cron strings
are valid:

- Run once an hour at the beginning of the hour: `0 * * * *`
- Run once a day at midnight: `0 0 * * *`
- Run once a week at midnight on Sunday morning: `0 0 * * 0`
- Run once a month at midnight of the first day of the month: `0 0 1 * *`
- Run once a month on the 22nd: `0 0 22 * *`
- Run once a month on the 2nd Monday: `0 0 * * 1#2`
- Run once a year at midnight of 1 January: `0 0 1 1 *`
- Run every other Sunday at 0900 hours: `0 9 * * sun%2`
- Run twice a month at 3 AM, on the 1st and 15th of the month: `0 3 1,15 * *`
  - This syntax is from the [fugit modulo extension](https://github.com/floraison/fugit#the-modulo-extension)

For complete cron documentation, refer to the
[crontab(5) — Linux manual page](https://man7.org/linux/man-pages/man5/crontab.5.html).
This documentation is accessible offline by entering `man 5 crontab` in a Linux or MacOS
terminal.

## Cron examples

```plaintext
# Run at 7:00pm every day:
0 19 * * *

# Run every minute on the 3rd of June:
* * 3 6 *

# Run at 06:30 every Friday:
30 6 * * 5
```

More examples of how to write a cron schedule can be found at
[crontab.guru](https://crontab.guru/examples.html).

## How GitLab parses cron syntax strings

GitLab uses [`fugit`](https://github.com/floraison/fugit) to parse cron syntax
strings on the server and [cron-validator](https://github.com/TheCloudConnectors/cron-validator)
to validate cron syntax in the browser. GitLab uses
[`cRonstrue`](https://github.com/bradymholt/cRonstrue) to convert cron to human-readable strings
in the browser.
