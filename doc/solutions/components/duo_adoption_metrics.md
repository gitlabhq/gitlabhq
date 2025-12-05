---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: Measure and visualize GitLab Duo adoption and usage with a CI-based data collection pipeline, GraphQL API client, and Duo Analytics dashboard.
title: GitLab Duo Adoption Metrics & Analytics
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## GitLab Duo Adoption Metrics & Analytics

This project provides end-to-end GitLab Duo usage analytics, combining:

- **Duo GraphQL Data Collection** – A generic Python orchestrator that calls the Duo collector scripts backed by a GitLab GraphQL API client.
- **Duo Usage Metrics Pipeline** – CI jobs that periodically collect and aggregate Duo usage data for your GitLab groups.
- **Duo Analytics Dashboard** – A GitLab Pages–hosted dashboard showing Duo adoption, usage intensity, and engagement trends.

## Getting Started

You can control which analytics pipelines run by setting these **Project CI/CD Variables**:

| Variable | Duo Setup | Description |
|----------|-----------|-------------|
| `ENABLE_DUO_METRICS` | `"true"` | Enable/disable Duo AI metrics pipeline. |
| `ENABLE_PROJECT_METRICS` | `"false"` | Disable traditional project-centric metrics when you only care about Duo adoption. |
| `DUO_TOKEN` | `TOKEN VALUE` | Personal Access Token with `read_api` and `ai_features` permissions for Duo usage collection. |
| `GROUP_PATH` | `example_group` | Top-level group or subgroup path to collect Duo metrics for. |

**Steps for Quick Start**

1. Fork this repository.
1. Go to **Project Settings → CI/CD → Variables**.
1. Add the variables above with values appropriate for your environment.
1. Configure a **scheduled pipeline** at your preferred interval. Duo usage collection can be heavy, so running **once per day** is recommended.
1. Run the scheduled pipeline manually, or wait for its schedule.
1. After the pipeline completes, open the **Pages** application under **Deploy → Pages** to access the Duo Analytics dashboard.

## GitLab Pages Deployment (Duo Metrics)

When Duo metrics are enabled, Pages deployment happens automatically after the Duo pipeline completes:

- **Duo Metrics Pipeline** → Deploys to a URL like `https://your-username.gitlab.io/project-name/duo-metrics/`.
- **Main Landing Page** → Available at `https://your-username.gitlab.io/project-name/`, with links to available dashboards.

The landing page auto-detects which dashboards are present and shows Duo-related links when `ENABLE_DUO_METRICS="true"`.

## Local Development & Testing

For local testing of Duo analytics (without CI):

1. Ensure you have Python and dependencies installed (for example via `poetry install` at the repo root).
1. Set required environment variables in a local `.env` or shell session:
   - `DUO_TOKEN`
   - `GROUP_PATH`
1. Run the generic orchestrator script to collect raw Duo usage data:

```shell
python ai_raw_data_collection.py
```

1. Open the generated metrics under the local `public/` or `docs/` folder (depending on your setup), or run the dashboard locally as described in the solution component project documentation.

## Duo Dashboard Features

The Duo Analytics Dashboard focuses on GitLab Duo adoption and AI usage patterns, including:

- **License & Adoption Analytics** – Track how many users have Duo access and how many actively use it.
- **Code Suggestions Analytics** – Monitor acceptance rates, volume of suggestions, and language distribution for AI-assisted coding.
- **Duo Chat Analytics** – View chat interactions, user cohorts, and conversation volumes.
- **User Engagement Analytics** – Segment users by usage level (inactive, experimenting, regular, heavy).
- **Language & Workflow Performance** – Analyze Duo effectiveness (e.g., acceptance rate, suggestion usage) by programming language or workflow.

These metrics are derived entirely from Duo-related signals; traditional project metrics are not required to use this dashboard.

## Duo Usage Data Collection Pipeline

Duo adoption metrics are created by a CI-driven data collection pipeline that relies on:

- A **generic Python orchestrator**: `ai_raw_data_collection.py`
- A reusable **GitLab GraphQL API client**: `gitlab_graphql_api`

