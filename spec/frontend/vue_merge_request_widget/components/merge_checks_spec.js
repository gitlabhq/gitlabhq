import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeChecksComponent from '~/vue_merge_request_widget/components/merge_checks.vue';
import mergeChecksQuery from '~/vue_merge_request_widget/queries/merge_checks.query.graphql';
import StatusIcon from '~/vue_merge_request_widget/components/extensions/status_icon.vue';

Vue.use(VueApollo);

let wrapper;
let apolloProvider;

function factory({ canMerge = true, mergeChecks = [] } = {}) {
  apolloProvider = createMockApollo([
    [
      mergeChecksQuery,
      jest.fn().mockResolvedValue({
        data: {
          project: {
            id: 1,
            mergeRequest: { id: 1, userPermissions: { canMerge }, mergeChecks },
          },
        },
      }),
    ],
  ]);

  wrapper = mountExtended(MergeChecksComponent, {
    apolloProvider,
    propsData: {
      mr: {},
    },
  });
}

describe('Merge request merge checks component', () => {
  afterEach(() => {
    apolloProvider = null;
  });

  it('renders ready to merge text if user can merge', async () => {
    factory({ canMerge: true });

    await waitForPromises();

    expect(wrapper.text()).toBe('Ready to merge!');
  });

  it('renders ready to merge by members text if user can not merge', async () => {
    factory({ canMerge: false });

    await waitForPromises();

    expect(wrapper.text()).toBe('Ready to merge by members who can write to the target branch.');
  });

  it.each`
    mergeChecks                                                                                      | text
    ${[{ identifier: 'discussions', result: 'failed' }]}                                             | ${'Merge blocked: 1 check failed'}
    ${[{ identifier: 'discussions', result: 'failed' }, { identifier: 'rebase', result: 'failed' }]} | ${'Merge blocked: 2 checks failed'}
  `('renders $text for $mergeChecks', async ({ mergeChecks, text }) => {
    factory({ mergeChecks });

    await waitForPromises();

    expect(wrapper.text()).toBe(text);
  });

  it.each`
    result      | statusIcon
    ${'failed'} | ${'failed'}
    ${'passed'} | ${'success'}
  `('renders $statusIcon for $result result', async ({ result, statusIcon }) => {
    factory({ mergeChecks: [{ result, identifier: 'discussions' }] });

    await waitForPromises();

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(statusIcon);
  });

  it('expands collapsed area', async () => {
    factory();

    await waitForPromises();

    await wrapper.findByTestId('widget-toggle').trigger('click');

    expect(wrapper.findByTestId('merge-checks-full').exists()).toBe(true);
  });
});
