import SettingsBlock from './settings_block.vue';

export default {
  component: SettingsBlock,
  title: 'vue_shared/settings/settings_block',
};

const Template = (args, { argTypes }) => ({
  components: { SettingsBlock },
  props: Object.keys(argTypes),
  template: `
  <settings-block v-bind="$props" title="Settings section title">
    <template #description>Settings section description</template>
    <template #default>
      <p>Content</p>
      <p>More content</p>
      <p>Content</p>
      <p>More content...</p>
      <p>Content</p>
    </template>
  </settings-block>
  `,
});

export const Default = Template.bind({});
