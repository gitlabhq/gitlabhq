import { shallowMount } from '@vue/test-utils';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import createStore from '~/releases/stores';
import createDetailModule from '~/releases/stores/modules/detail';

describe('releases/components/tag_field_new', () => {
  let store;
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TagFieldNew, {
      store,
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        detail: createDetailModule({}),
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a placeholder component', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });
});
