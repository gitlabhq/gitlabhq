import { GlAlert, GlButton, GlLink } from '@gitlab/ui';
import IndexLayout from './index_layout.vue';

const Template = (args, { argTypes }) => ({
  components: { IndexLayout },
  props: Object.keys(argTypes),
  template: `
    <index-layout v-bind="$props">
      <p>Index layout default slot.</p>
    </index-layout>
  `,
});

export const Default = Template.bind({});
Default.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const WithSlots = (args, { argTypes }) => ({
  components: { IndexLayout, GlButton, GlLink },
  props: Object.keys(argTypes),
  template: `
    <index-layout v-bind="$props">
      <template #heading>
        Custom <i>Heading</i> with Markup
      </template>
      <template #description>
        Custom <i>description</i> information with Markup.
        <gl-link>Learn more.</gl-link>
      </template>
      <template #actions>
        <gl-button variant="confirm">Primary action</gl-button>
        <gl-button>Secondary action</gl-button>
      </template>
      <p>Index layout default slot.</p>
    </index-layout>
  `,
});
WithSlots.args = {};

export const WithAlerts = (args, { argTypes }) => ({
  components: { IndexLayout, GlAlert },
  props: Object.keys(argTypes),
  template: `
    <index-layout v-bind="$props">
      <template #alerts>
        <gl-alert variant="danger" title="Example danger alert title">
          Example alert content
        </gl-alert>
        <gl-alert variant="warning" title="Example warning alert title">
          Example alert content
        </gl-alert>
        <gl-alert variant="info" title="Example info alert title">
          Example alert content
        </gl-alert>
      </template>
      <p>Index layout default slot.</p>
    </index-layout>
  `,
});
WithAlerts.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const Loading = Template.bind({});
Loading.args = {
  heading: 'Page Title',
  description: 'This is a page description',
  loading: true,
};

export const PageHeadingSrOnly = Template.bind({});
PageHeadingSrOnly.args = {
  heading: 'Page Title present for screen readers but not visible to sighted users',
  pageHeadingSrOnly: true,
};

export default {
  component: IndexLayout,
  title: 'vue_shared/layouts/index_layout',
  argTypes: {
    heading: {
      control: 'text',
    },
    description: {
      control: 'text',
    },
    loading: {
      control: 'boolean',
    },
    pageHeadingSrOnly: {
      control: 'boolean',
      description: 'Visually hide with gl-sr-only class',
    },
  },
};
