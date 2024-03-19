---
stage: enablement
group: Tenant Scale
description: 'Cells: Data Pipeline Ingestion'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Data pipeline ingestion

The Cells architecture will have a significant impact on the current [data pipeline](https://internal.gitlab.com/handbook/enterprise-data/platform/pipelines/saas-gitlab-com/) which exports data from Postgres to Snowflake for the use of data analytics. This data pipeline fulfils many use cases (i.e. SAAS Service ping, Gainsight metrics and Reporting and Analytics of the SAAS Platform).

## 1. Definition

## 2. Data flow

The current data pipeline is limited by not having the possibility to get data via a CDC mechanism (which leads to data quality issues) and works by polling the Postgres database and looking for new and updated records or fully extracting data for certain tables which causes a lot of overhead.
At the moment the data pipeline runs against two instances that get created from a snapshot of both the `main` and `ci` databases.
This is done to avoid workload on the production databases.
In the Cells architecture there will be more Postgres instances because of which the current pipeline couldn't scale to pull data from all the Postgres instances. Requirements around the data pipeline moving forward are as follows:

- We need a process that allows capturing all the CDC (insert, update and delete) from all Cells, scaling automatically with N number of Cells.
- We need to have (direct or indirect) access to database instances which allows it to do data catch up in case of major failure or root cause analysis for data anomalies.
- We need monitoring in place to alert any incident that can delay the data ingestion.

## 3. Proposal

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
