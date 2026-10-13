import Actions from './actions.vue';

export default {
  component: Actions,
  title: 'glql/components/common/actions',
  argTypes: {
    showCopyContents: {
      control: 'boolean',
      description:
        'Adds a "Copy contents" item to the dropdown. Read when the dropdown opens, not when the prop changes.',
    },

    // events
    viewSource: { action: 'view-source' },
    copySource: { action: 'copy-source' },
    copyAsGfm: { action: 'copy-as-gfm' },
    reload: { action: 'reload' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { Actions },
  props: Object.keys(argTypes),
  template: `<div style="height:200px"><actions
    :show-copy-contents="showCopyContents"
    v-on="{
      'view-source': viewSource,
      'copy-source': copySource,
      'copy-as-gfm': copyAsGfm,
      reload,
    }"
  /></div>`,
});

export const Default = Template.bind({});
Default.args = {
  showCopyContents: true,
};

export const WithoutCopyContents = Template.bind({});
WithoutCopyContents.args = {
  showCopyContents: false,
};
