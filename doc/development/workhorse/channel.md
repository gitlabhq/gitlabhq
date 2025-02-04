---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Websocket channel support for Workhorse
---

In some cases, GitLab can provide the following through a WebSocket:

- In-browser terminal access to an environment: a running server or container,
  onto which a project has been deployed.
- Access to services running in CI.

Workhorse manages the WebSocket upgrade and long-lived connection to the websocket
connection, which frees up GitLab to process other requests. This document outlines
the architecture of these connections.

## Introduction to WebSockets

Websockets are an "upgraded" `HTTP/1.1` request. They permit bidirectional
communication between a client and a server. **Websockets are not HTTP**.
Clients can send messages (known as frames) to the server at any time, and
vice versa. Client messages are not necessarily requests, and server messages are
not necessarily responses. WebSocket URLs have schemes like `ws://` (unencrypted) or
`wss://` (TLS-secured).

When requesting an upgrade to WebSocket, the browser sends a `HTTP/1.1`
request like this:

```plaintext
GET /path.ws HTTP/1.1
Connection: upgrade
Upgrade: websocket
Sec-WebSocket-Protocol: terminal.gitlab.com
# More headers, including security measures
```

At this point, the connection is still HTTP, so this is a request.
The server can send a standard HTTP response, such as `404 Not Found` or
`500 Internal Server Error`.

If the server decides to permit the upgrade, it sends a HTTP
`101 Switching Protocols` response. From this point, the connection is no longer
HTTP. It is now a WebSocket and frames, not HTTP requests, flow over it. The connection
persists until the client or server closes the connection.

In addition to the sub-protocol, individual websocket frames may
also specify a message type, such as:

- `BinaryMessage`
- `TextMessage`
- `Ping`
- `Pong`
- `Close`

Only binary frames can contain arbitrary data. The frames are expected to be valid
UTF-8 strings, in addition to any sub-protocol expectations.

## Browser to Workhorse

Using the terminal as an example:

1. GitLab serves a JavaScript terminal emulator to the browser on a URL like
   `https://gitlab.com/group/project/-/environments/1/terminal`.
1. This URL opens a websocket connection to
   `wss://gitlab.com/group/project/-/environments/1/terminal.ws`.
   This endpoint exists only in Workhorse, and doesn't exist in GitLab.
1. When receiving the connection, Workhorse first performs a `preauthentication`
   request to GitLab to confirm the client is authorized to access the requested terminal:
   - If the client has the appropriate permissions and the terminal exists, GitLab
     responds with a successful response that includes details of the terminal
     the client should be connected to.
   - Otherwise, Workhorse returns an appropriate HTTP error response.
1. If GitLab returns valid terminal details to Workhorse, it:
   1. Connects to the specified terminal.
   1. Upgrades the browser to a WebSocket.
   1. Proxies between the two connections for as long as the browser's credentials are valid.
   1. Send regular `PingMessage` control frames to the browser, to prevent intervening
      proxies from terminating the connection while the browser is present.

The browser must request an upgrade with a specific sub-protocol:

- [`terminal.gitlab.com`](#terminalgitlabcom)
- [`base64.terminal.gitlab.com`](#base64terminalgitlabcom)

### `terminal.gitlab.com`

This sub-protocol considers `TextMessage` frames to be invalid. Control frames,
such as `PingMessage` or `CloseMessage`, have their usual meanings.

- `BinaryMessage` frames sent from the browser to the server are
  arbitrary text input.
- `BinaryMessage` frames sent from the server to the browser are
  arbitrary text output.

These frames are expected to contain ANSI text control codes
and may be in any encoding.

### `base64.terminal.gitlab.com`

This sub-protocol considers `BinaryMessage` frames to be invalid.
Control frames, such as `PingMessage` or `CloseMessage`, have
their usual meanings.

- `TextMessage` frames sent from the browser to the server are
  base64-encoded arbitrary text input. The server must
  base64-decode them before inputting them.
- `TextMessage` frames sent from the server to the browser are
  base64-encoded arbitrary text output. The browser must
  base64-decode them before outputting them.

In their base64-encoded form, these frames are expected to
contain ANSI terminal control codes, and may be in any encoding.

## Workhorse to GitLab

Using the terminal as an example, before upgrading the browser,
Workhorse sends a standard HTTP request to GitLab on a URL like
`https://gitlab.com/group/project/environments/1/terminal.ws/authorize`.
This returns a JSON response containing details of where the
terminal can be found, and how to connect it. In particular,
the following details are returned in case of success:

- WebSocket URL to connect** to, such as `wss://example.com/terminals/1.ws?tty=1`.
- WebSocket sub-protocols to support, such as `["channel.k8s.io"]`.
- Headers to send, such as `Authorization: Token xxyyz`.
- Optional. Certificate authority to verify `wss` connections with.

Workhorse periodically rechecks this endpoint. If it receives an error response,
or the details of the terminal change, it terminates the websocket session.

## Workhorse to the WebSocket server

In GitLab, environments or CI jobs may have a deployment service (like
`KubernetesService`) associated with them. This service knows
where the terminals or the service for an environment may be found, and GitLab
returns these details to Workhorse.

These URLs are also WebSocket URLs. GitLab tells Workhorse which sub-protocols to
speak over the connection, along with any authentication details required by the
remote end.

Before upgrading the browser's connection to a websocket, Workhorse:

1. Opens a HTTP client connection, according to the details given to it by Workhorse.
1. Attempts to upgrade that connection to a websocket.
   - If it fails, an error response is sent to the browser.
   - If it succeeds, the browser is also upgraded.

Workhorse now has two websocket connections, albeit with differing sub-protocols,
and then:

- Decodes incoming frames from the browser, re-encodes them to the channel's
  sub-protocol, and sends them to the channel.
- Decodes incoming frames from the channel, re-encodes them to the browser's
  sub-protocol, and sends them to the browser.

When either connection closes or enters an error state, Workhorse detects the error
and closes the other connection, terminating the channel session. If the browser
is the connection that has disconnected, Workhorse sends an ANSI `End of Transmission`
control code (the `0x04` byte) to the channel, encoded according to the appropriate
sub-protocol. To avoid being disconnected, Workhorse replies to any websocket ping
frame sent by the channel.

Workhorse only supports the following sub-protocols:

- [`channel.k8s.io`](#channelk8sio)
- [`base64.channel.k8s.io`](#base64channelk8sio)

Supporting new deployment services requires new sub-protocols to be supported.

### `channel.k8s.io`

Used by Kubernetes, this sub-protocol defines a multiplexed channel.

Control frames have their usual meanings. `TextMessage` frames are
invalid. `BinaryMessage` frames represent I/O to a specific file
descriptor.

The first byte of each `BinaryMessage` frame represents the file
descriptor (`fd`) number, as a `uint8`. For example:

- `0x00` corresponds to `fd 0`, `STDIN`.
- `0x01` corresponds to `fd 1`, `STDOUT`.

The remaining bytes represent arbitrary data. For frames received
from the server, they are bytes that have been received from that
`fd`. For frames sent to the server, they are bytes that should be
written to that `fd`.

### `base64.channel.k8s.io`

Also used by Kubernetes, this sub-protocol defines a similar multiplexed
channel to `channel.k8s.io`. The main differences are:

- `TextMessage` frames are valid, rather than `BinaryMessage` frames.
- The first byte of each `TextMessage` frame represents the file
  descriptor as a numeric UTF-8 character, so the character `U+0030`,
  or "0", is `fd 0`, `STDIN`.
- The remaining bytes represent base64-encoded arbitrary data.
