import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import RightPane from '~/ide/components/panes/right.vue';
import SwitchEditorsView from '~/ide/components/switch_editors/switch_editors_view.vue';
import { rightSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import extendStore from '~/ide/stores/extend';
import { __ } from '~/locale';

Vue.use(Vuex);

const SWITCH_EDITORS_VIEW_NAME = 'switch-editors';

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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders collapsible-sidebar', () => {
      expect(wrapper.findComponent(CollapsibleSidebar).props()).toMatchObject({
        side: 'right',
        initOpenView: SWITCH_EDITORS_VIEW_NAME,
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

  describe('clientside live preview tab', () => {
    it('is shown if there is a packageJson and clientsidePreviewEnabled', () => {
      Vue.set(store.state.entries, 'package.json', {
        name: 'package.json',
      });
      store.state.clientsidePreviewEnabled = true;

      createComponent();

      expect(wrapper.findComponent(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

  describe('switch editors tab', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      desc              | canUseNewWebIde | expectedShow
      ${'is shown'}     | ${true}         | ${true}
      ${'is not shown'} | ${false}        | ${false}
    `('with canUseNewWebIde=$canUseNewWebIde, $desc', async ({ canUseNewWebIde, expectedShow }) => {
      Object.assign(store.state, { canUseNewWebIde });

      await nextTick();

      expect(wrapper.findComponent(CollapsibleSidebar).props('extensionTabs')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            show: expectedShow,
            title: __('Switch editors'),
            views: [
              { component: SwitchEditorsView, name: SWITCH_EDITORS_VIEW_NAME, keepAlive: true },
            ],
          }),
        ]),
      );
    });
  });
});
