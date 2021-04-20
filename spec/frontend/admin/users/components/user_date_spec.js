import { shallowMount } from '@vue/test-utils';

import UserDate from '~/vue_shared/components/user_date.vue';
import { users } from '../mock_data';

const mockDate = users[0].createdAt;

describe('FormatDate component', () => {
  let wrapper;

  const initComponent = (props = {}) => {
    wrapper = shallowMount(UserDate, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it.each`
    date         | output
    ${mockDate}  | ${'13 Nov, 2020'}
    ${null}      | ${'Never'}
    ${undefined} | ${'Never'}
  `('renders $date as $output', ({ date, output }) => {
    initComponent({ date });

    expect(wrapper.text()).toBe(output);
  });
});
