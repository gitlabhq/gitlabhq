import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlButton } from '@gitlab/ui';
import Trigger from '~/whats_new/components/trigger.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Trigger', () => {
  let wrapper;
  let store;
  let actions;
  let state;

  beforeEach(() => {
    actions = {
      openDrawer: jest.fn(),
    };

    state = {
      open: true,
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    wrapper = mount(Trigger, {
      localVue,
      store,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches openDrawer when clicking close', () => {
    wrapper.find(GlButton).vm.$emit('click');
    expect(actions.openDrawer).toHaveBeenCalled();
  });
});
