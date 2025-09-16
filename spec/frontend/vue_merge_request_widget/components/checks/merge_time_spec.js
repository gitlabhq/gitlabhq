import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeTimeComponent from '~/vue_merge_request_widget/components/checks/merge_time.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import mergeTimeQuery from '~/vue_merge_request_widget/queries/states/merge_time.query.graphql';

Vue.use(VueApollo);

let wrapper;

function factory(propsData = {}) {
  const apolloProvider = createMockApollo([
    [
      mergeTimeQuery,
      jest.fn().mockResolvedValue({
        data: {
          project: { id: 1, mergeRequest: { id: 1, mergeAfter: propsData.mr.mergeAfter } },
        },
      }),
    ],
  ]);

  wrapper = mountExtended(MergeTimeComponent, {
    propsData,
    apolloProvider,
  });
}

describe('Merge request merge checks merge time component', () => {
  it('renders failure reason text', async () => {
    factory({
      check: { status: 'success', identifier: 'merge_time' },
      mr: {
        targetProjectFullPath: 'gitlab',
        iid: '1',
        targetBranch: 'main',
        mergeAfter: '2024-10-17T18:23:00Z',
      },
    });

    await waitForPromises();

    expect(wrapper.text()).toBe('Cannot merge until Oct 17, 2024, 6:23 PM');
  });

  it.each`
    status        | icon
    ${'success'}  | ${'success'}
    ${'failed'}   | ${'failed'}
    ${'inactive'} | ${'neutral'}
  `('renders $icon icon for $status result', async ({ status, icon }) => {
    factory({
      check: { status, identifier: 'merge_time' },
      mr: {
        targetProjectFullPath: 'gitlab',
        iid: '1',
        targetBranch: 'main',
        mergeAfter: '2024-10-17T18:23:00Z',
      },
    });

    await waitForPromises();

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(icon);
  });
});
