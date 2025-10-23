import CiCatalogBadge from './ci_catalog_badge.vue';

export default {
  component: CiCatalogBadge,
  title: 'vue_shared/projects_list/ci-catalog-badge',
  argTypes: {
    isPublished: {
      control: 'boolean',
      description: 'Whether the CI/CD catalog project is published',
    },
    exploreCatalogPath: {
      control: 'text',
      description: 'Path to explore the CI/CD catalog',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { CiCatalogBadge },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-p-10 gl-flex gl-items-center gl-justify-center">
      <ci-catalog-badge v-bind="$props" />
    </div>
  `,
});

export const Published = Template.bind({});
Published.args = {
  isPublished: true,
  exploreCatalogPath: '/explore/catalog',
};

export const Unpublished = Template.bind({});
Unpublished.args = {
  isPublished: false,
  exploreCatalogPath: '',
};
