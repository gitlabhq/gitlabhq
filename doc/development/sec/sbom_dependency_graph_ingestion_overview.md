---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SBoM dependency graph ingestion overview
---

## Overview

The process starts after all `SBoM::Occurence` models have been ingested because we ingest them in slices and it would be tricky to process that in slices as well.

All work happens in a background worker which will be added in a subsequent MR so that we do not increase the time it takes to ingest an SBoM report. This means that there will be a delay between when the SBoM report is ingested and before the dependency graph is updated.

All record pertaining to dependency graphs are stored in `sbom_graph_paths` database table and has foreign keys to `sbom_occurrences` as well as `projects` for easier filtering.

## Implementation details

{{< alert type="note" >}}

This feature is a work in progress so this document can get out of date

{{< /alert >}}

1. [Sbom::Ingestion::IngestReportService](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/sbom/ingestion/ingest_report_service.rb#L5) is responsible for consuming the SBoM report.
1. After it's done, we fire off [Sbom::BuildDependencyGraphWorker](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/sbom/build_dependency_graph_worker.rb) which kicks off the dependency graph calculation to a background worker.
1. [Sbom::BuildDependencyGraph](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/sbom/build_dependency_graph.rb) does the actual heavy lifting for us. The class is documented so the details are omitted here.
1. We will [skip calculation](https://gitlab.com/groups/gitlab-org/-/epics/17340) of the dependency graph if the SBoM report did not change.
1. [Sbom::PathFinder](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/finders/sbom/path_finder.rb) returns all possible paths to reach target dependency. Do note that this accepts an `Sbom::Occurrence` because `(name, version)` pair is not precise enough when working with monorepos.

## Details

1. The database table is designed as a [closure table](https://www.slideshare.net/slideshow/models-for-hierarchical-data/4179181)
1. The database table structure is available [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql#L22509).
1. When a dependency is transitive then the corresponding `Sbom::Occurrence#ancestors` will contain entries.
1. When a dependency is a direct dependency then the corresponding `Sbom::Occurrence#ancestors` will contain an `{}`.
1. Dependencies can be both direct and transitive.
1. There can be more than one version of a given dependency in a project (for example Node allows that).
1. There can be more than one `Sbom::Occurrence` for a given dependency version, for example in monorepos. These `Sbom::Occurrence` rows should have a different `input_file_path` and `source_id` (however we will not use `source_id` when building the dependency tree to avoid SQL JOIN).
