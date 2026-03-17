import { GlAlert, GlLink } from '@gitlab/ui';
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
  components: { IndexLayout, GlLink },
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

export default {
  component: IndexLayout,
  title: 'vue_shared/index_layout',
};
