---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Request Profiling

To profile a request:

1. Sign in to GitLab as a user with Administrator or Maintainer [permissions](../../../user/permissions.md).
1. In the navigation bar, click **{admin}** **Admin area**.
1. Navigate to **{monitor}** **Monitoring > Requests Profiles**.
1. In the **Requests Profiles** section, copy the token.
1. Pass the headers `X-Profile-Token: <token>` and `X-Profile-Mode: <mode>`(where
   `<mode>` can be `execution` or `memory`) to the request you want to profile. When
   passing headers, you can use:

   - Browser extensions such as the
     [ModHeader](https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj)
     Chrome extension.
   - `curl`. For example:

     ```shell
     curl --header 'X-Profile-Token: <token>' --header 'X-Profile-Mode: <mode>' "https://gitlab.example.com/group/project"
     ```

     NOTE: **Note:**
     Profiled requests can take longer than usual.

After the request completes, you can view the profiling output from the
**{monitor}** **Monitoring > Requests Profiles** administration page:

![Profiling output](img/request_profile_result.png)

## Cleaning up profiled requests

The output from profiled requests is cleared out once each day through a
Sidekiq worker.
