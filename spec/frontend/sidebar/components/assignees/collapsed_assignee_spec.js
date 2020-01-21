import { shallowMount } from '@vue/test-utils';
import CollapsedAssignee from '~/sidebar/components/assignees/collapsed_assignee.vue';
import AssigneeAvatar from '~/sidebar/components/assignees/assignee_avatar.vue';
import userDataMock from '../../user_data_mock';

const TEST_USER = userDataMock();
const TEST_ISSUABLE_TYPE = 'merge_request';

describe('CollapsedAssignee assignee component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      issuableType: TEST_ISSUABLE_TYPE,
      ...props,
    };

    wrapper = shallowMount(CollapsedAssignee, {
      propsData,
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
    ).toEqual(TEST_USER.name);
  });

  it('has assignee avatar', () => {
    createComponent();

    expect(wrapper.find(AssigneeAvatar).props()).toEqual({
      imgSize: 24,
      user: TEST_USER,
      issuableType: TEST_ISSUABLE_TYPE,
    });
  });
});
