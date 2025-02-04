---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Model and services spam protection and CAPTCHA support
---

Before adding any spam or CAPTCHA support to the REST API, GraphQL API, or Web UI, you must
first add the necessary support to:

1. The backend ActiveRecord models.
1. The services layer.

All or most of the following changes are required, regardless of the type of spam or CAPTCHA request
implementation you are supporting. Some newer features which are completely based on the GraphQL API
may not have any controllers, and don't require you to add the `mark_as_spam` action to the controller.

To do this:

1. [Add `Spammable` support to the ActiveRecord model](#add-spammable-support-to-the-activerecord-model).
1. [Add support for the `mark_as_spam` action to the controller](#add-support-for-the-mark_as_spam-action-to-the-controller).
1. [Add a call to `check_for_spam` to the execute method of services](#add-a-call-to-check_for_spam-to-the-execute-method-of-services).

## Add `Spammable` support to the ActiveRecord model

1. Include the `Spammable` module in the model class:

   ```ruby
   include Spammable
   ```

1. Add: `attr_spammable` to indicate which fields can be checked for spam. Up to
   two fields per model are supported: a "`title`" and a "`description`". You can
   designate which fields to consider the "`title`" or "`description`". For example,
   this line designates the `content` field as the `description`:

   ```ruby
   attr_spammable :content, spam_description: true
   ```

1. Add a `#check_for_spam?` method implementation:

   ```ruby
   def check_for_spam?(user:)
     # Return a boolean result based on various applicable checks, which may include
     # which attributes have changed, the type of user, whether the data is publicly
     # visible, and other criteria. This may vary based on the type of model, and
     # may change over time as spam checking requirements evolve.
   end
   ```

   Refer to other existing `Spammable` models'
   implementations of this method for examples of the required logic checks.

## Add support for the `mark_as_spam` action to the controller

The `SpammableActions::AkismetMarkAsSpamAction` module adds support for a `#mark_as_spam` action
to a controller. This controller allows administrators to manage spam for the associated
`Spammable` model in the [**Spam log** section](../../integration/akismet.md) of the **Admin** area.

1. Include the `SpammableActions::AkismetMarkAsSpamAction` module in the controller.

   ```ruby
   include SpammableActions::AkismetMarkAsSpamAction
   ```

1. Add a `#spammable_path` method implementation. The spam administration page redirects
   to this page after edits. Refer to other existing controllers' implementations
   of this method for examples of the type of path logic required. In general, it should
   be the `#show` action for the `Spammable` model's controller.

   ```ruby
   def spammable_path
     widget_path(widget)
   end
   ```

NOTE:
There may be other changes needed to controllers, depending on how the feature is
implemented. See [Web UI](web_ui.md) for more details.

## Add a call to `check_for_spam` to the execute method of services

This approach applies to any service which can persist spammable attributes:

1. In the relevant Create or Update service under `app/services`, call the `check_for_spam` method on the model.
1. If the spam check fails:
   - An error is added to the model, which causes it to be invalid and prevents it from being saved.
   - The `needs_recaptcha` property is set to `true`.

   These changes to the model enable it for handling by the subsequent backend and frontend CAPTCHA logic.

Make these changes to each relevant service:

1. In the `execute` method, call the `check_for_spam` method on the model.
   (You can also use `before_create` or `before_update`, if the service
   uses that pattern.) This method uses named arguments, so its usage is clear if
   you refer to existing examples. However, two important considerations exist:
   1. The `check_for_spam` must be executed _after_ all necessary changes are made to
      the unsaved (and dirty) `Spammable` model instance. This ordering ensures
      spammable attributes exist to be spam-checked.
   1. The `check_for_spam` must be executed _before_ the model is checked for errors and
      attempting a `save`. If potential spam is detected in the model's changed attributes, we must prevent a save.

```ruby
module Widget
  class CreateService < ::Widget::BaseService
    # NOTE: We add a default value of `true` for `perform_spam_check`, because spam checking is likely to be necessary.
    def initialize(project:, current_user: nil, params: {}, perform_spam_check: true)
      super(project: project, current_user: current_user, params: params)

      @perform_spam_check = perform_spam_check
    end

    def execute
      widget = Widget::BuildService.new(project, current_user, params).execute

      # More code that may manipulate dirty model before it is spam checked.

      # NOTE: do this AFTER the spammable model is instantiated, but BEFORE
      # it is validated or saved.
      widget.check_for_spam(user: current_user, action: :create) if perform_spam_check

      # Possibly more code related to saving model, but should not change any attributes.

      widget.save
    end

    private

    attr_reader :perform_spam_check
```
