---
stage: Foundations
group: Design System
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Page layouts and panels
---

Pages are divided into three panels:

- The **static panel** is the primary context of the page. All standard
  application pages use it automatically.
- The **dynamic panel** (optional) is for displaying detailed information in
  the context of the static panel.
  Individual features mount Vue applications into it to display contextual content.
- The **AI panel** (collapsible) is for intelligent features.

See the [Design System documentation](https://design.gitlab.com/product-foundations/layout/#panel-based-layout)
for more information about page structure.

Within the static panel, the index and detail layout components provide consistent
spacing and structure for the page heading, alerts, and content areas.

## Panels

### Static panel

The `Layouts::StaticPanelComponent` ViewComponent wraps the main content area.
All standard application pages use it automatically.
You don't need to adopt it explicitly when building a new page.

### Dynamic panel

The `DynamicPanel` Vue component defines the structure of dynamic panel, including its header, actions and content areas.
Use it as the direct child of `MountingPortal`, with the `mount-to="#contextual-panel-portal"` and `append` props.

**Props:**

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `String` | `null` | Header text. The `header` slot takes precedence when provided. |
| `maximizeUrl` | `String` | `null` | When set, a maximize button is rendered that links to this URL. |

**Slots:**

| Slot | Description |
| --- | --- |
| Default | Main panel body content. |
| `header` | Custom header markup. Takes precedence over the `header` prop. |
| `actions` | Panel header actions. For more information, see [Panel actions](#panel-actions). |

**Events:**

| Event | Payload | Description |
| --- | --- | --- |
| `close` | None | Emitted when the close button is clicked. |
| `maximize` | `MouseEvent` | Emitted when the maximize button is clicked. |

**Example:**

```vue
<script>
import DynamicPanel from '~/vue_shared/components/dynamic_panel.vue';

export default {
  components: { DynamicPanel },
  methods: {
    onClose() {
      // handle close
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#contextual-panel-portal" append>
    <dynamic-panel header="Example" @close="onClose">
      <!-- Content goes here -->
    </dynamic-panel>
  </mounting-portal>
</template>
```

With a custom header, maximize button, and actions:

```vue
<template>
  <mounting-portal mount-to="#contextual-panel-portal" append>
    <dynamic-panel :maximize-url="fullUrlToEntity" @close="onClose" @maximize="onMaximize">
      <template #header>
        <span class="panel-header-inner-text">{{ entityName }}</span>
      </template>

      <template #actions>
        <gl-button
          v-gl-tooltip.bottom="__('Example action')"
          category="tertiary"
          icon="remove"
          size="small"
          :aria-label="__('Example action')"
          @click="onAction"
        />
      </template>

      <!-- Content goes here -->
    </dynamic-panel>
  </mounting-portal>
</template>
```

### Panel actions

Panel actions are icon buttons rendered in the panel header, to the left of the
built-in close and maximize buttons.

Three approaches are available depending on your context:

**1. Dynamic panel `actions` slot**

Use this when your component is a direct consumer of `DynamicPanel`:

```vue
<template>
  <dynamic-panel header="Details" @close="onClose">
    <template #actions>
      <gl-button
        v-gl-tooltip.bottom="$options.i18n.editLabel"
        category="tertiary"
        icon="pencil"
        size="small"
        :aria-label="$options.i18n.editLabel"
        @click="onEdit"
      />
    </template>
    <detail-view />
  </dynamic-panel>
</template>
```

**2. Static panel `static_panel_actions` content region (HAML)**

Use this from the HAML view file when rendering actions in the static panel:

```haml
- content_for :static_panel_actions do
  = link_button_to _("Example action"), path_to_action, category: :tertiary, size: :small
```

If the actions are not simple links, consider using `PanelActionsPortal` instead.

**3. `PanelActionsPortal` Vue component**

Use `PanelActionsPortal` when one or more of the following are true:

- The actions to render in the static panel are not simple links, and require
  client side behavior, for example, buttons or dropdowns.
- The actions are defined deep in the component tree, making it impractical to
  pass them to the `actions` slot of `DynamicPanel`.
- The application renders in both the static and dynamic panels, for example, work items.

```vue
<script>
import PanelActionsPortal from '~/vue_shared/components/panel_actions_portal.vue';

export default {
  components: { PanelActionsPortal },
};
</script>

<template>
  <panel-actions-portal>
    <gl-button category="tertiary" size="small" @click="onAction">
      {{ __('Example action') }}
    </gl-button>
  </panel-actions-portal>
</template>
```

Import path: `~/vue_shared/components/panel_actions_portal.vue`.

#### Panel actions guidance

Follow these rules when adding buttons to a panel actions area:

- Use only buttons (or links that look like buttons), for example:
  - `GlButton` (Vue)
  - `GlDisclosureDropdown` (Vue)
  - `Pajamas::ButtonComponent` (HAML/Ruby)
  - `link_button_to` (HAML/Ruby)
- Buttons should have `category="tertiary"` and `size="small"`.
- Icon only buttons must:
  - have a tooltip which appears below the button (`v-gl-tooltip.bottom="..."`)
  - set `aria-label` set to the same string as the tooltip.
- If you have four or more actions, group the less commonly used ones in a
  "More actions" icon-only dropdown using the `ellipsis_h` icon, with
  `no-caret`, `category="tertiary"`, and `size="small"` options as well.
- Ensure the page's entry template sets `@force_show_panel_header = true`.
  For example, see
  [`app/views/groups/observability/show.html.haml#L2`](https://gitlab.com/gitlab-org/gitlab/-/blob/2670fe39ed60b180f05f0846707265e2fc91ea52/app/views/groups/observability/show.html.haml#L2).
  This ensures the static panel's header is always rendered, no matter the
  value of the `page_breadcrumbs_in_top_bar` feature flag.

**Example with a "More actions" dropdown:**

```vue
<template>
  <dynamic-panel header="Details" @close="onClose">
    <template #actions>
      <gl-button
        v-gl-tooltip.bottom="__('Edit')"
        category="tertiary"
        icon="pencil"
        size="small"
        :aria-label="__('Edit')"
        @click="onEdit"
      />
      <gl-disclosure-dropdown
        v-gl-tooltip.bottom="__('More actions')"
        icon="ellipsis_h"
        category="tertiary"
        size="small"
        no-caret
        :toggle-aria-label="__('More actions')"
        :items="moreActions"
      />
    </template>
    <detail-view />
  </dynamic-panel>
</template>
```

## Layouts

Layout components provide consistent spacing and structure within the content area of a panel.
Both ViewComponent and Vue component equivalents are available.

### Index layout

Use the index layout for pages that list entities.
It provides consistent structure for the page heading, alerts, and main content area.

**Parameters:**

See [Index layout](view_component.md#index-layout).

**Slots:**

See [Index layout](view_component.md#index-layout).

#### HAML (`Layouts::IndexLayout`)

**Example:**

```ruby
= render ::Layouts::IndexLayout.new(heading: _('Tokens'), description: _('Manage your tokens.')) do |c|
  - c.with_alerts do
    = render Pajamas::AlertComponent.new(variant: :danger, title: _('Failed to create token.'))
  = render 'tokens_table'
```

For more information, see [Index layout](view_component.md#index-layout).

#### Vue (`IndexLayout`)

**Props:**

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `heading` | `String` | `null` | Page title text. |
| `headingTag` | `String` | `null` | Heading element tag: `'h1'` or `'h2'`. Defaults to the tag provided by context. |
| `description` | `String` | `null` | Page description text. |
| `loading` | `Boolean` | `false` | When `true`, renders a loading icon in place of the content. |
| `pageHeadingSrOnly` | `Boolean` | `false` | When `true`, visually hides the page heading. |

**Slots:**

| Slot | Description |
| --- | --- |
| `before` | Content rendered before the page heading. |
| `heading-wrapper` | Replaces the heading element entirely. |
| `heading` | Custom heading markup. |
| `description` | Custom description markup. |
| `alerts` | Page alerts. Rendered only when the slot is provided. |
| `loading` | Custom loading state. Falls back to `GlLoadingIcon` when not provided. |
| Default | Main page content. |

**Example:**

```vue
<script>
import IndexLayout from '~/vue_shared/components/index_layout.vue';

export default {
  components: { IndexLayout },
};
</script>

<template>
  <index-layout :heading="$options.i18n.heading" :description="$options.i18n.description">
    <template v-if="hasAlerts" #alerts>
      <gl-alert v-if="error" variant="danger" @dismiss="onDismissError">
        {{ errorMessage }}
      </gl-alert>
    </template>

    <tokens-table :tokens="tokens" />
  </index-layout>
</template>
```

### Detail layout

Use the detail layout for detail or show pages.
It extends the index layout with a `sidebar` slot.

#### HAML (`Layouts::DetailLayout`)

**Parameters:**

See [Detail layout](view_component.md#detail-layout).

**Slots:**

Same as [Detail layout](view_component.md#detail-layout), plus:

| Slot | Description |
| --- | --- |
| `sidebar` | Sidebar content. |

**Example:**

```ruby
= render ::Layouts::DetailLayout.new(heading: _('Page title'), description: _('Page description')) do |c|
  - c.with_alerts do
    = render Pajamas::AlertComponent.new(title: 'Alert message')
  - c.with_sidebar do
    = render 'sidebar'

  = render 'items_table'
```

For more information, see [Detail layout](view_component.md#detail-layout).

#### Vue (`DetailLayout`)

**Props:**

Same as `IndexLayout` (see [Index layout](#vue-indexlayout)).

**Slots:**

Same as `IndexLayout`, plus:

| Slot | Description |
| --- | --- |
| `sidebar` | Sidebar content. |

**Example:**

```vue
<script>
import DetailLayout from '~/vue_shared/components/detail_layout.vue';

export default {
  components: { DetailLayout },
};
</script>

<template>
  <detail-layout :heading="token.name">
    <template #sidebar>
      <token-metadata :token="token" />
    </template>

    <token-body :token="token" />
  </detail-layout>
</template>
```
