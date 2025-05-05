import SettingsSubSection from './settings_sub_section.vue';

export default {
  component: SettingsSubSection,
  title: 'vue_shared/settings/settings_sub_section',
};

const Template = (args, { argTypes }) => ({
  components: { SettingsSubSection },
  props: Object.keys(argTypes),
  template: `
  <settings-sub-section v-bind="$props" heading="Settings sub section heading">
    <template #description>Settings section description</template>
    <template #default>
      <p>Settings sub section content</p>
    </template>
  </settings-sub-section>
  `,
});

export const Default = Template.bind({});
