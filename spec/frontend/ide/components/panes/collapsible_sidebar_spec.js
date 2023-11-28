import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import IdeSidebarNav from '~/ide/components/ide_sidebar_nav.vue';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import { createStore } from '~/ide/stores';
import paneModule from '~/ide/stores/modules/pane';

Vue.use(Vuex);

describe('ide/components/panes/collapsible_sidebar.vue', () => {
  let wrapper;
  let store;

  const width = 350;
  const fakeComponentName = 'fake-component';

  const createComponent = (props) => {
    wrapper = shallowMount(CollapsibleSidebar, {
      store,
      propsData: {
        extensionTabs: [],
        side: 'right',
        width,
        ...props,
      },
    });
  };

  const findSidebarNav = () => wrapper.findComponent(IdeSidebarNav);

  beforeEach(() => {
    store = createStore();
    store.registerModule('leftPane', paneModule());
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  describe('with a tab', () => {
    const FakeComponent = Vue.component(fakeComponentName, {
      render: () => null,
    });

    const fakeView = {
      name: fakeComponentName,
      keepAlive: true,
      component: FakeComponent,
    };

    const extensionTabs = [
      {
        show: true,
        title: fakeComponentName,
        views: [fakeView],
        icon: 'text-description',
        buttonClasses: ['button-class-1', 'button-class-2'],
      },
    ];

    describe.each`
      side
      ${'left'}
      ${'right'}
    `('when side=$side', ({ side }) => {
      beforeEach(() => {
        createComponent({ extensionTabs, side });
      });

      it('correctly renders side specific attributes', () => {
        expect(wrapper.classes()).toContain('multi-file-commit-panel');
        expect(wrapper.classes()).toContain(`ide-${side}-sidebar`);
        expect(wrapper.find('.multi-file-commit-panel-inner')).not.toBe(null);
        expect(wrapper.find(`.ide-${side}-sidebar-${fakeComponentName}`)).not.toBe(null);
        expect(findSidebarNav().props('side')).toBe(side);
      });

      it('when sidebar emits open, dispatch open', () => {
        const view = 'lorem-view';

        findSidebarNav().vm.$emit('open', view);

        expect(store.dispatch).toHaveBeenCalledWith(`${side}Pane/open`, view);
      });

      it('when sidebar emits close, dispatch toggleOpen', () => {
        findSidebarNav().vm.$emit('close');

        expect(store.dispatch).toHaveBeenCalledWith(`${side}Pane/toggleOpen`);
      });
    });

    describe('when side bar is rendered initially', () => {
      it('nothing is dispatched', () => {
        createComponent({ extensionTabs });
        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });

    describe.each`
      isOpen
      ${true}
      ${false}
    `('when isOpen=$isOpen', ({ isOpen }) => {
      beforeEach(() => {
        store.state.rightPane.isOpen = isOpen;
        store.state.rightPane.currentView = fakeComponentName;

        createComponent({ extensionTabs });
      });

      it(`tab view is shown=${isOpen}`, () => {
        expect(wrapper.find('.js-tab-view').exists()).toBe(isOpen);
      });

      it('renders sidebar nav', () => {
        expect(findSidebarNav().props()).toEqual({
          tabs: extensionTabs,
          side: 'right',
          currentView: fakeComponentName,
          isOpen,
        });
      });
    });

    describe('with initOpenView that does not exist', () => {
      it('nothing is dispatched', () => {
        createComponent({ extensionTabs, initOpenView: 'does-not-exist' });
        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });

    describe('with initOpenView that does exist', () => {
      it('dispatches open with view on create', () => {
        createComponent({ extensionTabs, initOpenView: fakeView.name });
        expect(store.dispatch).toHaveBeenCalledWith('rightPane/open', fakeView);
      });
    });
  });
});
