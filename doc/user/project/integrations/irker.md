---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: irker (IRC gateway)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab provides a way to push update messages to an irker server. After you configure
the integration, each push to a project triggers the integration to send data directly
to the irker server.

See also the [irker integration API documentation](../../../api/integrations.md).

For more information, see the [irker project homepage](https://gitlab.com/esr/irker).

## Set up an irker daemon

You need to set up an irker daemon. To do so:

1. Download the irker code [from its repository](https://gitlab.com/esr/irker):

   ```shell
   git clone https://gitlab.com/esr/irker.git
   ```

1. Run the Python script named `irkerd`. This is the gateway script.
   It acts both as an IRC client, for sending messages to an IRC server,
   and as a TCP server, for receiving messages from the GitLab service.

If the irker server runs on the same machine, you are done. If not, you
need to follow the first steps of the next section.

WARNING:
irker does **not** have built-in authentication, which makes it vulnerable to spamming IRC channels if
it is hosted outside of a firewall. To prevent abuse, make sure you run the daemon on a secured
network. For more details, read
[Security analysis of irker](http://www.catb.org/~esr/irker/security.html).

## Complete these steps in GitLab

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **irker (IRC gateway)**.
1. Ensure that the **Active** toggle is enabled.
1. Optional. Under **Server host**, enter the server host address where `irkerd` runs. If empty,
   it defaults to `localhost`.
1. Optional. Under **Server port**, enter the server port of `irkerd`. If empty, it defaults to `6659`.
1. Optional. Under **Default IRC URI**, enter the default IRC URI, in the format `irc[s]://domain.name`.
   It's prepended to every channel or user provided under **Recipients**, which is not a full URI.
1. Under **Recipients**, enter the users or channels to receive updates, separated by spaces
   (for example, `#channel1 user1`). For more details, see [Enter irker recipients](#enter-irker-recipients).
1. Optional. To highlight messages, select the **Colorize messages** checkbox.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

## Enter irker recipients

If you left the **Default IRC URI** field empty, enter recipients as a full URI:
`irc[s]://irc.network.net[:port]/#channel`. If you entered a default IRC URI there, you can use just
channel or user names.

To send messages:

- To a channel (for example, `#chan`), irker accepts channel names of the form `chan` and
  `#chan`.
- To a password-protected channel, append `?key=thesecretpassword` to the channel name,
  with the channel password instead of `thesecretpassword`. For example, `chan?key=hunter2`.
  Do **not** put the `#` sign in front of the channel name. If you do, irker tries to join a
  channel named `#chan?key=password` and so it can leak the channel password through the
  `/whois` IRC command. This is due to a long-standing irker bug.
- In a user query, add `,isnick` after the user name. For example, `UserSmith,isnick`.
