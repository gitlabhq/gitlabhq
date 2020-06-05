import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import component from '~/registry/explorer/components/details_page/details_header.vue';
import { DETAILS_PAGE_TITLE } from '~/registry/explorer/constants';

describe('Details Header', () => {
  let wrapper;

  const mountComponent = propsData => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  it('has the correct title ', () => {
    mountComponent();
    expect(wrapper.text()).toMatchInterpolatedText(DETAILS_PAGE_TITLE);
  });

  it('shows imageName in the title', () => {
    mountComponent({ imageName: 'foo' });
    expect(wrapper.text()).toContain('foo');
  });
});
