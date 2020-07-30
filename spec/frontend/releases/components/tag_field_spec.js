import { shallowMount } from '@vue/test-utils';
import TagField from '~/releases/components/tag_field.vue';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import TagFieldExisting from '~/releases/components/tag_field_existing.vue';
import createStore from '~/releases/stores';
import createDetailModule from '~/releases/stores/modules/detail';

describe('releases/components/tag_field', () => {
  let store;
  let wrapper;

  const createComponent = ({ originalRelease }) => {
    store = createStore({
      modules: {
        detail: createDetailModule({}),
      },
    });

    store.state.detail.originalRelease = originalRelease;

    wrapper = shallowMount(TagField, { store });
  };

  const findTagFieldNew = () => wrapper.find(TagFieldNew);
  const findTagFieldExisting = () => wrapper.find(TagFieldExisting);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when an existing release is being edited', () => {
    beforeEach(() => {
      const originalRelease = { name: 'Version 1.0' };
      createComponent({ originalRelease });
    });

    it('renders the TagFieldExisting component', () => {
      expect(findTagFieldExisting().exists()).toBe(true);
    });

    it('does not render the TagFieldNew component', () => {
      expect(findTagFieldNew().exists()).toBe(false);
    });
  });

  describe('when a new release is being created', () => {
    beforeEach(() => {
      createComponent({ originalRelease: null });
    });

    it('renders the TagFieldNew component', () => {
      expect(findTagFieldNew().exists()).toBe(true);
    });

    it('does not render the TagFieldExisting component', () => {
      expect(findTagFieldExisting().exists()).toBe(false);
    });
  });
});
