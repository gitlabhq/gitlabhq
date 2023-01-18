---
stage: Data Science
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GraphQL API spam protection and CAPTCHA support

If the model can be modified via the GraphQL API, you must also add support to all of the
relevant GraphQL mutations which may modify spammable or spam-related attributes. This
definitely includes the `Create` and `Update` mutations, but may also include others, such as those
related to changing a model's confidential/public flag.

## Add support to the GraphQL mutations

The main steps are:

1. Use `include Mutations::SpamProtection` in your mutation.
1. Create a `spam_params` instance based on the request. Obtain the request from the context
   via `context[:request]` when creating the `SpamParams` instance.
1. Pass `spam_params` to the relevant Service class constructor.
1. After you create or update the `Spammable` model instance, call `#check_spam_action_response!`
   and pass it the model instance. This call:
   1. Performs the necessary spam checks on the model.
   1. If spam is detected:
      - Raises a `GraphQL::ExecutionError` exception.
      - Includes the relevant information added as error fields to the response via the `extensions:` parameter.
        For more details on these fields, refer to the section in the GraphQL API documentation on
        [Resolve mutations detected as spam](../../api/graphql/index.md#resolve-mutations-detected-as-spam).

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
        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        service_response = ::Widgets::CreateService.new(
          project: project,
          current_user: current_user,
          params: args,
          spam_params: spam_params
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
