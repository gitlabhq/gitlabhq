import DataTable from './data_table.vue';
import UserLink from './user_link.vue';

export default {
  component: UserLink,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/user_link',
};

const firstChild = {
  user: {
    name: 'Ayanami Rei',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    username: 'ramiel',
    webUrl: 'https://gitlab.com/fakeuser',
  },
};

const nodes = [
  firstChild,
  {
    user: {
      name: 'Shikinami-Langley Asuka',
      avatarUrl:
        'https://www.gravatar.com/avatar/c4ab964b90c3049c47882b319d3c5cc0?s=80\u0026d=identicon',
      username: 'sachiel',
      webUrl: 'https://gitlab.com/fakeuser',
    },
  },
  {
    user: {
      name: 'Makinami Mari',
      avatarUrl:
        'https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon',
      username: 'leliel',
      webUrl: 'https://gitlab.com/fakeuser',
    },
  },
];

const Template = (args, { argTypes }) => ({
  components: { UserLink },
  props: Object.keys(argTypes),
  template: `<user-link v-bind="$props" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable, UserLink },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { ...firstChild.user };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes,
  },
  options: {
    fields: [
      { key: 'user.name', label: 'Name' },
      { key: 'user', label: 'User', component: 'UserLink' },
    ],
  },
};
