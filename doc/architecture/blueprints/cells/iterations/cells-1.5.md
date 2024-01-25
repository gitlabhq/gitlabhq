---
stage: core platform
group: Tenant Scale
description: 'Cell: 1.5'
---

# Cells 1.5

This document describes a technical proposal for a Cells 1.5 that builds on top of [Cells 1.0](cells-1.0.md).

The Cells 1.5 target is to deliver a migration solution for existing enterprise customers using the SaaS GitLab.com offering.

## Preamble

Cells 1.5 is meant to target existing enterprise customers:

1. They are existing customers of the GitLab.com Primary Cell and want to use the Organization model.
1. They want their Organization to be isolated from the rest of GitLab.com.
1. They are fine with limiting their users from accessing other Organizations (including public projects on other Organizations).
1. Their groups and projects that are meant to be private.

From a development and infrastructure perspective we want to achieve the following goals:

1. Customers that migrated to the Organization model are isolated from each other.
1. We can migrate Organizations from the Primary Cell to another Cell without user intervention or changing any user workflows.
1. The routing solution can dynamically route customers to the correct Cell once they are migrated.

Long-term we want to achieve the following goals:

1. The proposed architecture must not prevent us from implementing the ability for users to interact with many Organizations.
1. Cells can be re-balanced by moving Organizations between Cells.
