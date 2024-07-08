---
owning-stage: "~devops::data stores"
description: 'Cells ADR 010: HTTP Router uses static rules and HTTP-based caching mechanism'
---

<!-- vale gitlab.FutureTense = NO -->
# HTTP Router rules and caching behavior

## Context

HTTP Router is integral part of the Cells 1.0 architecture. The definition of rules and usage
of cache was a confusing part of the design. This change clarifies the behavior.

## Decision

- HTTP Router does use only static rules that are part of project, or an router deployment.
- The rules are described in a JSON.
- The rules might define to be `passthrough` (use fixed address or from the config),
  or `classify` (use Topology Service).
- The `classify` requests do use HTTP headers to control cache behavior instead of `json` response.
- The usage of HTTP headers is compatible with caching behavior expected by the
  [Cloudflare Workers - Cache](https://developers.cloudflare.com/workers/runtime-apis/cache/).

## Consequences

- The HTTP Router design is simplified as we don't need to resolve now how to merge routing rules from many
  distinct Cells, possibly running different versions, and all complexities involved by this [note](https://gitlab.com/gitlab-org/gitlab/-/issues/439667#note_1952380955).
- The usage of HTTP cache control headers make it seamless to use with Cloudflare Workers.
- If the need for alternative methods for merging rules emerges or managing cache this simplification
  is compatible with any future design improvement.

## Alternatives

- No alternatives were considered since it is a simplification of the original design.
