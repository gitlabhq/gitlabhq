# Runners API

API used by runners to register and delete itselves.

_**Note:** This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[new Runners API](../../api/runners.md)._

## Runners

### Register a new runner

__Authentication is done with a shared runner registration token or a project
specific runner registration token.__

Used to make GitLab CI aware of available runners.

    POST /runners/register

Parameters:

  * `token` (required) - The registration token.

It is 2 types of token you can pass here.

1. Shared runner registration token
2. Project specific registration token

### Delete a runner

__Authentication is done by using runner token.__

Used to remove runner.

    DELETE /runners/delete

Parameters:

  * `token` (required) - The runner token.
