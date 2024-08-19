import { shallowMount, mount } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import RunnerEditDisclosureDropdownItem from '~/ci/runner/components/runner_edit_disclosure_dropdown_item.vue';
import { I18N_EDIT } from '~/ci/runner/constants';

describe('RunnerEditDisclosureDropdownItem', () => {
  let wrapper;

  const findItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const createComponent = ({ props = {}, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(RunnerEditDisclosureDropdownItem, {
      propsData: {
        href: '/edit',
        ...props,
      },
      ...options,
    });
  };

  it('Displays Edit text', () => {
    createComponent({ mountFn: mount });

    expect(wrapper.text()).toBe(I18N_EDIT);
  });

  it('Renders a link and adds an href attribute', () => {
    createComponent();

    expect(findItem().props('item').href).toBe('/edit');
  });

  describe('When no href is provided', () => {
    beforeEach(() => {
      createComponent({ props: { href: null } });
    });

    it('does not render', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
