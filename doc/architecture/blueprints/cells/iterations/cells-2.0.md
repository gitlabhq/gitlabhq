---
stage: core platform
group: Tenant Scale
description: 'Cells: 2.0'
---

# Cells 2.0

This document describes a technical proposal for a Cells 2.0 that builds on top of [Cells 1.0](cells-1.0.md).

The Cells 2.0 target is to support a public and open source contribution model in a cellular architecture.

## Preamble

Cells 2.0 is meant to target public and open source Organizations on GitLab.com:

1. Existing users can create public Organizations that are isolated from the rest of GitLab.com.
1. A single user can be part of many Organizations that are on different Cells.
1. Users can contribute to public projects across Cells.

From a development and infrastructure perspective we want to achieve the following goals:

1. We can migrate public Organizations between Cells without user intervention or a user changing any of their workflows.
1. The routing solution allows seamless interaction with many Organizations at the same time.
