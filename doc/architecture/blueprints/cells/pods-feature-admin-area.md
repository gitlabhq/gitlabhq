---
stage: enablement
group: pods
comments: false
description: 'Pods: Admin Area'
---

This document is a work-in-progress and represents a very early state of the
Pods design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Pods, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Pods: Admin Area

In our Pods architecture proposal we plan to share all admin related tables in
GitLab. This allows simpler management of all Pods in one interface and reduces
the risk of settings diverging in different Pods. This introduces challenges
with admin pages that allow you to manage data that will be spread across all
Pods.

## 1. Definition

There are consequences for admin pages that contain data that spans "the whole
instance" as the Admin pages may be served by any Pod or possibly just 1 pod.
There are already many parts of the Admin interface that will have data that
spans many pods. For example lists of all Groups, Projects, Topics, Jobs,
Analytics, Applications and more. There are also administrative monitoring
capabilities in the Admin page that will span many pods such as the "Background
Jobs" and "Background Migrations" pages.

## 2. Data flow

## 3. Proposal

We will need to decide how to handle these exceptions with a few possible
options:

1. Move all these pages out into a dedicated per-pod Admin section. Probably
   the URL will need to be routable to a single Pod like `/pods/<pod_id>/admin`,
   then we can display this data per Pod. These pages will be distinct from
   other Admin pages which control settings that are shared across all Pods. We
   will also need to consider how this impacts self-managed customers and
   whether, or not, this should be visible for single-pod instances of GitLab.
1. Build some aggregation interfaces for this data so that it can be fetched
   from all Pods and presented in a single UI. This may be beneficial to an
   administrator that needs to see and filter all data at a glance, especially
   when they don't know which Pod the data is on. The downside, however, is
   that building this kind of aggregation is very tricky when all the Pods are
   designed to be totally independent, and it does also enforce more strict
   requirements on compatibility between Pods.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
