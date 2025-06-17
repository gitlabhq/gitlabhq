import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeChecksTitleRegex from '~/vue_merge_request_widget/components/checks/title_regex.vue';
import MergeChecksMessage from '~/vue_merge_request_widget/components/checks/message.vue';

describe('MergeChecksTitleRegex component', () => {
  let wrapper;

  function createComponent(
    propsData = {
      check: {
        status: 'FAILED',
        identifier: 'title_regex',
      },
    },
  ) {
    wrapper = mountExtended(MergeChecksTitleRegex, {
      propsData,
    });
  }

  it('passes check down to the MergeChecksMessage', () => {
    const check = {
      status: 'failed',
      identifier: 'title_regex',
    };
    createComponent({ check });

    expect(wrapper.findComponent(MergeChecksMessage).props('check')).toEqual(check);
  });

  it('has a link to the edit page', () => {
    const editPath = `${document.location.pathname.replace(/\/$/, '')}/edit`;

    createComponent();

    const editLink = wrapper.findByTestId('extension-actions-button');

    expect(editLink.attributes('href')).toBe(editPath);
  });
});
