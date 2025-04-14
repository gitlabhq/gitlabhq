---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SBoM dependency graph ingestion overview
---

## Overview

The process starts *after* all `SBoM::Occurence` models have been ingested because we ingest them in slices and it would be tricky to process that in slices as well.

All work happens in a background worker which will be added in a subsequent MR so that we do not increase the time it takes to ingest an SBoM report. This means that there will be a delay between when the SBoM report is ingested and before the dependency graph is updated.

All record pertaining to dependency graphs are stored in `sbom_graph_paths` database table and has foreign keys to `sbom_occurrences` as well as `projects` for easier filtering.

## Details

1. The database table is designed as a [closure table](https://www.slideshare.net/slideshow/models-for-hierarchical-data/4179181)
1. When a dependency is transitive then the corresponding `Sbom::Occurrence#ancestors` will contain entries.
1. When a dependency is a direct dependency then the corresponding `Sbom::Occurrence#ancestors` will contain an `{}`.
1. Dependencies can be both direct and transitive.
1. There can be more than one version of a given dependency in a project (for example Node allows that).
1. There can be more than one `Sbom::Occurrence` for a given dependency version, for example in monorepos. These `Sbom::Occurrence` rows should have a different `input_file_path` and `source_id` (however we will not use `source_id` when building the dependency tree to avoid SQL JOIN).
