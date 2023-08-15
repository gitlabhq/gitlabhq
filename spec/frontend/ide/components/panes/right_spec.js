import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import RightPane from '~/ide/components/panes/right.vue';
import { rightSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import extendStore from '~/ide/stores/extend';

Vue.use(Vuex);

describe('ide/components/panes/right.vue', () => {
  let wrapper;
  let store;

  const createComponent = (props) => {
    extendStore(store, document.createElement('div'));

    wrapper = shallowMount(RightPane, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders collapsible-sidebar', () => {
      expect(wrapper.findComponent(CollapsibleSidebar).props()).toMatchObject({
        side: 'right',
      });
    });
  });

  describe('pipelines tab', () => {
    it('is always shown', () => {
      createComponent();

      expect(wrapper.findComponent(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: true,
            title: 'Pipelines',
            views: expect.arrayContaining([
              expect.objectContaining({
                name: rightSidebarViews.pipelines.name,
              }),
              expect.objectContaining({
                name: rightSidebarViews.jobsDetail.name,
              }),
            ]),
          }),
        ]),
      );
    });
  });

  describe('terminal tab', () => {
    beforeEach(() => {
      createComponent();
    });

    it('adds terminal tab', async () => {
      store.state.terminal.isVisible = true;

      await nextTick();
      expect(wrapper.findComponent(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: true,
            title: 'Terminal',
          }),
        ]),
      );
    });

    it('hides terminal tab when not visible', () => {
      store.state.terminal.isVisible = false;

      expect(wrapper.findComponent(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: false,
            title: 'Terminal',
          }),
        ]),
      );
    });
  });
});
