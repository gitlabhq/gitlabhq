import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/admin/users/components/actions';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { CONFIRMATION_ACTIONS } from '../../constants';

describe('Action components', () => {
  let wrapper;

  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const initComponent = ({ component, props } = {}) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...props,
      },
    });
  };

  describe('CONFIRMATION_ACTIONS', () => {
    it.each(CONFIRMATION_ACTIONS)('renders a dropdown item for "%s"', (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          path: '/test',
        },
      });

      expect(findDisclosureDropdownItem().exists()).toBe(true);
    });
  });
});
