---
status: proposed
creation-date: "2023-05-22"
authors: [ "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
---

# Hexagonal Rails Monolith

## Summary

**TL;DR:** Change the Rails monolith from a [big ball of mud](https://en.wikipedia.org/wiki/Big_ball_of_mud) state to
a [modular monolith](https://www.thereformedprogrammer.net/my-experience-of-using-modular-monolith-and-ddd-architectures)
that uses an [Hexagonal architecture](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)) (or ports and adapters architecture).
Extract cohesive functional domains into separate directory structure using Domain-Driven Design practices.
Extract infrastructure code (logging, database tools, instrumentation, etc.) into gems, essentially remove the need for `lib/` directory.
Define what parts of the functional domains (for example application services) are of public use for integration (the ports)
and what parts are instead private encapsulated details.
Define Web, Sidekiq, REST, GraphQL, and Action Cable as the adapters in the external layer of the architecture.
Use [Packwerk](https://github.com/Shopify/packwerk) to enforce privacy and dependency between modules of the monolith.

![Hexagonal Architecture for GitLab monolith](hexagonal_architecture.png)

## Details

### Application domain

The application core (functional domains) is divided into separate top-level bounded contexts called after the
[feature category](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml) they represent.
A bounded-context is represented in the form of a Ruby module.
This follows the existing [guideline on naming namespaces](../../../../development/software_design.md#use-namespaces-to-define-bounded-contexts) but puts more structure to it.

Modules should:

- Be deep enough to encapsulate a lot of the internal logic, state and data.
- Have a public interface that is as small as possible, safe to use by other bounded contexts and well documented.
- Be cohesive and represent the SSoT (single source of truth) of the feature it describes.

Feature categories represent a product area that is large enough for the module to be deep, so we don't have a proliferation
of small top-level modules. It also helps the codebase to follow the
[ubiquitous language](../../../../development/software_design.md#use-ubiquitous-language-instead-of-crud-terminology).
A team can be responsible for multiple feature categories, hence owning the vision for multiple bounded contexts.
While feature categories can sometimes change ownership, this change of mapping the bounded context to new owners
is very cheap.
Using feature categories also helps new contributors, either as GitLab team members of members of the wider community,
to navigate the codebase.

If multiple feature categories are strongly related, they may be grouped under a single bounded context.
If a feature category is only relevant in the context of a parent feature category, it may be included in the
parent's bounded context. For example: Build artifacts existing in the context of Continuous Integration feature category
and they may be merged under a single bounded context.

### Application adapters

>>>
_Adapters are the glue between components and the outside world._
_They tailor the exchanges between the external world and the ports that represent the requirements of the inside_
_of the application component. There can be several adapters for one port, for example, data can be provided by_
_a user through a GUI or a command-line interface, by an automated data source, or by test scripts._ -
[Wikipedia](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)#Principle)
>>>

Application adapters would be:

- Web UI (Rails controllers, view, JS and Vue client)
- REST API endpoints
- GraphQL Endpoints
- Action Cable

TODO: continue describing how adapters are organized and why they are separate from the domain code.

### Platform code

For platform code we consider any classes and modules that are required by the application domain and/or application
adapters to work.

The Rails' `lib/` directory today contains multiple categories of code that could live somewhere else,
most of which is platform code:

- REST API endpoints could be part of the [application adapters](#application-adapters).
- domain code (both large domain code such as `Gitlab::Ci` and small such as `Gitlab::JiraImport`) should be
  moved inside the [application domain](#application-domain).
- The rest could be extracted as separate single-purpose gems under the `gems/` directory inside the monolith.
  This can include utilities such as logging, error reporting and metrics, rate limiters,
  infrastructure code like `Gitlab::ApplicationRateLimiter`, `Gitlab::Redis`, `Gitlab::Database`
  and generic subdomains like `Banzai`.

Base classes to extend Rails framework such as `ApplicationRecord` or `ApplicationWorker` as well as GitLab base classes
such as `BaseService` could be implemented as gem extensions.

This means that aside from the Rails framework code, the rest of the platform code resides in `gems/`.

Eventually all code inside `gems/` could potentially be extracted in a separate repository or open sourced.
Placing platform code inside `gems/` makes it clear that its purpose is to serve the application code.

### Why Packwerk?

TODO:

- boundaries not enforced at runtime. Ruby code will still work as being all loaded in the same memory space.
- can be introduced incrementally. Not everything requires to be moved to packs for the Rails autoloader to work.

Companies like Gusto have been developing and maintaining a list of [development and engineering tools](https://github.com/rubyatscale)
for organizations that want to move to using a Rails modular monolith around Packwerk.

### EE and JH extensions

TODO:

## Challenges

- Such changes require a shift in the development mindset to understand the benefits of the modular
  architecture and not fallback into legacy practices.
- Changing the application architecture is a challenging task. It takes time, resources and commitment
  but most importantly it requires buy-in from engineers.
- This may require us to have a medium-long term team of engineers or a Working Group that makes progresses
  on the architecture evolution plan, foster discussions in various engineering channels and resolve adoption challenges.
- We need to ensure we build standards and guidelines and not silos.
- We need to ensure we have clear guidelines on where new code should be placed. We must not recreate junk drawer folders like `lib/`.

## Opportunities

The move to a modular monolith architecture enables a lot of opportunities that we could explore in the future:

- We could align the concept of domain expert with explicitly owning specific modules of the monolith.
- The use of static analysis tool (such as Packwerk, Rubocop) can catch design violations in development and CI, ensuring
  that best practices are honored.
- By defining dependencies between modules explicitly we could speed up CI by testing only the parts that are affected by
  the changes.
- Such modular architecture could help to further decompose modules into separate services if needed.
