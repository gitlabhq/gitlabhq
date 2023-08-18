import { GlTab } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { stubComponent } from 'helpers/stub_component';
import RepoTab from '~/ide/components/repo_tab.vue';
import { createStore } from '~/ide/stores';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { file } from '../helpers';

Vue.use(Vuex);

const GlTabStub = stubComponent(GlTab, {
  template: '<li><slot name="title" /></li>',
});

describe('RepoTab', () => {
  let wrapper;
  let store;

  const pushMock = jest.fn();
  const findTab = () => wrapper.findComponent(GlTabStub);
  const findCloseButton = () => wrapper.findByTestId('close-button');

  function createComponent(propsData) {
    wrapper = mountExtended(RepoTab, {
      store,
      propsData,
      stubs: {
        GlTab: GlTabStub,
      },
      mocks: {
        $router: {
          push: pushMock,
        },
      },
    });
  }

  beforeEach(() => {
    store = createStore();
  });

  it('renders a close link and a name link', () => {
    const tab = file();
    createComponent({
      tab,
    });
    store.state.openFiles.push(tab);
    const name = wrapper.find(`[title]`);

    expect(findCloseButton().html()).toContain('#close');
    expect(name.text()).toBe(tab.name);
  });

  it('does not call openPendingTab when tab is active', async () => {
    createComponent({
      tab: {
        ...file(),
        pending: true,
        active: true,
      },
    });

    jest.spyOn(store, 'dispatch');

    await findTab().vm.$emit('click');

    expect(store.dispatch).not.toHaveBeenCalledWith('openPendingTab');
  });

  it('fires clickFile when the link is clicked', async () => {
    const { getters } = store;
    const tab = file();
    createComponent({ tab });

    await findTab().vm.$emit('click', tab);

    expect(pushMock).toHaveBeenCalledWith(getters.getUrlForPath(tab.path));
  });

  it('calls closeFile when clicking close button', async () => {
    const tab = file();
    createComponent({ tab });
    store.state.entries[tab.path] = tab;

    jest.spyOn(store, 'dispatch');

    await findCloseButton().trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('closeFile', tab);
  });

  it('changes icon on hover', async () => {
    const tab = file();
    tab.changed = true;
    createComponent({
      tab,
    });

    await findTab().vm.$emit('mouseover');

    expect(wrapper.find('.file-modified').exists()).toBe(false);

    await findTab().vm.$emit('mouseout');

    expect(wrapper.find('.file-modified').exists()).toBe(true);
  });

  it.each`
    tabProps             | closeLabel
    ${{}}                | ${'Close foo.txt'}
    ${{ changed: true }} | ${'foo.txt changed'}
  `('close button has label ($closeLabel) with tab ($tabProps)', ({ tabProps, closeLabel }) => {
    const tab = { ...file('foo.txt'), ...tabProps };

    createComponent({ tab });

    expect(findCloseButton().attributes('aria-label')).toBe(closeLabel);
  });

  describe('locked file', () => {
    let f;

    beforeEach(() => {
      f = file('locked file');
      f.file_lock = {
        user: {
          name: 'testuser',
          updated_at: new Date(),
        },
      };

      createComponent({
        tab: f,
      });
    });

    it('renders lock icon', () => {
      expect(wrapper.find('.file-status-icon')).not.toBeNull();
    });

    it('renders a tooltip', () => {
      expect(wrapper.find('span:nth-child(2)').attributes('title')).toBe('Locked by testuser');
    });
  });

  describe('methods', () => {
    describe('closeTab', () => {
      it('closes tab if file has changed', async () => {
        const tab = file();
        tab.changed = true;
        tab.opened = true;
        createComponent({
          tab,
        });
        store.state.openFiles.push(tab);
        store.state.changedFiles.push(tab);
        store.state.entries[tab.path] = tab;
        store.dispatch('setFileActive', tab.path);

        await findCloseButton().trigger('click');

        expect(tab.opened).toBe(false);
        expect(store.state.changedFiles).toHaveLength(1);
      });

      it('closes tab when clicking close btn', async () => {
        const tab = file('lose');
        tab.opened = true;
        createComponent({
          tab,
        });
        store.state.openFiles.push(tab);
        store.state.entries[tab.path] = tab;
        store.dispatch('setFileActive', tab.path);

        await findCloseButton().trigger('click');

        expect(tab.opened).toBe(false);
      });
    });
  });
});
