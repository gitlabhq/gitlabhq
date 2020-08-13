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

  beforeEach(() => {
    actions = {
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
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const getDrawer = () => wrapper.find(GlDrawer);

  it('contains a drawer', () => {
    expect(getDrawer().exists()).toBe(true);
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
});