### Orchestrator: `ai_raw_data_collection.py`

The script `ai_raw_data_collection.py` is responsible for:

- Reading environment/CI variables (such as `GROUP_PATH`, `DUO_TOKEN`, and pipeline configuration).
- Invoking one or more **collector scripts** that implement concrete Duo usage queries.
- Coordinating:
  - Pagination across groups and projects.
  - Date/time windows or sampling strategies for Duo usage events.
  - Normalization of results into a consistent, analytics-friendly format (e.g., CSV/JSON).
- Writing the collected data to locations that the Duo dashboard and downstream aggregation steps consume.

It acts as a **generic entry point** for collecting raw Duo usage data, so you can:

- Add new Duo-related collectors without changing CI configuration.
- Control which collectors run via environment variables or CI jobs.

### GitLab GraphQL API Client & Collections

All Duo-related GraphQL logic is encapsulated in the `gitlab_graphql_api` Python package, particularly under:

- `gitlab_graphql_api > collections`

Key ideas:

- **GraphQL client abstraction** – A central client handles authentication, pagination, and error handling against the GitLab GraphQL endpoint.
- **Collection classes** – The `collections` module provides higher-level abstractions (such as “project collections” or “user collections”) that expose methods for retrieving structured data. Duo collectors use these to:
  - Fetch groups and projects for a given `GROUP_PATH`.
  - Query Duo usage fields and AI-related activity.
- **Versioned API usage** – The same collections API can be extended as GitLab improves or expands Duo-related GraphQL fields without changing the orchestrator.

The Duo collectors import these collection classes and define the specific queries they need (for example, fetching counts of AI code suggestions, chat usage events, or user-level adoption statistics).

> **Note:** The GraphQL schema and field names for Duo usage are documented alongside the collection classes in `gitlab_graphql_api > collections`. Use those docs when extending or customizing the data collected for Duo metrics.

## Configuring Duo Data Collection

While the pipeline can be customized, a typical Duo-only setup requires:

- **Minimal CI configuration**:
  - Enable the Duo pipeline by setting `ENABLE_DUO_METRICS="true"`.
  - Optionally disable any non-Duo pipelines by setting `ENABLE_PROJECT_METRICS="false"`.
- **Environment variables** used by `ai_raw_data_collection.py`:

| Variable | Description | Example |
|----------|-------------|---------|
| `DUO_TOKEN` | Token with `read_api` + `ai_features`, used for Duo GraphQL queries. | `glpat-xxxx` |
| `GROUP_PATH` | Group or subgroup whose Duo usage should be measured. | `"gitlab-org/your-group"` |
| `DUO_METRICS_OUTPUT_DIR` | Optional output directory for raw Duo usage data. | `"duo-metrics/raw"` |

With these set, the CI job that runs `ai_raw_data_collection.py` will:

1. Use `gitlab_graphql_api` collections to query Duo usage data for the specified group.
1. Write raw Duo usage artifacts that can be:
   - Aggregated into reports.
   - Loaded directly by the Duo dashboard.

## Extending Duo Metrics

To add or refine Duo adoption metrics:

1. **Identify** the GitLab GraphQL fields relevant to the new Duo signal (for example, additional usage counters or new AI features).
1. **Update or add** a collector script that:
   - Uses the `gitlab_graphql_api > collections` abstractions.
   - Writes data in a format consistent with existing Duo collectors.
1. **Wire the collector** into `ai_raw_data_collection.py` (or control it via environment variables).
1. **Update the dashboard** to consume and visualize the new fields, if needed.

Because the GraphQL access and pagination logic are encapsulated inside `gitlab_graphql_api`, extending Duo metrics typically means:

- Minimal changes in the orchestrator.
- Focus on modeling the new metric and updating the dashboard.

## Resources

- [GitLab Duo Adoption Metrics solution component project](https://gitlab.com/gitlab-com/product-accelerator/work-streams/packaging/gitlab-graphql-api)
- `gitlab_graphql_api` package and `collections` module (for Duo GraphQL usage patterns)
