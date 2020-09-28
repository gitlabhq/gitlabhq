import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlDrawer } from '@gitlab/ui';
import App from '~/whats_new/components/app.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('App', () => {
  let wrapper;
  let store;
  let actions;
  let state;
  let propsData = { features: '[ {"title":"Whats New Drawer"} ]', storageKey: 'storage-key' };

  const buildWrapper = () => {
    actions = {
      openDrawer: jest.fn(),
      closeDrawer: jest.fn(),
    };

    state = {
      open: true,
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    wrapper = mount(App, {
      localVue,
      store,
      propsData,
    });
  };

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const getDrawer = () => wrapper.find(GlDrawer);

  it('contains a drawer', () => {
    expect(getDrawer().exists()).toBe(true);
  });

  it('dispatches openDrawer when mounted', () => {
    expect(actions.openDrawer).toHaveBeenCalled();
    expect(actions.openDrawer).toHaveBeenCalledWith(expect.any(Object), 'storage-key');
  });

  it('dispatches closeDrawer when clicking close', () => {
    getDrawer().vm.$emit('close');
    expect(actions.closeDrawer).toHaveBeenCalled();
  });

  it.each([true, false])('passes open property', async openState => {
    wrapper.vm.$store.state.open = openState;

    await wrapper.vm.$nextTick();

    expect(getDrawer().props('open')).toBe(openState);
  });

  it('renders features when provided as props', () => {
    expect(wrapper.find('h5').text()).toBe('Whats New Drawer');
  });

  it('handles bad json argument gracefully', () => {
    propsData = { features: 'this is not json', storageKey: 'storage-key' };
    buildWrapper();

    expect(getDrawer().exists()).toBe(true);
  });
});
