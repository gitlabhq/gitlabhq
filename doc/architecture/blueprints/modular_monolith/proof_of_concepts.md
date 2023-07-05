---
status: proposed
creation-date: "2023-07-05"
authors: [ "@grzesiek" ]
coach: [ ]
owners: [ ]
---

# Modular Monolithk: PoCs

Modularization of our monolith is a complex project. There will be many
unknowns. One thing that can help us mitigate the risks and deliver key
insights are Proof-of-Concepts that we could deliver early on, to better
understand what will need to be done.

## Inter-module communicaton PoC

First PoC that we plan to deliver is a PoC of inter-module communication. We do
recognize the need to separate modules, but still allow them to communicate
together using a well defined interface. Modules can communicate through a
facade classes (like libraries usually do), or through evening system. Both
ways are important.

The main question is: how do we want to define the interface and how to design
the communication channels.

It is one of our goals to make it possible to plug modules out, and operate
some of them as separate services. This will make it easier deploy GitLab.com
in the future and scale key domains. One possible way to achieve this goal
would be to design the inter-module communication using a protobuf as an
interface and gRPC as a communication channel. When modules are plugged-in, we
would bypass gRPC and serialization and use in-process communication primitives
(while still using protobuf as an interface). When a module gets plugged-out,
gRPC would carry messages between modules.

## Frontend sorting hat PoC

Frontend sorting-hat is a PoC for combining multiple domains to render a full
page of GitLab (with menus, and items that come from multiple separate
domains).

## Frontend assets aggregation PoC

Frontend assets aggregation is a PoC for a possible separation of micro-frontends.
