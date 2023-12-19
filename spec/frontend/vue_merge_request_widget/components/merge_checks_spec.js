import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeChecksComponent from '~/vue_merge_request_widget/components/merge_checks.vue';
import mergeChecksQuery from '~/vue_merge_request_widget/queries/merge_checks.query.graphql';
import StatusIcon from '~/vue_merge_request_widget/components/extensions/status_icon.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import { COMPONENTS } from '~/vue_merge_request_widget/components/checks/constants';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';
import rebaseStateQuery from '~/vue_merge_request_widget/queries/states/rebase.query.graphql';

Vue.use(VueApollo);

let wrapper;
let apolloProvider;

function factory(mountFn, { canMerge = true, mergeabilityChecks = [] } = {}) {
  apolloProvider = createMockApollo([
    [
      mergeChecksQuery,
      jest.fn().mockResolvedValue({
        data: {
          project: {
            id: 1,
            mergeRequest: { id: 1, userPermissions: { canMerge }, mergeabilityChecks },
          },
        },
      }),
    ],
    [
      conflictsStateQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                shouldBeRebased: false,
                sourceBranchProtected: false,
                userPermissions: { pushToSourceBranch: true },
              },
            },
          },
        }),
    ],
    [
      rebaseStateQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: '1',
              mergeRequest: {
                id: '2',
                rebaseInProgress: false,
                targetBranch: 'main',
                userPermissions: {
                  pushToSourceBranch: true,
                },
                pipelines: {
                  nodes: [
                    {
                      id: '1',
                      project: {
                        id: '2',
                        fullPath: 'gitlab/gitlab',
                      },
                    },
                  ],
                },
              },
            },
          },
        }),
    ],
  ]);

  wrapper = mountFn(MergeChecksComponent, {
    apolloProvider,
    propsData: {
      mr: {},
      service: {},
    },
  });
}

const mountComponent = factory.bind(null, mountExtended);
const shallowMountComponent = factory.bind(null, shallowMountExtended);

describe('Merge request merge checks component', () => {
  afterEach(() => {
    apolloProvider = null;
  });

  it('renders ready to merge text if user can merge', async () => {
    mountComponent({ canMerge: true });

    await waitForPromises();

    expect(wrapper.text()).toBe('Ready to merge!');
  });

  it('renders ready to merge by members text if user can not merge', async () => {
    mountComponent({ canMerge: false });

    await waitForPromises();

    expect(wrapper.text()).toBe('Ready to merge by members who can write to the target branch.');
  });

  it.each`
    mergeabilityChecks                                                                               | text
    ${[{ identifier: 'discussions', status: 'failed' }]}                                             | ${'Merge blocked: 1 check failed'}
    ${[{ identifier: 'discussions', status: 'failed' }, { identifier: 'rebase', status: 'failed' }]} | ${'Merge blocked: 2 checks failed'}
  `('renders $text for $mergeabilityChecks', async ({ mergeabilityChecks, text }) => {
    mountComponent({ mergeabilityChecks });

    await waitForPromises();

    expect(wrapper.text()).toBe(text);
  });

  it.each`
    status      | statusIcon
    ${'failed'} | ${'failed'}
    ${'passed'} | ${'success'}
  `('renders $statusIcon for $status result', async ({ status, statusIcon }) => {
    mountComponent({ mergeabilityChecks: [{ status, identifier: 'discussions' }] });

    await waitForPromises();

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(statusIcon);
  });

  it.each`
    identifier
    ${'conflict'}
    ${'discussions_not_resolved'}
    ${'need_rebase'}
    ${'default'}
  `('renders $identifier merge check', async ({ identifier }) => {
    shallowMountComponent({ mergeabilityChecks: [{ status: 'failed', identifier }] });

    wrapper.findComponent(StateContainer).vm.$emit('toggle');

    await waitForPromises();

    const { default: component } = await COMPONENTS[identifier]();

    expect(wrapper.findComponent(component).exists()).toBe(true);
  });

  it('expands collapsed area', async () => {
    mountComponent();

    await waitForPromises();

    await wrapper.findByTestId('widget-toggle').trigger('click');

    expect(wrapper.findByTestId('merge-checks-full').exists()).toBe(true);
  });
});
