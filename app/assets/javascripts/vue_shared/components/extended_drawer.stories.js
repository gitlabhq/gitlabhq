import { GlBadge, GlButton } from '@gitlab/ui';
import ExtendedDrawer from './extended_drawer.vue';

const defaultArgs = {
  open: true,
  title: 'Sessions',
  expanded: false,
};

const Template = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
    };
  },
  watch: {
    // The templates bind :open="isOpen" after v-bind="$props", so isOpen has
    // to follow the arg for the storybook `open` control to stay functional.
    open(value) {
      this.isOpen = value;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
  template: `
    <div>
      <gl-button @click="toggle">Toggle drawer</gl-button>
      <extended-drawer v-bind="$props" :open="isOpen" @close="isOpen = false">
        <p>Primary content area. This is the drawer feed.</p>
      </extended-drawer>
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = { ...defaultArgs };

export const Expanded = Template.bind({});
Expanded.args = { ...defaultArgs, expanded: true, open: true };

export const ExpandedWithSecondary = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton, GlBadge },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
    };
  },
  watch: {
    open(value) {
      this.isOpen = value;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
  template: `
    <div>
      <gl-button @click="toggle">Toggle drawer</gl-button>
      <extended-drawer v-bind="$props" :open="isOpen" @close="isOpen = false">
        <p>Primary content area. Becomes the left column while the secondary slot renders.</p>
        <template #secondary>
          <section>
            <h3>Secondary content area</h3>
            <gl-badge variant="info">Renders only while expanded</gl-badge>
            <p>Receives a layout in product usage.</p>
          </section>
        </template>
      </extended-drawer>
    </div>
  `,
});
ExpandedWithSecondary.args = { ...defaultArgs, expanded: true };

// The bulletproof case: the consumer provides the secondary slot (because its
// content appears conditionally, e.g. after a selection) but nothing populates
// it yet, so the primary content keeps the full width. Conditionally provided
// slots are not reactive, which is why visibility is a prop, not slot sniffing.
export const ExpandedSecondaryNotVisible = ExpandedWithSecondary.bind({});
ExpandedSecondaryNotVisible.args = { ...defaultArgs, expanded: true, secondaryVisible: false };

// The component's headline interaction: the secondary area appears after a
// selection in the primary content. Whether the new region is announced or
// receives focus is a consumer decision; the component only renders it.
export const SecondaryAppearsOnSelection = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
      hasSelection: false,
    };
  },
  watch: {
    open(value) {
      this.isOpen = value;
    },
  },
  template: `
    <div>
      <extended-drawer v-bind="$props" :open="isOpen" :secondary-visible="hasSelection" @close="isOpen = false">
        <p>Primary content area.</p>
        <gl-button @click="hasSelection = !hasSelection">
          {{ hasSelection ? 'Clear selection' : 'Select an item' }}
        </gl-button>
        <template #secondary>
          <p>Detail for the selected item.</p>
        </template>
      </extended-drawer>
    </div>
  `,
});
SecondaryAppearsOnSelection.args = { ...defaultArgs, expanded: true };

// The second scroll model: long primary content with no secondary area. The
// drawer body itself scrolls (there is no inner scroll region), unlike the
// split case where each column scrolls independently.
export const ExpandedWithLongPrimaryOnly = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
    };
  },
  watch: {
    open(value) {
      this.isOpen = value;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
  template: `
    <div>
      <gl-button @click="toggle">Toggle drawer</gl-button>
      <extended-drawer v-bind="$props" :open="isOpen" @close="isOpen = false">
        <p v-for="i in 60" :key="'p' + i">Feed row {{ i }}</p>
      </extended-drawer>
    </div>
  `,
});
ExpandedWithLongPrimaryOnly.args = { ...defaultArgs, expanded: true };

// Pinned to a phone viewport: below md the split stacks into one column
// with a bottom divider and the drawer body scrolls as one.
export const ExpandedWithSecondaryNarrow = ExpandedWithSecondary.bind({});
ExpandedWithSecondaryNarrow.args = { ...defaultArgs, expanded: true };
ExpandedWithSecondaryNarrow.parameters = {
  viewport: { defaultViewport: 'breakpointSmall' },
};

// Long content in both areas: each scrolls independently while expanded
// (the drawer header stays pinned).
export const ExpandedWithScrollingContent = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
    };
  },
  watch: {
    open(value) {
      this.isOpen = value;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
  template: `
    <div>
      <gl-button @click="toggle">Toggle drawer</gl-button>
      <extended-drawer v-bind="$props" :open="isOpen" @close="isOpen = false">
        <p v-for="i in 60" :key="'p' + i">Feed row {{ i }}</p>
        <template #secondary>
          <p v-for="i in 60" :key="'s' + i">Detail row {{ i }}</p>
        </template>
      </extended-drawer>
    </div>
  `,
});
ExpandedWithScrollingContent.args = { ...defaultArgs, expanded: true };

export const WithHeaderAndFooter = (args, { argTypes }) => ({
  components: { ExtendedDrawer, GlButton },
  props: Object.keys(argTypes),
  data() {
    return {
      isOpen: this.open,
    };
  },
  watch: {
    open(value) {
      this.isOpen = value;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
  template: `
    <div>
      <gl-button @click="toggle">Toggle drawer</gl-button>
      <extended-drawer v-bind="$props" :open="isOpen" @close="isOpen = false">
        <template #header>
          <p class="gl-mb-0">Header slot content below the title row.</p>
        </template>
        <p>Primary content area.</p>
        <template #footer>
          <gl-button variant="confirm">Footer action</gl-button>
        </template>
      </extended-drawer>
    </div>
  `,
});
WithHeaderAndFooter.args = { ...defaultArgs };

export default {
  component: ExtendedDrawer,
  title: 'vue_shared/extended_drawer',
  argTypes: {
    open: {
      control: 'boolean',
      description:
        'Seeds and updates the open state of the drawer. A self-close reports through `close` and `update:open`, so `.sync` bindings stay aligned.',
    },
    title: {
      control: 'text',
      description: 'Accessible title of the drawer, rendered as the header heading.',
    },
    expanded: {
      control: 'boolean',
      description:
        'Full width state. The component manages its own expanded state, seeded and updated by this prop, and reports transitions through the `expand` and `collapse` events.',
    },
    headerHeight: {
      control: 'text',
      description: "Height of the fixed chrome above the drawer, e.g. '48px'.",
    },
    headerSticky: {
      control: 'boolean',
      description: 'Keeps the drawer header visible while scrolling.',
    },
    zIndex: {
      control: 'number',
      description: 'Stacking order of the drawer.',
    },
    secondaryVisible: {
      control: 'boolean',
      description:
        'Whether the provided secondary slot is currently shown. Consumers with conditional secondary content always provide the slot and drive this prop.',
    },
    primaryLabel: {
      control: 'text',
      description: 'Accessible name of the primary scroll region while the split shows.',
    },
    secondaryLabel: {
      control: 'text',
      description: 'Accessible name of the secondary scroll region.',
    },
  },
};
