# Settings Module

## Overview

The `Gitlab::Fp::Settings` module contains support for the Settings Module pattern used
currently by the Remote Development Workspace and Web IDE domains. This pattern is
based on the ["Functional Programming"](../../../ee/lib/remote_development/README.md#functional-patterns) and ["Railway Oriented Programming and the Result Class"](../../../ee/lib/remote_development/README.md#railway-oriented-programming-and-the-result-class) patterns.

It is in the process of being extracted from the `RemoteDevelopment` domain code,
and made available for wider use in the monolith.

See the following section in the [Remote Development Rails domain developer documentation](../../../ee/lib/remote_development/README.md) for more context:

- [Remote Development Settings](../../../ee/lib/remote_development/README.md#remote-development-settings)
