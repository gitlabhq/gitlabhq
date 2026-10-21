import { compileVue2Template } from './compile_vue2_template';

// Stands in for an import-free `.vue` file, which the infection scanner shares between
// both realms.
export default {
  name: 'SharedVShow',
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  ...compileVue2Template('<div><span v-show="visible" data-testid="content">content</span></div>'),
};
