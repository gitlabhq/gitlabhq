import { GlTab } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { stubComponent } from 'helpers/stub_component';
import RepoTab from '~/ide/components/repo_tab.vue';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

const GlTabStub = stubComponent(GlTab, {
  template: '<li><slot name="title" /></li>',
});

describe('RepoTab', () => {
  let wrapper;
  let store;
  let router;

  const findTab = () => wrapper.find(GlTabStub);

  function createComponent(propsData) {
    wrapper = mount(RepoTab, {
      localVue,
      store,
      propsData,
      stubs: {
        GlTab: GlTabStub,
      },
    });
  }

  beforeEach(() => {
    store = createStore();
    router = createRouter(store);
    jest.spyOn(router, 'push').mockImplementation(() => {});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a close link and a name link', () => {
    createComponent({
      tab: file(),
    });
    wrapper.vm.$store.state.openFiles.push(wrapper.vm.tab);
    const close = wrapper.find('.multi-file-tab-close');
    const name = wrapper.find(`[title]`);

    expect(close.html()).toContain('#close');
    expect(name.text().trim()).toEqual(wrapper.vm.tab.name);
  });

  it('does not call openPendingTab when tab is active', async () => {
    createComponent({
      tab: {
        ...file(),
        pending: true,
        active: true,
      },
    });

    jest.spyOn(wrapper.vm, 'openPendingTab').mockImplementation(() => {});

    await findTab().vm.$emit('click');

    expect(wrapper.vm.openPendingTab).not.toHaveBeenCalled();
  });

  it('fires clickFile when the link is clicked', () => {
    createComponent({
      tab: file(),
    });

    jest.spyOn(wrapper.vm, 'clickFile').mockImplementation(() => {});

    findTab().vm.$emit('click');

    expect(wrapper.vm.clickFile).toHaveBeenCalledWith(wrapper.vm.tab);
  });

  it('calls closeFile when clicking close button', () => {
    createComponent({
      tab: file(),
    });

    jest.spyOn(wrapper.vm, 'closeFile').mockImplementation(() => {});

    wrapper.find('.multi-file-tab-close').trigger('click');

    expect(wrapper.vm.closeFile).toHaveBeenCalledWith(wrapper.vm.tab);
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

    expect(wrapper.find('button').attributes('aria-label')).toBe(closeLabel);
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
        wrapper.vm.$store.state.openFiles.push(tab);
        wrapper.vm.$store.state.changedFiles.push(tab);
        wrapper.vm.$store.state.entries[tab.path] = tab;
        wrapper.vm.$store.dispatch('setFileActive', tab.path);

        await wrapper.find('.multi-file-tab-close').trigger('click');

        expect(tab.opened).toBeFalsy();
        expect(wrapper.vm.$store.state.changedFiles).toHaveLength(1);
      });

      it('closes tab when clicking close btn', async () => {
        const tab = file('lose');
        tab.opened = true;
        createComponent({
          tab,
        });
        wrapper.vm.$store.state.openFiles.push(tab);
        wrapper.vm.$store.state.entries[tab.path] = tab;
        wrapper.vm.$store.dispatch('setFileActive', tab.path);

        await wrapper.find('.multi-file-tab-close').trigger('click');

        expect(tab.opened).toBeFalsy();
      });
    });
  });
});
