import { mount } from '@vue/test-utils';
import groupEmptyState from '~/registry/list/components/group_empty_state.vue';

describe('Registry Group Empty state', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(groupEmptyState, {
      propsData: {
        noContainersImage: 'imageUrl',
        helpPagePath: 'help',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
