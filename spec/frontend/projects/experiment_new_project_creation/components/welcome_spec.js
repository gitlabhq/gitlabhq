import { shallowMount } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import WelcomePage from '~/projects/experiment_new_project_creation/components/welcome.vue';

describe('Welcome page', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = propsData => {
    wrapper = shallowMount(WelcomePage, { propsData });
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

  it('tracks link clicks', () => {
    createComponent({ panels: [{ name: 'test', href: '#' }] });
    wrapper.find('a').trigger('click');
    return wrapper.vm.$nextTick().then(() => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', { label: 'test' });
    });
  });
});
