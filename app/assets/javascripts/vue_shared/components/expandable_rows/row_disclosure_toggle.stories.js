import RowDisclosureToggle from './row_disclosure_toggle.vue';
import { flattenTree, rowDomId } from './utils';

export default {
  component: RowDisclosureToggle,
  title: 'vue_shared/expandable_rows/row_disclosure_toggle',
};

// The toggle is controlled, so the story keeps its own state to respond to clicks.
const Template = (args, { argTypes }) => ({
  components: { RowDisclosureToggle },
  props: Object.keys(argTypes),
  data() {
    return { isExpanded: this.expanded };
  },
  watch: {
    expanded(value) {
      this.isExpanded = value;
    },
  },
  template: `
    <row-disclosure-toggle v-bind="$props" :expanded="isExpanded" @toggle="isExpanded = !isExpanded">
      {{ label }}
    </row-disclosure-toggle>
  `,
});

export const Default = Template.bind({});
Default.args = {
  label: 'Platform',
  expandable: true,
  expanded: false,
  depth: 0,
  loading: false,
};

// A row that cannot expand holds the toggle's space, so its content lines up.
export const NotExpandable = Template.bind({});
NotExpandable.args = { ...Default.args, expandable: false };

export const Loading = Template.bind({});
Loading.args = { ...Default.args, expanded: true, loading: true };

const TREE = [
  {
    id: 'platform',
    name: 'Platform',
    users: 21,
    children: [
      { id: 'api', name: 'api', users: 18 },
      { id: 'web-app', name: 'web-app', users: 9 },
    ],
  },
  { id: 'mobile', name: 'Mobile', users: 7, children: [{ id: 'ios', name: 'ios', users: 7 }] },
  { id: 'tools', name: 'Tools', users: 2 },
];

// The toggle in the first cell of a plain table, with `flattenTree` deciding which rows show.
export const InATable = () => ({
  components: { RowDisclosureToggle },
  data() {
    return { expandedKeys: ['platform'] };
  },
  computed: {
    rows() {
      return flattenTree(TREE, {
        keyOf: (node) => node.id,
        expandedKeys: new Set(this.expandedKeys),
      });
    },
    namesByKey() {
      return Object.fromEntries(this.rows.map(({ key, node }) => [key, node.name]));
    },
  },
  methods: {
    rowDomId,
    toggle(row) {
      this.expandedKeys = row.expanded
        ? this.expandedKeys.filter((key) => key !== row.key)
        : [...this.expandedKeys, row.key];
    },
  },
  template: `
    <table class="gl-w-full">
      <thead>
        <tr><th class="gl-p-3">Name</th><th class="gl-p-3">Users</th></tr>
      </thead>
      <tbody>
        <tr v-for="row in rows" :id="row.depth ? rowDomId('story', row.key) : null" :key="row.key">
          <td class="gl-p-3">
            <row-disclosure-toggle
              :label="row.node.name"
              :expandable="row.expandable"
              :expanded="row.expanded"
              :depth="row.depth"
              :parent-label="namesByKey[row.parentKey]"
              :child-row-ids="row.childKeys.map((key) => rowDomId('story', key))"
              @toggle="toggle(row)"
            >{{ row.node.name }}</row-disclosure-toggle>
          </td>
          <td class="gl-p-3">{{ row.node.users }}</td>
        </tr>
      </tbody>
    </table>
  `,
});
