import { shallowMount } from '@vue/test-utils';

import UserDate from '~/vue_shared/components/user_date.vue';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
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

  it.each`
    date         | dateFormat          | output
    ${mockDate}  | ${undefined}        | ${'Nov 13, 2020'}
    ${null}      | ${undefined}        | ${'Never'}
    ${undefined} | ${undefined}        | ${'Never'}
    ${mockDate}  | ${ISO_SHORT_FORMAT} | ${'2020-11-13'}
    ${null}      | ${ISO_SHORT_FORMAT} | ${'Never'}
    ${undefined} | ${ISO_SHORT_FORMAT} | ${'Never'}
  `('renders $date as $output', ({ date, dateFormat, output }) => {
    initComponent({ date, dateFormat });

    expect(wrapper.text()).toBe(output);
  });
});
