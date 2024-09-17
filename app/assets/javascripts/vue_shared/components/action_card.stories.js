import ActionCard, { VARIANTS } from './action_card.vue';

export default {
  component: ActionCard,
  title: 'vue_shared/action_card',
  argTypes: {
    variant: {
      control: 'select',
      options: Object.values(VARIANTS),
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ActionCard },
  props: Object.keys(argTypes),
  template: `
    <action-card v-bind="$props"></action-card>
  `,
});

export const Default = Template.bind({});
Default.args = {
  title: 'Create a project',
  description:
    'Projects are where you store your code, access issues, wiki, and other features of GitLab.',
  icon: 'project',
  variant: VARIANTS.default,
  href: 'gitlab.com',
};
