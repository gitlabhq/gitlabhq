---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: REST API spam protection and CAPTCHA support
---

If the model can be modified via the REST API, you must also add support to all of the
relevant API endpoints which may modify spammable or spam-related attributes. This
definitely includes the `POST` and `PUT` mutations, but may also include others, such as those
related to changing a model's confidential/public flag.

## Add support to the REST endpoints

The main steps are:

1. Add `helpers SpammableActions::CaptchaCheck::RestApiActionsSupport` in your `resource`.
1. Pass `perform_spam_check: true` to the Update Service class constructor.
   It is set to `true` by default in the Create Service.
1. After you create or update the `Spammable` model instance, call `#check_spam_action_response!`,
   save the created or updated instance in a variable.
1. Identify the error handling logic for the `failure` case of the request,
   when create or update was not successful. These indicate possible spam detection,
   which adds an error to the `Spammable` instance.
   The error is usually similar to `render_api_error!` or `render_validation_error!`.
1. Wrap the existing error handling logic in a
   `with_captcha_check_rest_api(spammable: my_spammable_instance)` call, passing the `Spammable`
   model instance you saved in a variable as the `spammable:` named argument. This call will:
   1. Perform the necessary spam checks on the model.
   1. If spam is detected:
      - Raise a Grape `#error!` exception with a descriptive spam-specific error message.
      - Include the relevant information added as error fields to the response.
        For more details on these fields, refer to the section in the REST API documentation on
        [Resolve requests detected as spam](../../api/rest/troubleshooting.md#requests-detected-as-spam).

   NOTE:
   If you use the standard ApolloLink or Axios interceptor CAPTCHA support described
   above, you can ignore the field details, because they are handled
   automatically. They become relevant if you attempt to use the GraphQL API directly to
   process a failed check for potential spam, and resubmit the request with a solved
   CAPTCHA response.

Here is an example for the `post` and `put` actions on the `snippets` resource:

```ruby
module API
  class Snippets < ::API::Base
    #...
    resource :snippets do
      # This helper provides `#with_captcha_check_rest_api`
      helpers SpammableActions::CaptchaCheck::RestApiActionsSupport

      post do
        #...
        service_response = ::Snippets::CreateService.new(project: nil, current_user: current_user, params: attrs).execute
        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet, current_user: current_user
        else
          # Wrap the normal error response in a `with_captcha_check_rest_api(spammable: snippet)` block
          with_captcha_check_rest_api(spammable: snippet) do
            # If possible spam was detected, an exception would have been thrown by
            # `#with_captcha_check_rest_api` for Grape to handle via `error!`
            render_api_error!({ error: service_response.message }, service_response.http_status)
          end
        end
      end

      put ':id' do
        #...
        service_response = ::Snippets::UpdateService.new(project: nil, current_user: current_user, params: attrs, perform_spam_check: true).execute(snippet)

        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet, current_user: current_user
        else
          # Wrap the normal error response in a `with_captcha_check_rest_api(spammable: snippet)` block
          with_captcha_check_rest_api(spammable: snippet) do
            # If possible spam was detected, an exception would have been thrown by
            # `#with_captcha_check_rest_api` for Grape to handle via `error!`
            render_api_error!({ error: service_response.message }, service_response.http_status)
          end
        end
      end
```
