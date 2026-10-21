import { compileVue2Template } from './compile_vue2_template';

// Stands in for an import-free `.vue` file that declares its own directive.
export default {
  name: 'SharedLocalDirective',
  directives: {
    mark: {
      mounted(el) {
        el.dataset.marked = 'yes';
      },
    },
  },
  ...compileVue2Template('<div><span v-mark data-testid="content">content</span></div>'),
};
