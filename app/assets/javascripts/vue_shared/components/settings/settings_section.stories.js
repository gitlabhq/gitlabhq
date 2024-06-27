import SettingsSection from './settings_section.vue';

export default {
  component: SettingsSection,
  title: 'vue_shared/settings/settings_section',
};

const Template = (args, { argTypes }) => ({
  components: { SettingsSection },
  props: Object.keys(argTypes),
  template: `
  <settings-section v-bind="$props" heading="Settings section heading">
    <template #description>Settings section description</template>
    <template #default>
      <p>Settings section content</p>
    </template>
  </settings-section>
  `,
});

export const Default = Template.bind({});
