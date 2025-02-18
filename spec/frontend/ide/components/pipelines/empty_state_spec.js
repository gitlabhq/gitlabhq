import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/ide/components/pipelines/empty_state.vue';
import { createStore } from '~/ide/stores';

const TEST_PIPELINES_EMPTY_STATE_SVG_PATH = 'illustrations/test/pipelines.svg';

describe('~/ide/components/pipelines/empty_state.vue', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(EmptyState, {
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.dispatch('setEmptyStateSvgs', {
      pipelinesEmptyStateSvgPath: TEST_PIPELINES_EMPTY_STATE_SVG_PATH,
    });
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty state', () => {
      expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
        title: EmptyState.i18n.title,
        description: EmptyState.i18n.description,
        primaryButtonText: EmptyState.i18n.primaryButtonText,
        primaryButtonLink: '/help/ci/quick_start/_index.md',
        svgPath: TEST_PIPELINES_EMPTY_STATE_SVG_PATH,
      });
    });
  });
});
