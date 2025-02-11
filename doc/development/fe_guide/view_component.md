---
stage: Foundations
group: Design System
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: ViewComponent
---

ViewComponent is a framework for creating reusable, testable & encapsulated view
components with Ruby on Rails, without the need for a JavaScript framework like Vue.
They are rendered server-side and can be seamlessly used with template languages like [Haml](haml.md).

For more information, see the [official documentation](https://viewcomponent.org/) or
[this introduction video](https://youtu.be/akRhUbvtnmo).

## Browse components with Lookbook

We have a [Lookbook](https://github.com/allmarkedup/lookbook) in `http://gdk.test:3000/rails/lookbook` (only available in development mode) to browse and interact with ViewComponent previews.

## Pajamas components

Some of the components of our [Pajamas](https://design.gitlab.com) design system are
available as a ViewComponent in `app/components/pajamas`.

NOTE:
We are still in the process of creating these components, so not every Pajamas component is available as ViewComponent.
Reach out to the [Design Systems team](https://handbook.gitlab.com/handbook/engineering/development/dev/foundations/design-system/)
if the component you are looking for is not yet available.

### Available components

Consider this list a best effort. The full list can be found in [`app/components/pajamas`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/components/pajamas). Also see our Lookbook (`http://gdk.test:3000/rails/lookbook`) for a more interactive way to browse our components.

#### Alert

The `Pajamas::AlertComponent` follows the [Pajamas Alert](https://design.gitlab.com/components/alert/) specification.

**Examples:**

By default this creates a dismissible info alert with icon:

```haml
= render Pajamas::AlertComponent.new(title: "Almost done!")
```

You can set variant, hide the icons and more:

```haml
= render Pajamas::AlertComponent.new(title: "All done!",
  variant: :success,
  dismissible: :false,
  show_icon: false)
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/alert_component.rb).

#### Banner

The `Pajamas::BannerComponent` follows the [Pajamas Banner](https://design.gitlab.com/components/banner/) specification.

**Examples:**

In its simplest form the banner component looks like this:

```haml
= render Pajamas::BannerComponent.new(button_text: 'Learn more', button_link: example_path,
  svg_path: 'illustrations/example.svg') do |c|
  - c.with_title { 'Hello world!' }
  %p Content of your banner goes here...
```

If you have a need for more control, you can also use the `illustration` slot
instead of `svg_path` and the `primary_action` slot instead of `button_text` and `button_link`:

```haml
= render Pajamas::BannerComponent.new do |c|
  - c.with_illustration do
    = custom_icon('my_inline_svg')
  - c.with_title do
    Hello world!
  - c.with_primary_action do
    = render 'my_button_in_a_partial'
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/banner_component.rb).

#### Button

The `Pajamas::ButtonComponent` follows the [Pajamas Button](https://design.gitlab.com/components/button/) specification.

**Examples:**

The button component has a lot of options but all of them have good defaults,
so the simplest button looks like this:

```haml
= render Pajamas::ButtonComponent.new do |c|
  = _('Button text goes here')
```

The following example shows most of the available options:

```haml
= render Pajamas::ButtonComponent.new(category: :secondary,
  variant: :danger,
  size: :small,
  type: :submit,
  disabled: true,
  loading: false,
  block: true) do |c|
  Button text goes here
```

You can also create button-like looking `<a>` tags, like this:

```haml
= render Pajamas::ButtonComponent.new(href: root_path) do |c|
  Go home
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/button_component.rb).

#### Card

The `Pajamas::CardComponent` follows the [Pajamas Card](https://design.gitlab.com/components/card/) specification.

**Examples:**

The card has one mandatory `body` slot and optional `header` and `footer` slots:

```haml
= render Pajamas::CardComponent.new do |c|
  - c.with_header do
    I'm the header.
  - c.with_body do
    %p Multiple line
    %p body content.
  - c.with_footer do
    Footer goes here.
```

If you want to add custom attributes to any of these or the card itself, use the following options:

```haml
= render Pajamas::CardComponent.new(card_options: {id: "my-id"}, body_options: {data: { count: 1 }})
```

`header_options` and `footer_options` are available, too.

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/card_component.rb).

#### Checkbox tag

The `Pajamas::CheckboxTagComponent` follows the [Pajamas Checkbox](https://design.gitlab.com/components/checkbox/) specification.

The `name` argument and `label` slot are required.

For example:

```haml
= render Pajamas::CheckboxTagComponent.new(name: 'project[initialize_with_sast]',
  checkbox_options: { data: { testid: 'initialize-with-sast-checkbox', track_label: track_label, track_action: 'activate_form_input', track_property: 'init_with_sast' } }) do |c|
  - c.with_label do
    = s_('ProjectsNew|Enable Static Application Security Testing (SAST)')
  - c.with_help_text do
    = s_('ProjectsNew|Analyze your source code for known security vulnerabilities.')
    = link_to _('Learn more.'), help_page_path('user/application_security/sast/_index'), target: '_blank', rel: 'noopener noreferrer', data: { track_action: 'followed' }
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/checkbox_tag_component.rb).

#### Checkbox

The `Pajamas::CheckboxComponent` follows the [Pajamas Checkbox](https://design.gitlab.com/components/checkbox/) specification.

NOTE:
`Pajamas::CheckboxComponent` is used internally by the [GitLab UI form builder](haml.md#use-the-gitlab-ui-form-builder) and requires an instance of [ActionView::Helpers::FormBuilder](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html) to be passed as the `form` argument.
It is preferred to use the [`gitlab_ui_checkbox_component`](haml.md#gitlab_ui_checkbox_component) method to render this ViewComponent.
To use a checkbox without an instance of [ActionView::Helpers::FormBuilder](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html) use [CheckboxTagComponent](#checkbox-tag).

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/checkbox_component.rb).

#### Toggle

The `Pajamas::ToggleComponent` follows the [Pajamas Toggle](https://design.gitlab.com/components/toggle/) specification.

```haml
= render Pajamas::ToggleComponent.new(classes: 'js-force-push-toggle',
  label: s_("ProtectedBranch|Toggle allowed to force push"),
  is_checked: protected_branch.allow_force_push,
  label_position: :hidden) do
  Leverage this block to render a rich help text. To render a plain text help text, prefer the `help` parameter.
```

NOTE:
**The toggle ViewComponent is special as it depends on the Vue.js component.**
To actually initialize this component, make sure to call the `initToggle` helper from `~/toggles`.

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/toggle_component.rb).

## Layouts

Layout components can be used to create common layout patterns used in GitLab.

### Available components

#### Page heading

A standard page header with a page title and optional actions.

**Example:**

```haml
= render ::Layouts::PageHeadingComponent.new(_('Page title')) do |c|
  - c.with_actions do
    = buttons
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/layouts/page_heading_component.rb).

#### CRUD component

A list container being used to host a table or list with user actions such as create, read, update, delete.

**Example:**

```haml
= render ::Layouts::CrudComponent.new(_('CRUD title'), icon: 'ICONNAME', count: COUNT) do |c|
  - c.with_description do
    = description
  - c.with_actions do
    = buttons
  - c.with_form do
    = add item form
  - c.with_body do
    = body
  - c.with_pagination do
    = pagination component
  - c.with_footer do
    = optional footer
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/layouts/crud_component.rb).

#### Horizontal section

Many of the settings pages use a layout where the title and description are on the left and the settings fields are on the right. The `Layouts::HorizontalSectionComponent` can be used to create this layout.

**Example:**

```haml
= render ::Layouts::HorizontalSectionComponent.new(options: { class: 'gl-mb-6' }) do |c|
  - c.with_title { _('Naming, visibility') }
  - c.with_description do
    = _('Update your group name, description, avatar, and visibility.')
    = link_to _('Learn more about groups.'), help_page_path('user/group/index')
  - c.with_body do
    .form-group.gl-form-group
      = f.label :name, _('New group name')
      = f.text_field :name
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/layouts/horizontal_section_component.rb).

#### Settings block

A settings block (accordion) to group related settings.

**Example:**

```haml
= render ::Layouts::SettingsBlock.new(_('Settings block heading')) do |c|
  - c.with_description do
    = description
  - c.with_body do
    = body
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/layouts/settings_block_component.rb).

#### Settings section

Similar to SettingsBlock (see above) this component is used to group related settings together. Unlike SettingsBlock it doesn't provide accordion functionality. Uses a sticky header.

**Example:**

```haml
= render ::Layouts::SettingsSection.new(_('Settings section heading')) do |c|
  - c.with_description do
    = description
  - c.with_body do
    = body
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/layouts/settings_section_component.rb).

## Best practices

- If you are about to create a new view in Haml, use the available components
  over creating plain Haml tags with CSS classes.
- If you are making changes to an existing Haml view and see, for example, a
  button that is still implemented with plain Haml, consider migrating it to use a ViewComponent.
- If you decide to create a new component, consider creating [previews](https://viewcomponent.org/guide/previews.html) for it, too.
  This will help others to discover your component with Lookbook, also it makes it much easier to test its different states.

### Preview layouts

If you need to have a custom layout for your ViewComponent preview consider using these paths for the layout code:

- `app/views/layouts/lookbook` — for your layout HAML file
- `app/assets/javascripts/entrypoints/lookbook` — for your custom JavaScript code
- `app/assets/stylesheets/lookbook` — for your custom SASS code

Please note that JavaScript and SASS code has to be manually included in the layout.
