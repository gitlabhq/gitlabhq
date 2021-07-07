---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cron

Cron syntax is used to schedule when jobs should run.

You may need to use a cron syntax string to
[trigger nightly pipelines](../../ci/triggers/index.md#using-cron-to-trigger-nightly-pipelines),
create a [pipeline schedule](../../api/pipeline_schedules.md#create-a-new-pipeline-schedule),
or to prevent unintentional releases by setting a
[deploy freeze](../../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).

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
- Run once a year at midnight of 1 January: `0 0 1 1 *`

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
strings on the server and [cron-validate](https://github.com/Airfooox/cron-validate)
to validate cron syntax in the browser.
