---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GraphQL API spam protection and CAPTCHA support
---

If the model can be modified via the GraphQL API, you must also add support to all of the
relevant GraphQL mutations which may modify spammable or spam-related attributes. This
definitely includes the `Create` and `Update` mutations, but may also include others, such as those
related to changing a model's confidential/public flag.

## Add support to the GraphQL mutations

The main steps are:

1. Use `include Mutations::SpamProtection` in your mutation.
1. Pass `perform_spam_check: true` to the Update Service class constructor.
   It is set to `true` by default in the Create Service.
1. After you create or update the `Spammable` model instance, call `#check_spam_action_response!`
   and pass it the model instance. This call:
   1. Performs the necessary spam checks on the model.
   1. If spam is detected:
      - Raises a `GraphQL::ExecutionError` exception.
      - Includes the relevant information added as error fields to the response via the `extensions:` parameter.
        For more details on these fields, refer to the section in the GraphQL API documentation on
        [Resolve mutations detected as spam](../../api/graphql/_index.md#resolve-mutations-detected-as-spam).

   NOTE:
   If you use the standard ApolloLink or Axios interceptor CAPTCHA support described
   above, you can ignore the field details, because they are handled
   automatically. They become relevant if you attempt to use the GraphQL API directly to
   process a failed check for potential spam, and resubmit the request with a solved
   CAPTCHA response.

For example:

```ruby
module Mutations
  module Widgets
    class Create < BaseMutation
      include Mutations::SpamProtection

      def resolve(args)
        service_response = ::Widgets::CreateService.new(
          project: project,
          current_user: current_user,
          params: args
        ).execute

        widget = service_response.payload[:widget]
        check_spam_action_response!(widget)

        # If possible spam was detected, an exception would have been thrown by
        # `#check_spam_action_response!`, so the normal resolve return logic can follow below.
      end
    end
  end
end
```

Refer to the [Exploratory Testing](exploratory_testing.md) section for instructions on how to test
CAPTCHA behavior in the GraphQL API.
