---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: Sometimes it is necessary to store large amounts of records at once, which can be inefficient when iterating collections and performing individual `save`s. With the arrival of `insert_all` in Rails 6, which operates at the row level (that is, using `Hash`es), GitLab has added a set of APIs that make it safe and simple to insert ActiveRecord objects in bulk.
title: Insert into tables in batches
---
