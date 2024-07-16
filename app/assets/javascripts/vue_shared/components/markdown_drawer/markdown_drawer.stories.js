import { GlButton } from '@gitlab/ui';
import { MOCK_HTML } from '../../../../../../spec/frontend/vue_shared/components/markdown_drawer/mock_data';
import MarkdownDrawer from './markdown_drawer.vue';

export default {
  component: MarkdownDrawer,
  title: 'vue_shared/markdown_drawer',
  parameters: {
    mirage: {
      timing: 1000,
      handlers: {
        get: {
          '/help/user/search/global_search/advanced_search_syntax.json': [
            200,
            {},
            { html: MOCK_HTML },
          ],
        },
      },
    },
  },
};

const createStory =
  ({ ...options }) =>
  (_, { argTypes }) => ({
    components: { MarkdownDrawer, GlButton },
    props: Object.keys(argTypes),
    data() {
      return {
        render: false,
      };
    },
    methods: {
      toggleDrawer() {
        this.$refs.drawer.toggleDrawer();
      },
    },
    mounted() {
      window.requestAnimationFrame(() => {
        this.render = true;
      });
    },
    template: `
       <div v-if="render">
        <gl-button @click="toggleDrawer">Open Drawer</gl-button>
        <markdown-drawer
          :documentPath="'user/search/global_search/advanced_search_syntax.json'"
          ref="drawer"
        />
        </div>
      `,
    ...options,
  });

export const Default = createStory({});
