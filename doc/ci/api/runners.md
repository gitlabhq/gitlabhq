# Runners API

API used by runners to register and delete themselves.

_**Note:** This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[new Runners API](../../api/runners.md)._

## Authentication

This API uses two types of authentication:

1.   Unique runner's token

     Token assigned to runner after it has been registered.

2.   Using runners' registration token

     This is a token that can be found in project's settings.
     It can be also found in Admin area &raquo; Runners settings.

     There are two types of tokens you can pass - shared runner registration
     token or project specific registration token.

## Runners

### Register a new runner

Used to make GitLab CI aware of available runners.

    POST /ci/api/v1/runners/register

Parameters:

  * `token` (required) - Registration token


### Delete a runner

Used to remove runner.

    DELETE /ci/api/v1/runners/delete

Parameters:

  * `token` (required) - Unique runner token
