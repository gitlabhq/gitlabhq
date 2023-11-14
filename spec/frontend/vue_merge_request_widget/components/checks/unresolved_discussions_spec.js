import { mountExtended } from 'helpers/vue_test_utils_helper';
import notesEventHub from '~/notes/event_hub';
import MergeChecksUnresolvedDiscussions from '~/vue_merge_request_widget/components/checks/unresolved_discussions.vue';
import MergeChecksMessage from '~/vue_merge_request_widget/components/checks/message.vue';

describe('MergeChecksUnresolvedDiscussions component', () => {
  let wrapper;

  function createComponent(
    propsData = {
      check: {
        status: 'FAILED',
        failureReason: 'Failed message',
        identifier: 'discussions_not_resolved',
      },
    },
  ) {
    wrapper = mountExtended(MergeChecksUnresolvedDiscussions, {
      propsData,
    });
  }

  it('passes check down to the MergeChecksMessage', () => {
    const check = {
      status: 'failed',
      failureReason: 'Unresolved discussions',
      identifier: 'discussions_not_resolved',
    };
    createComponent({ check });

    expect(wrapper.findComponent(MergeChecksMessage).props('check')).toEqual(check);
  });

  it('does not show go to first unresolved discussion button with passed state', () => {
    createComponent({ check: { status: 'success', identifier: 'discussions_not_resolved' } });
    const button = wrapper.findByRole('button', { name: 'Go to first unresolved thread' });
    expect(button.exists()).toBe(false);
  });

  it('triggers go to first discussion action', () => {
    const callback = jest.fn();
    notesEventHub.$on('jumpToFirstUnresolvedDiscussion', callback);
    createComponent();

    wrapper.findByRole('button', { name: 'Go to first unresolved thread' }).trigger('click');

    expect(callback).toHaveBeenCalled();
  });
});
