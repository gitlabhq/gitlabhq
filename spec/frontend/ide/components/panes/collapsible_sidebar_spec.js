import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import IdeSidebarNav from '~/ide/components/ide_sidebar_nav.vue';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import { createStore } from '~/ide/stores';
import paneModule from '~/ide/stores/modules/pane';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/panes/collapsible_sidebar.vue', () => {
  let wrapper;
  let store;

  const width = 350;
  const fakeComponentName = 'fake-component';

  const createComponent = (props) => {
    wrapper = shallowMount(CollapsibleSidebar, {
      localVue,
      store,
      propsData: {
        extensionTabs: [],
        side: 'right',
        width,
        ...props,
      },
    });
  };

  const findSidebarNav = () => wrapper.find(IdeSidebarNav);

  beforeEach(() => {
    store = createStore();
    store.registerModule('leftPane', paneModule());
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with a tab', () => {
    let fakeView;
    let extensionTabs;

    beforeEach(() => {
      const FakeComponent = localVue.component(fakeComponentName, {
        render: () => null,
      });

      fakeView = {
        name: fakeComponentName,
        keepAlive: true,
        component: FakeComponent,
      };

      extensionTabs = [
        {
          show: true,
          title: fakeComponentName,
          views: [fakeView],
          icon: 'text-description',
          buttonClasses: ['button-class-1', 'button-class-2'],
        },
      ];
    });

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

      it('nothing is dispatched', () => {
        expect(store.dispatch).not.toHaveBeenCalled();
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
  });
});
