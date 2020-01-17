import Vue from 'vue';
import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import RightPane from '~/ide/components/panes/right.vue';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import { rightSidebarViews } from '~/ide/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/panes/right.vue', () => {
  let wrapper;
  let store;

  const createComponent = props => {
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

  it('allows tabs to be added via extensionTabs prop', () => {
    createComponent({
      extensionTabs: [
        {
          show: true,
          title: 'FakeTab',
        },
      ],
    });

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'FakeTab',
        }),
      ]),
    );
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

  describe('merge request tab', () => {
    it('is shown if there is a currentMergeRequestId', () => {
      store.state.currentMergeRequestId = 1;

      createComponent();

      expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: true,
            title: 'Merge Request',
            views: expect.arrayContaining([
              expect.objectContaining({
                name: rightSidebarViews.mergeRequestInfo.name,
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
});
