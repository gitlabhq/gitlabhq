---
stage: Data Science
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Model and services spam protection and CAPTCHA support

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
1. [Add a call to SpamActionService to the execute method of services](#add-a-call-to-spamactionservice-to-the-execute-method-of-services).

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
`Spammable` model in the [Spam Log section](../../integration/akismet.md) of the Admin Area page.

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

## Add a call to SpamActionService to the execute method of services

This approach applies to any service which can persist spammable attributes:

1. In the relevant Create or Update service under `app/services`, pass in a populated
   `Spam::SpamParams` instance. (Refer to instructions later on in this page.)
1. Use it and the `Spammable` model instance to execute a `Spam::SpamActionService` instance.
1. If the spam check fails:
   - An error is added to the model, which causes it to be invalid and prevents it from being saved.
   - The `needs_recaptcha` property is set to `true`.

   These changes to the model enable it for handling by the subsequent backend and frontend CAPTCHA logic.

Make these changes to each relevant service:

1. Change the constructor to take a `spam_params:` argument as a required named argument.

   Using named arguments for the constructor helps you identify all the calls to
   the constructor that need changing. It's less risky because the interpreter raises
   type errors unless the caller is changed to pass the `spam_params` argument.
   If you use an IDE (such as RubyMine) which supports this, your
   IDE flags it as an error in the editor.

1. In the constructor, set the `@spam_params` instance variable from the `spam_params` constructor
   argument. Add an `attr_reader: :spam_params` in the `private` section of the class.

1. In the `execute` method, add a call to execute the `Spam::SpamActionService`.
   (You can also use `before_create` or `before_update`, if the service
   uses that pattern.) This method uses named arguments, so its usage is clear if
   you refer to existing examples. However, two important considerations exist:
   1. The `SpamActionService` must be executed _after_ all necessary changes are made to
      the unsaved (and dirty) `Spammable` model instance. This ordering ensures
      spammable attributes exist to be spam-checked.
   1. The `SpamActionService` must be executed _before_ the model is checked for errors and
      attempting a `save`. If potential spam is detected in the model's changed attributes, we must prevent a save.

```ruby
module Widget
  class CreateService < ::Widget::BaseService
    # NOTE: We require the spam_params and do not default it to nil, because
    # spam_checking is likely to be necessary.  However, if there is not a request available in scope
    # in the caller (for example, a note created via email) and the required arguments to the
    # SpamParams constructor are not otherwise available, spam_params: must be explicitly passed as nil.
    def initialize(project:, current_user: nil, params: {}, spam_params:)
      super(project: project, current_user: current_user, params: params)

      @spam_params = spam_params
    end

    def execute
      widget = Widget::BuildService.new(project, current_user, params).execute

      # More code that may manipulate dirty model before it is spam checked.

      # NOTE: do this AFTER the spammable model is instantiated, but BEFORE
      # it is validated or saved.
      Spam::SpamActionService.new(
        spammable: widget,
        spam_params: spam_params,
        user: current_user,
        # Or `action: :update` for a UpdateService or service for an existing model.
        action: :create
      ).execute

      # Possibly more code related to saving model, but should not change any attributes.

      widget.save
    end

    private

    attr_reader :spam_params
```
