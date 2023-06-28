# `::Gitlab::Ci::Config` module overview

`::Gitlab::Ci::Config` is a concrete implementation of abstract
`::Gitlab::Config` module. It's being used to build, traverse and translate
hierarchical, user-provided, CI configuration, usually provided in
`.gitlab-ci.yml` and included files.

## High-level Overview

`::Gitlab::Ci::Config` is an indirection layer between user-provided data and
GitLab itself.

1. A user provides YAML configuration in `.gitlab-ci.yml` and all included files.
1. `::Gitlab::Ci::Config` loads the provided YAML using Ruby standard `Psych` library.
1. The resulting Hash is then passed to the module to build an Abstract Syntax Tree.
1. The module validates, transforms, translates and augments the data to build
   a stable representation of user-provided configuration.

This additional layer helps us to validate the user-provided configuration and
surface any errors to a user if it is not valid. In case of a valid
configuration, it makes it possible to build a stable representation of
config that we can depend on.

For example, both following configurations using the
[environment](https://docs.gitlab.com/ee/ci/yaml/#environment)
keyword are correct:

```yaml
# First way to define an environment:

deploy:
  environment: production
  script: cap deploy

# Second way to define an environment:

deploy:
  environment:
    name: production
    url: https://prod.example.com
    kubernetes:
      namespace: production
```

This demonstrates the concept of hidden / expanding complexity: if users need
more flexibility, they can opt-in into using a much more elaborate syntax to
configure their environments. **We use this technique to make it possible for
simplicity to coexist with flexibility without additional complexity**.

`::Gitlab::Ci::Config` allows us to achieve this, because it is an indirection
layer, that translates user-provided configuration into a known and expected
format when users can achieve the same thing in `.gitlab-ci.yml` in a few
different ways.

## Hierarchical configuration

`.gitlab-ci.yml` configuration is hierarchical but same keywords can often be
used on different levels in the hierarchy. `::Gitlab::Ci::Config` module makes
it easier to manage the complexity that stems from having same keyword
available in [many different places](https://docs.gitlab.com/ee/ci/yaml/#default):

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

We can achieve that, because in `::Gitlab::Ci::Config` most of the keywords are
implemented within separate Ruby classes, that then can be reused:

```ruby
# Simplified version of an entry class that describes a Docker image.
#
class Gitlab::Ci::Config::Entry
  class Image < ::Gitlab::Config::Entry::Node

    validates :config, allowed_keys: ALLOWED_IMAGE_CONFIG_KEYS

    def value
      if string?
        { name: @config }
      elsif hash?
        {
          name: @config[:name],
          entrypoint: @config[:entrypoint],
          ports: (ports_value if ports_defined?),
          pull_policy: pull_policy_value
        }
      else
        {}
      end
    end
  end
end
```

The config above is a simple demonstration of the translation layer, into a
stable configuration, depending on what simplification strategy has been used
by a user. There more complex examples, though:

```ruby
module Gitlab::Ci::Config::Entry
  class Need < ::Gitlab::Config::Entry::Simplifiable
    strategy :JobString, if: -> (config) { config.is_a?(String) }

    strategy :JobHash,
      if: -> (config) { config.is_a?(Hash) && same_pipeline_need?(config) }

    strategy :CrossPipelineDependency,
      if: -> (config) { config.is_a?(Hash) && cross_pipeline_need?(config) }

     # [ ... ]
  end
end
```

Every time we load config, an Abstract Syntax Tree is being built, because
nodes / entries know what the child nodes can be:

```ruby
# Simplified root entry code
#
module Gitlab::Ci::Config::Entry
  class Root < ::Gitlab::Config::Entry::Node
    include ::Gitlab::Config::Entry::Configurable

    entry :default, Entry::Default,
      description: 'Default configuration for all jobs.'

    entry :include, Entry::Includes,
      description: 'List of external YAML files to include.'

    entry :before_script, Entry::Commands,
      description: 'Script that will be executed before each job.'

    entry :image, Entry::Image,
      description: 'Docker image that will be used to execute jobs.'

    entry :services, Entry::Services,
      description: 'Docker images that will be linked to the container.'

    entry :after_script, Entry::Commands,
      description: 'Script that will be executed after each job.'

    entry :variables, Entry::Variables,
      description: 'Environment variables that will be used.'

    # [ ... ]
  end
end
```

Loading the configuration script mentioned at the beginning of this pargraph
will result in build a following AST:

```
Entry::Root
`-
 |- Entry::Default
 |  `- Entry::Image('ruby:3.0')
 |
 |- Entry::Job('rspec')
 |  `- Entry::Script('bundle exec rspec')
 |
 |- Entry::Job('rspec 2.7')
 |  |- Entry::Image('ruby:2.7)
 |  `- Entry::Script('bundle exec rspec')
```

The AST will be validated, and eventually will generate a stable representation
of configuration that we can use to persist pipelines / stages / jobs in the
database, and start pipeline processing.
