import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import paneModule from '~/ide/stores/modules/pane';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import Vuex from 'vuex';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/panes/collapsible_sidebar.vue', () => {
  let wrapper;
  let store;

  const width = 350;
  const fakeComponentName = 'fake-component';

  const createComponent = props => {
    wrapper = shallowMount(CollapsibleSidebar, {
      localVue,
      store,
      propsData: {
        extensionTabs: [],
        side: 'right',
        width,
        ...props,
      },
      slots: {
        'header-icon': '<div class=".header-icon-slot">SLOT ICON</div>',
        header: '<div class=".header-slot"/>',
        footer: '<div class=".footer-slot"/>',
      },
    });
  };

  const findTabButton = () => wrapper.find(`[data-qa-selector="${fakeComponentName}_tab_button"]`);

  beforeEach(() => {
    store = createStore();
    store.registerModule('leftPane', paneModule());
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
        render: () => {},
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
      it('correctly renders side specific attributes', () => {
        createComponent({ extensionTabs, side });
        const button = findTabButton();

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.classes()).toContain('multi-file-commit-panel');
          expect(wrapper.classes()).toContain(`ide-${side}-sidebar`);
          expect(wrapper.find('.multi-file-commit-panel-inner')).not.toBe(null);
          expect(wrapper.find(`.ide-${side}-sidebar-${fakeComponentName}`)).not.toBe(null);
          expect(button.attributes('data-placement')).toEqual(side === 'left' ? 'right' : 'left');
          if (side === 'right') {
            // this class is only needed on the right side; there is no 'is-left'
            expect(button.classes()).toContain('is-right');
          } else {
            expect(button.classes()).not.toContain('is-right');
          }
        });
      });
    });

    describe('when default side', () => {
      let button;

      beforeEach(() => {
        createComponent({ extensionTabs });

        button = findTabButton();
      });

      it('correctly renders tab-specific classes', () => {
        store.state.rightPane.currentView = fakeComponentName;

        return wrapper.vm.$nextTick().then(() => {
          expect(button.classes()).toContain('button-class-1');
          expect(button.classes()).toContain('button-class-2');
        });
      });

      it('can show an open pane tab with an active view', () => {
        store.state.rightPane.isOpen = true;
        store.state.rightPane.currentView = fakeComponentName;

        return wrapper.vm.$nextTick().then(() => {
          expect(button.classes()).toEqual(expect.arrayContaining(['ide-sidebar-link', 'active']));
          expect(button.attributes('data-original-title')).toEqual(fakeComponentName);
          expect(wrapper.find('.js-tab-view').exists()).toBe(true);
        });
      });

      it('does not show a pane which is not open', () => {
        store.state.rightPane.isOpen = false;
        store.state.rightPane.currentView = fakeComponentName;

        return wrapper.vm.$nextTick().then(() => {
          expect(button.classes()).not.toEqual(
            expect.arrayContaining(['ide-sidebar-link', 'active']),
          );
          expect(wrapper.find('.js-tab-view').exists()).toBe(false);
        });
      });

      describe('when button is clicked', () => {
        it('opens view', () => {
          button.trigger('click');
          expect(store.state.rightPane.isOpen).toBeTruthy();
        });

        it('toggles open view if tab is currently active', () => {
          button.trigger('click');
          expect(store.state.rightPane.isOpen).toBeTruthy();

          button.trigger('click');
          expect(store.state.rightPane.isOpen).toBeFalsy();
        });
      });

      it('shows header-icon', () => {
        expect(wrapper.find('.header-icon-slot')).not.toBeNull();
      });

      it('shows header', () => {
        expect(wrapper.find('.header-slot')).not.toBeNull();
      });

      it('shows footer', () => {
        expect(wrapper.find('.footer-slot')).not.toBeNull();
      });
    });
  });
});
