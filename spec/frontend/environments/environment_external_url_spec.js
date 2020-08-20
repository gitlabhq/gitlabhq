import { mount } from '@vue/test-utils';
import ExternalUrlComp from '~/environments/components/environment_external_url.vue';

describe('External URL Component', () => {
  let wrapper;
  const externalUrl = 'https://gitlab.com';

  beforeEach(() => {
    wrapper = mount(ExternalUrlComp, { propsData: { externalUrl } });
  });

  it('should link to the provided externalUrl prop', () => {
    expect(wrapper.attributes('href')).toEqual(externalUrl);
    expect(wrapper.find('a').exists()).toBe(true);
  });
});
