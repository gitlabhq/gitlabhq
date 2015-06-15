# Irker IRC Gateway

GitLab provides a way to push update messages to an Irker server. When
configured, pushes to a project will trigger the service to send data directly
to the Irker server.

See the project homepage for further info: https://gitlab.com/esr/irker

## Needed setup

You will first need an Irker daemon. You can download the Irker code from its
gitorious repository on https://gitorious.org/irker: `git clone
git@gitorious.org:irker/irker.git`. Once you have downloaded the code, you can
run the python script named `irkerd`. This script is the gateway script, it acts
both as an IRC client, for sending messages to an IRC server obviously, and as a
TCP server, for receiving messages from the GitLab service.

If the Irker server runs on the same machine, you are done. If not, you will
need to follow the firsts steps of the next section.

## Optional setup

In the `app/models/project_services/irker_service.rb` file, you can modify some
options in the `initialize_settings` method:
- **server_ip** (defaults to `localhost`): the server IP address where the
`irkerd` daemon runs;
- **server_port** (defaults to `6659`): the server port of the `irkerd` daemon;
- **max_channels** (defaults to `3`): the maximum number of recipients the
client is authorized to join, per project;
- **default_irc_uri** (no default) : if this option is set, it has to be in the
format `irc[s]://domain.name` and will be prepend to each and every channel
provided by the user which is not a full URI.

If the Irker server and the GitLab application do not run on the same host, you
will **need** to setup at least the **server_ip** option.

## Note on Irker recipients

Irker accepts channel names of the form `chan` and `#chan`, both for the
`#chan` channel. If you want to send messages in query, you will need to add
`,isnick` avec the channel name, in this form: `Aorimn,isnick`. In this latter
case, `Aorimn` is treated as a nick and no more as a channel name.

Irker can also join password-protected channels. Users need to append
`?key=thesecretpassword` to the chan name.

