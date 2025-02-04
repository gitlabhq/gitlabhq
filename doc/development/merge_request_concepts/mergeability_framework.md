---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Developer information explaining the process to add a new mergeability check"
title: Mergeability framework
---

The initial work started with the [better defined mergeability framework](https://gitlab.com/groups/gitlab-org/-/epics/5598)

Originally, the mergeability knowledge was spread throughout the backend and frontend.
This work was to consolidate some of the mergeability criteria into the same location
in the backend. This allows the frontend to simply consume the API and display the error.

## Add a new check

When adding a new merge check, we must make a few choices:

- Is this check skippable, and part of the **Merge when checks pass** feature?
- Is this check cacheable?
  - If so, what is an appropriate cache key?
- Does this check have a setting to turn this check on or off?

After we answer these questions, we can create the new check.

The mergeability checks live under `app/services/merge_requests/mergeability/`.

1. To create a new check, we can use this as a base:

   ```ruby
   # frozen_string_literal: true
   module MergeRequests
     module Mergeability
       class CheckCiStatusService < CheckBaseService
          identifier :ci_must_pass # Identifier used to state which check failed
          description 'Checks whether CI has passed' # Description of the check returned through GraphQL

         def execute
           # If the merge check is behind a setting, we return inactive if the setting is false
           return inactive unless merge_request.only_allow_merge_if_pipeline_succeeds?

           if merge_request.mergeable_ci_state?
             success
           else
             failure
           end
         end

         def skip?
           # Here we can check for the param or return false if its not skippable
           # Skippablility of an MR is related to merge when checks pass functionality
           params[:skip_ci_check].present?
         end

         # If we return true here, we need to create the method def cache_key and provide
         # an approriate cache key that will invalidate correctly.
         def cacheable?
           false
         end
       end
     end
   end
   ```

1. Add the new check in the `def mergeable_state_checks` method.
1. Add the new check to the GraphQL enum `app/graphql/types/merge_requests/detailed_merge_status_enum.rb`.
1. Update the GraphQL documentation with `bundle exec rake gitlab:graphql:compile_docs`.
1. Update the API documentation in `doc/api/merge_requests.md`.
1. Update the frontend to support the new message: `app/assets/javascripts/vue_merge_request_widget/components/checks/message.vue`.

## Considerations

1. **Should it be skippable?** If it is part of the merge when checks pass work,
   then we should add the skippable check. Otherwise, you should return `false`.
1. **Performance**: These mergeability checks are run very frequently, and therefore
   performance is a big consideration here. It is critical to check how the new
   mergeability check performs. In general, we are expecting around 10-20 ms.
1. **Caching is an option too.** We can set the `def cacheable?` method to return `true`,
   and in that case, we need to create another method `def cache_key` to set the
   cache key for the particular check. Cache invalidation can often be tricky,
   and we must consider all the edge cases in the cache key. If we keep the timing
   around 10-20 ms, then caching is not needed.
1. **Time the checks.** We time each check through the `app/services/merge_requests/mergeability/logger.rb`
   class, which can then be viewed in Kibana.

## How the classes work together

1. The main methods that call the mergeability framework are: `def mergeable?`, and `DetailedMergeStatusService`.
1. These methods call the `RunChecksService` class which handles the iterating
   of the mergeability checks, caching and instrumentation.

## Merge when checks pass

When we want to add the check to the Merge When Checks Pass feature, we must:

1. Allow the check to be skipped in the class.
1. Add the parameter to the list in the method `skipped_mergeable_checks`.

## Future work

1. At the moment, the slow performance of the approval check is the main area of
   concern. We have attempted to make this check cacheable, but there are a lot of
   edge cases to consider in regard to when it is invalid.
