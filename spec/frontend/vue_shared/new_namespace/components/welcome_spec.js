import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { mockTracking } from 'helpers/tracking_helper';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';

describe('Welcome page', () => {
  let wrapper;
  let trackingSpy;

  const DEFAULT_PROPS = {
    title: 'Create new something',
  };

  const createComponent = ({ propsData, slots }) => {
    wrapper = shallowMount(WelcomePage, {
      slots,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
  });

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
    wrapper = null;
  });

  it('tracks link clicks', async () => {
    createComponent({ propsData: { panels: [{ name: 'test', href: '#' }] } });
    const link = wrapper.find('a');
    link.trigger('click');
    await nextTick();
    return wrapper.vm.$nextTick().then(() => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', { label: 'test' });
    });
  });

  it('renders footer slot if provided', () => {
    const DUMMY = 'Test message';
    createComponent({
      slots: { footer: DUMMY },
      propsData: { panels: [{ name: 'test', href: '#' }] },
    });

    expect(wrapper.text()).toContain(DUMMY);
  });
});
