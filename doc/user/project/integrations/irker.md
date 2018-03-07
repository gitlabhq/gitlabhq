# Irker IRC Gateway

GitLab provides a way to push update messages to an Irker server. When
configured, pushes to a project will trigger the service to send data directly
to the Irker server.

See the project homepage for further info: https://gitlab.com/esr/irker

## Needed setup

You will first need an Irker daemon. You can download the Irker code from its
repository on https://gitlab.com/esr/irker:

```
git clone https://gitlab.com/esr/irker.git
```

Once you have downloaded the code, you can run the python script named `irkerd`.
This script is the gateway script, it acts both as an IRC client, for sending
messages to an IRC server obviously, and as a TCP server, for receiving messages
from the GitLab service.

If the Irker server runs on the same machine, you are done. If not, you will
need to follow the firsts steps of the next section.

## Complete these steps in GitLab

1. Navigate to the project you want to configure for notifications.
1. Navigate to the [Integrations page](project_services.md#accessing-the-project-services)
1. Click "Irker".
1. Select the "Active" checkbox.
1. Enter the server host address where `irkerd` runs (defaults to `localhost`)
in the `Server host` field on the Web page
1. Enter the server port of `irkerd` (e.g. defaults to 6659) in the
`Server port` field on the Web page.
1. Optional: if `Default IRC URI` is set, it has to be in the format
`irc[s]://domain.name` and will be prepend to each and every channel provided
by the user which is not a full URI.
1. Specify the recipients (e.g. #channel1, user1, etc.)
1. Save or optionally click "Test Settings".

## Note on Irker recipients

Irker accepts channel names of the form `chan` and `#chan`, both for the
`#chan` channel. If you want to send messages in query, you will need to add
`,isnick` after the channel name, in this form: `Aorimn,isnick`. In this latter
case, `Aorimn` is treated as a nick and no more as a channel name.

Irker can also join password-protected channels. Users need to append
`?key=thesecretpassword` to the chan name.  When using this feature remember to
**not** put the `#` sign in front of the channel name; failing to do so will
result on irker joining a channel literally named `#chan?key=password` henceforth
leaking the channel key through the `/whois` IRC command (depending on IRC server
configuration). This is due to a long standing irker bug.
