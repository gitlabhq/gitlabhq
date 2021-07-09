import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { kebabCase } from 'lodash';
import { nextTick } from 'vue';
import Actions from '~/admin/users/components/actions';
import SharedDeleteAction from '~/admin/users/components/actions/shared/shared_delete_action.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import { CONFIRMATION_ACTIONS, DELETE_ACTIONS } from '../../constants';

describe('Action components', () => {
  let wrapper;

  const findDropdownItem = () => wrapper.find(GlDropdownItem);

  const initComponent = ({ component, props, stubs = {} } = {}) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...props,
      },
      stubs,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('CONFIRMATION_ACTIONS', () => {
    it.each(CONFIRMATION_ACTIONS)('renders a dropdown item for "%s"', async (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          path: '/test',
        },
      });

      await nextTick();

      expect(wrapper.attributes('data-path')).toBe('/test');
      expect(wrapper.attributes('data-modal-attributes')).toContain('John Doe');
      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  describe('DELETE_ACTION_COMPONENTS', () => {
    const oncallSchedules = [{ name: 'schedule1' }, { name: 'schedule2' }];
    it.each(DELETE_ACTIONS)('renders a dropdown item for "%s"', async (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          paths: {
            delete: '/delete',
            block: '/block',
          },
          oncallSchedules,
        },
        stubs: { SharedDeleteAction },
      });

      await nextTick();

      const sharedAction = wrapper.find(SharedDeleteAction);

      expect(sharedAction.attributes('data-block-user-url')).toBe('/block');
      expect(sharedAction.attributes('data-delete-user-url')).toBe('/delete');
      expect(sharedAction.attributes('data-gl-modal-action')).toBe(kebabCase(action));
      expect(sharedAction.attributes('data-username')).toBe('John Doe');
      expect(sharedAction.attributes('data-oncall-schedules')).toBe(
        JSON.stringify(oncallSchedules),
      );
      expect(findDropdownItem().exists()).toBe(true);
    });
  });
});
