import { GlFormInput } from '@gitlab/ui';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import TagFieldExisting from '~/releases/components/tag_field_existing.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';

const TEST_TAG_NAME = 'test-tag-name';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('releases/components/tag_field_existing', () => {
  let store;
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TagFieldExisting, {
      store,
      localVue,
    });
  };

  const findInput = () => wrapper.find(GlFormInput);
  const findHelp = () => wrapper.find('[data-testid="tag-name-help"]');

  beforeEach(() => {
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          tagName: TEST_TAG_NAME,
        }),
      },
    });

    store.state.editNew.release = {
      tagName: TEST_TAG_NAME,
    };
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    it('shows the tag name', () => {
      createComponent();

      expect(findInput().attributes()).toMatchObject({
        disabled: '',
        value: TEST_TAG_NAME,
      });
    });

    it('shows help', () => {
      createComponent(mount);

      expect(findHelp().text()).toMatchInterpolatedText(
        "The tag name can't be changed for an existing release.",
      );
    });
  });
});
