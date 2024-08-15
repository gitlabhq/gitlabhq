import { GlButton, GlTableLite } from '@gitlab/ui';
import CrudComponent from './crud_component.vue';

export default {
  component: CrudComponent,
  title: 'vue_shared/crud',
};

const Template = (args, { argTypes }) => ({
  components: { CrudComponent, GlButton },
  props: Object.keys(argTypes),
  template: `
    <crud-component v-bind="$props" ref="crudComponent">
      <template v-if="customActions" #actions>
        <code>#actions</code> slot
      </template>

      <template v-if="descriptionEnabled" #description>
        <code>#description</code> slot
      </template>

      <template v-if="isEmpty" #empty>
        This component has no content yet.
      </template>

      <code>#default</code> slot

      <template #form>
        <p>Add form</p>
        <div class="gl-flex gl-gap-3">
          <gl-button variant="confirm">Add item</gl-button>
          <gl-button @click="$refs.crudComponent.hideForm">Cancel</gl-button>
        </div>
      </template>

      <template v-if="footer" #footer>
        <code>#footer</code> slot
      </template>

      <template v-if="pagination" #pagination>
        <code>#pagination</code> slot
      </template>
    </crud-component>
  `,
});

const defaultArgs = {
  descriptionEnabled: false,
  customActions: false,
};

export const Default = Template.bind({});
Default.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  isEmpty: false,
};

export const WithDescription = Template.bind({});
WithDescription.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  description: 'Description text',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  descriptionEnabled: true,
  isEmpty: false,
};

export const WithFooter = Template.bind({});
WithFooter.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  description: 'Description text',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  footer: true,
  isEmpty: false,
};

export const WithPagnation = Template.bind({});
WithPagnation.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  description: 'Description text',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  pagination: true,
  isEmpty: false,
};

export const WithCustomActions = Template.bind({});
WithCustomActions.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  customActions: true,
  isEmpty: false,
};

export const withEmpty = Template.bind({});
withEmpty.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  icon: 'rocket',
  count: 0,
  toggleText: 'Add action',
  isEmpty: true,
};

export const isLoading = Template.bind({});
isLoading.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  isLoading: true,
  isEmpty: false,
};

export const isCollapsible = Template.bind({});
isCollapsible.args = {
  ...defaultArgs,
  title: 'CRUD Component title',
  icon: 'rocket',
  count: 99,
  toggleText: 'Add action',
  isCollapsible: true,
  isEmpty: false,
};

const TableTemplate = (args, { argTypes }) => ({
  components: { CrudComponent, GlButton, GlTableLite },
  props: Object.keys(argTypes),
  template: `
    <crud-component v-bind="$props" ref="crudComponent">
    <gl-table-lite
      :items="tableItems"
      :fields="tableFields" />

      <template #form>
        <p>Add form</p>
        <div class="gl-flex gl-gap-3">
          <gl-button variant="confirm">Add item</gl-button>
          <gl-button @click="$refs.crudComponent.hideForm">Cancel</gl-button>
        </div>
      </template>
    </crud-component>
  `,
});

const ContentListTemplate = (args, { argTypes }) => ({
  components: { CrudComponent, GlButton },
  props: Object.keys(argTypes),
  template: `
    <crud-component v-bind="$props" ref="crudComponent">
      <ul class="content-list">
        <li v-for="item in items">{{ item.label }}</li>
      </ul>

      <template #form>
        <p>Add form</p>
        <div class="gl-flex gl-gap-3">
          <gl-button variant="confirm">Add item</gl-button>
          <gl-button @click="$refs.crudComponent.hideForm">Cancel</gl-button>
        </div>
      </template>
    </crud-component>
  `,
});

export const TableExample = TableTemplate.bind({});
TableExample.args = {
  title: 'Hooks',
  icon: 'hook',
  count: 3,
  toggleText: 'Add new hook',
  tableItems: [
    {
      column_one: 'test',
      column_two: 1234,
    },
    {
      column_one: 'test2',
      column_two: 5678,
    },
    {
      column_one: 'test3',
      column_two: 9101,
    },
  ],
  tableFields: [
    {
      key: 'column_one',
      label: 'First column',
      thClass: 'w-60p',
      tdClass: 'table-col',
    },
    {
      key: 'column_two',
      label: 'Second column',
      thClass: 'w-60p',
      tdClass: 'table-col',
    },
  ],
};

export const ContentListExample = ContentListTemplate.bind({});
ContentListExample.args = {
  title: 'Branches',
  icon: 'branch',
  count: 4,
  toggleText: 'Add new branch',
  items: [
    {
      label: 'First item',
    },
    {
      label: 'Second item',
    },
    {
      label: 'Third item',
    },
    {
      label: 'Fourth item',
    },
  ],
};
