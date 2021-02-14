import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import RightPane from '~/ide/components/panes/right.vue';
import { rightSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import extendStore from '~/ide/stores/extend';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/panes/right.vue', () => {
  let wrapper;
  let store;

  const createComponent = (props) => {
    extendStore(store, document.createElement('div'));

    wrapper = shallowMount(RightPane, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('pipelines tab', () => {
    it('is always shown', () => {
      createComponent();

      expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

  describe('clientside live preview tab', () => {
    it('is shown if there is a packageJson and clientsidePreviewEnabled', () => {
      Vue.set(store.state.entries, 'package.json', {
        name: 'package.json',
      });
      store.state.clientsidePreviewEnabled = true;

      createComponent();

      expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: true,
            title: 'Live preview',
            views: expect.arrayContaining([
              expect.objectContaining({
                name: rightSidebarViews.clientSidePreview.name,
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

    it('adds terminal tab', () => {
      store.state.terminal.isVisible = true;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              show: true,
              title: 'Terminal',
            }),
          ]),
        );
      });
    });

    it('hides terminal tab when not visible', () => {
      store.state.terminal.isVisible = false;

      expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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
