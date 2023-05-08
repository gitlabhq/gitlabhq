import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ExternalUrlComp from '~/environments/components/environment_external_url.vue';

describe('External URL Component', () => {
  let wrapper;
  const externalUrl = 'https://gitlab.com';

  beforeEach(() => {
    wrapper = mount(ExternalUrlComp, { propsData: { externalUrl } });
  });

  it('should link to the provided externalUrl prop', () => {
    const button = wrapper.findComponent(GlButton);
    expect(button.attributes('href')).toEqual(externalUrl);
    expect(button.props('isUnsafeLink')).toBe(true);
  });
});
