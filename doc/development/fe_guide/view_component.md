---
stage: Ecosystem
group: Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# ViewComponent

ViewComponent is a framework for creating reusable, testable & encapsulated view
components with Ruby on Rails, without the need for a JavaScript framework like Vue.
They are rendered server-side and can be seamlessly used with template languages like [Haml](haml.md).

Refer to the official [documentation](https://viewcomponent.org/) to learn more or
watch this [introduction video](https://youtu.be/akRhUbvtnmo).

## Browse components with Lookbook

We have a [Lookbook](https://github.com/allmarkedup/lookbook) in [http://gdk.test:3000/rails/lookbook](http://gdk.test:3000/rails/lookbook) (only available in development mode) to browse and interact with ViewComponent previews.

## Pajamas components

Some of the components of our [Pajamas](https://design.gitlab.com) design system are
available as a ViewComponent in `app/components/pajamas`.

NOTE:
We are still in the process of creating these components, so not every Pajamas component is available as ViewComponent.
Reach out to the [Foundations team](https://about.gitlab.com/handbook/engineering/development/dev/ecosystem/foundations/)
if the component you are looking for is not yet available.

### Available components

Consider this list a best effort. The full list can be found in [`app/components/pajamas`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/components/pajamas). Also see [our Lookbook](http://gdk.test:3000/rails/lookbook) for a more interactive way to browse our components.

#### Alert

The `Pajamas::AlertComponent` follows the [Pajamas Alert](https://design.gitlab.com/components/alert) specification.

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

The `Pajamas::BannerComponent` follows the [Pajamas Banner](https://design.gitlab.com/components/banner) specification.

**Examples:**

In its simplest form the banner component looks like this:

```haml
= render Pajamas::BannerComponent.new(button_text: 'Learn more', button_link: example_path,
  svg_path: 'illustrations/example.svg') do |c|
  - c.title { 'Hello world!' }
  %p Content of your banner goes here...
```

If you have a need for more control, you can also use the `illustration` slot
instead of `svg_path` and the `primary_action` slot instead of `button_text` and `button_link`:

```haml
= render Pajamas::BannerComponent.new do |c|
  - c.illustration do
    = custom_icon('my_inline_svg')
  - c.title do
    Hello world!
  - c.primary_action do
    = render 'my_button_in_a_partial'
```

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/banner_component.rb).

#### Button

The `Pajamas::ButtonComponent` follows the [Pajamas Button](https://design.gitlab.com/components/button) specification.

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

The `Pajamas::CardComponent` follows the [Pajamas Card](https://design.gitlab.com/components/card) specification.

**Examples:**

The card has one mandatory `body` slot and optional `header` and `footer` slots:

```haml
= render Pajamas::CardComponent.new do |c|
  - c.header do
    I'm the header.
  - c.body do
    %p Multiple line
    %p body content.
  - c.footer do
    Footer goes here.
```

If you want to add custom attributes to any of these or the card itself, use the following options:

```haml
= render Pajamas::CardComponent.new(card_options: {id: "my-id"}, body_options: {data: { count: 1 }})
```

`header_options` and `footer_options` are available, too.

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/card_component.rb).

#### Toggle

The `Pajamas::ToggleComponent` follows the [Pajamas Toggle](https://design.gitlab.com/components/toggle) specification.

```haml
= render Pajamas::ToggleComponent.new(classes: 'js-force-push-toggle',
  label: s_("ProtectedBranch|Toggle allowed to force push"),
  is_checked: protected_branch.allow_force_push,
  label_position: :hidden)
  Leverage this block to render a rich help text. To render a plain text help text, prefer the `help` parameter.
```

NOTE:
**The toggle ViewComponent is special as it depends on the Vue.js component.**
To actually initialize this component, make sure to call the `initToggle` helper from `~/toggles`.

For the full list of options, see its
[source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/components/pajamas/toggle_component.rb).

### Best practices

- If you are about to create a new view in Haml, use the available components
  over creating plain Haml tags with CSS classes.
- If you are making changes to an existing Haml view and see, for example, a
  button that is still implemented with plain Haml, consider migrating it to use a ViewComponent.
- If you decide to create a new component, consider creating [previews](https://viewcomponent.org/guide/previews.html) for it, too.
  This will help others to discover your component with Lookbook, also it makes it much easier to test its different states.
