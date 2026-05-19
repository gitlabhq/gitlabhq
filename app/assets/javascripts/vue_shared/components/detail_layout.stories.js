import { GlAlert, GlButton, GlLink } from '@gitlab/ui';
import DetailLayout from './detail_layout.vue';

const Template = (args, { argTypes }) => ({
  components: { DetailLayout },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
      <p>Detail layout default slot.</p>
    </detail-layout>
  `,
});

export const Default = Template.bind({});
Default.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const WithSlots = (args, { argTypes }) => ({
  components: { DetailLayout, GlButton, GlLink },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
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
      <template #sidebar>
        <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 1024px;">
          Detail layout sidebar slot.
        </div>
      </template>
      <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 1024px;">
        Detail layout default slot.
      </div>
    </detail-layout>
  `,
});
WithSlots.args = {};

export const WithAlerts = (args, { argTypes }) => ({
  components: { DetailLayout, GlAlert },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
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
      <p>Detail layout default slot.</p>
    </detail-layout>
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
  component: DetailLayout,
  title: 'vue_shared/layouts/detail_layout',
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
