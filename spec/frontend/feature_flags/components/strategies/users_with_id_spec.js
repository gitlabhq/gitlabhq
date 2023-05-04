import { GlFormTextarea } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import UsersWithId from '~/feature_flags/components/strategies/users_with_id.vue';
import { usersWithIdStrategy } from '../../mock_data';

const DEFAULT_PROPS = {
  strategy: usersWithIdStrategy,
};

describe('~/feature_flags/components/users_with_id.vue', () => {
  let wrapper;
  let textarea;

  const factory = (props = {}) => mount(UsersWithId, { propsData: { ...DEFAULT_PROPS, ...props } });

  beforeEach(() => {
    wrapper = factory();
    textarea = wrapper.findComponent(GlFormTextarea);
  });

  it('should display the current value of the parameters', () => {
    expect(textarea.element.value).toBe(usersWithIdStrategy.parameters.userIds);
  });

  it('should emit a change event when the IDs change', () => {
    textarea.setValue('4,5,6');

    expect(wrapper.emitted('change')).toEqual([[{ parameters: { userIds: '4,5,6' } }]]);
  });
});
