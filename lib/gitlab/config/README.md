# `::Gitlab::Config` module overview

`::Gitlab::Config` is an abstract module used to build, traverse and translate
any kind of hierarchical, user-provided configuration.

The most complex and widely used implementation is `::Gitlab::Ci::Config`
facade class. Please see `lib/gitlab/ci/config/README.md` for more information
around how it works.

## High-level Overview

The main motivation behind how `::Gitlab::Config` and `::Gitlab::Ci::Config`
work is to build an indirection layer between complex user-provided
configuration and GitLab itself. This helps us to extend configuration keywords
in a backwards-compatible way, and make sure that validation and transformation
rules are encapsulated within domain classes, what significantly helps to
reduce cognitive load on Engineers working on that part of the codebase.

`Gitlab::Config` is a tool to work with hierarchical configuration:

1. First we parse YAML with Ruby standard library `Psych`.
1. The resulting hash is being used to initialize a concrete implementation of `Gitlab::Config`.
1. In `::Gitlab::Ci::Config` abstract classes from `::Gitlab::Config` have their implementations.
1. Each domain class represents one or a group of hierarchical YAML entries, like `job:artifacts`.
1. Each entry knows what subentires are supported and how to validate them.
1. Upon loading a configuration we build an abstract syntax tree, and validate configuration.
1. If there are errors, the module can surface them to a user.
1. In case of config being valid, the config gets translated and augmented.
1. The result is a consistent representation that we can depend on in other parts of the codebase.
