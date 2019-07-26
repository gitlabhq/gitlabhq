import { shallowMount } from '@vue/test-utils';
import CollapsedAssignee from '~/sidebar/components/assignees/collapsed_assignee.vue';
import userDataMock from '../../user_data_mock';

describe('CollapsedAssignee assignee component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      ...props,
    };

    wrapper = shallowMount(CollapsedAssignee, {
      propsData,
      sync: false,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('has author name', () => {
    createComponent();

    expect(
      wrapper
        .find('.author')
        .text()
        .trim(),
    ).toEqual(wrapper.vm.user.name);
  });
});
