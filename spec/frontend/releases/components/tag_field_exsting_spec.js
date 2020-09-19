import Vuex from 'vuex';
import { GlFormInput } from '@gitlab/ui';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import TagFieldExisting from '~/releases/components/tag_field_existing.vue';
import createStore from '~/releases/stores';
import createDetailModule from '~/releases/stores/modules/detail';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_DOCS_PATH = '/help/test/docs/path';

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
  const findHelpLink = () => {
    const link = findHelp().find('a');

    return {
      text: link.text(),
      href: link.attributes('href'),
      target: link.attributes('target'),
    };
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        detail: createDetailModule({
          updateReleaseApiDocsPath: TEST_DOCS_PATH,
          tagName: TEST_TAG_NAME,
        }),
      },
    });

    store.state.detail.release = {
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
        'Changing a Release tag is only supported via Releases API. More information',
      );

      const helpLink = findHelpLink();

      expect(helpLink).toEqual({
        text: 'More information',
        href: TEST_DOCS_PATH,
        target: '_blank',
      });
    });
  });
});
