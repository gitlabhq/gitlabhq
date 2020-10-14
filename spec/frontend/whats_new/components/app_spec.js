import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlDrawer } from '@gitlab/ui';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import App from '~/whats_new/components/app.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('App', () => {
  const propsData = { storageKey: 'storage-key' };
  let wrapper;
  let store;
  let actions;
  let state;
  let trackingSpy;

  const buildWrapper = () => {
    actions = {
      openDrawer: jest.fn(),
      closeDrawer: jest.fn(),
      fetchItems: jest.fn(),
    };

    state = {
      open: true,
      features: null,
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

  beforeEach(async () => {
    document.body.dataset.page = 'test-page';
    document.body.dataset.namespaceId = 'namespace-840';

    trackingSpy = mockTracking('_category_', null, jest.spyOn);
    buildWrapper();

    wrapper.vm.$store.state.features = [{ title: 'Whats New Drawer', url: 'www.url.com' }];
    await wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  const getDrawer = () => wrapper.find(GlDrawer);

  it('contains a drawer', () => {
    expect(getDrawer().exists()).toBe(true);
  });

  it('dispatches openDrawer when mounted', () => {
    expect(actions.openDrawer).toHaveBeenCalledWith(expect.any(Object), 'storage-key');
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_whats_new_drawer', {
      label: 'namespace_id',
      value: 'namespace-840',
    });
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

  it('renders features when provided via ajax', () => {
    expect(actions.fetchItems).toHaveBeenCalled();
    expect(wrapper.find('h5').text()).toBe('Whats New Drawer');
  });

  it('send an event when feature item is clicked', () => {
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

    const link = wrapper.find('[data-testid="whats-new-title-link"]');
    triggerEvent(link.element);

    expect(trackingSpy.mock.calls[1]).toMatchObject([
      '_category_',
      'click_whats_new_item',
      {
        label: 'Whats New Drawer',
        property: 'www.url.com',
      },
    ]);
  });
});
