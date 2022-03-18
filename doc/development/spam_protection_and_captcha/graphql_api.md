---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API spam protection and CAPTCHA support

If the model can be modified via the GraphQL API, you must also add support to all of the
relevant GraphQL mutations which may modify spammable or spam-related attributes. This
definitely includes the `Create` and `Update` mutations, but may also include others, such as those
related to changing a model's confidential/public flag.

## Add support to the GraphQL mutations

This implementation is very similar to the controller implementation. You create a `spam_params`
instance based on the request, and pass it to the relevant Service class constructor.

The three main differences from the controller implementation are:

1. Use `include Mutations::SpamProtection` instead of `...JsonFormatActionsSupport`.
1. Obtain the request from the context via `context[:request]` when creating the `SpamParams`
   instance.
1. After you create or updated the `Spammable` model instance, call `#check_spam_action_response!`
   and pass it the model instance. This call will:
    1. Perform the necessary spam checks on the model.
    1. If spam is detected:
       - Raise a `GraphQL::ExecutionError` exception.
       - Include the relevant information added as error fields to the response via the `extensions:` parameter.
       For more details on these fields, refer to the section on
       [Spam and CAPTCHA support in the GraphQL API](../../api/graphql/index.md#resolve-mutations-detected-as-spam).

       NOTE:
       If you use the standard ApolloLink or Axios interceptor CAPTCHA support described
       above, the field details are unimportant. They become important if you
       attempt to use the GraphQL API directly to process a failed check for potential spam, and
       resubmit the request with a solved CAPTCHA response.

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

        # If possible spam wasdetected, an exception would have been thrown by
        # `#check_spam_action_response!`, so the normal resolve return logic can follow below.
      end
    end
  end
end
```
