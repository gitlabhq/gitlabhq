---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform authentication
---

GitLab Duo Agent Platform uses a multi-token authentication chain before requests reach a model provider.

The following table lists the token types and time-to-live (TTL) for each token.

| Token  | Issuer | TTL    | Refresh behavior                                        |
|--------|--------|--------|---------------------------------------------------------|
| Cloud Connector JWT (self-signed) | GitLab Dedicated instance | One hour  | In each request. |
| CustomersDot service access token | `customers.gitlab.com`    | Approximately three days | In an hourly cron when fewer than 2 days remain. |
| OAuth access token                | GitLab Dedicated instance | Two hours  | In each workflow.                                 |
| GitLab Duo Workflow Service Internal JWT           | GitLab Duo Workflow Service | 1 hour | In each workflow with the `GenerateToken` RPC. |
| GLGO exchange JWT                 | AI Gateway                | 1 hour                              |  In each request. |
