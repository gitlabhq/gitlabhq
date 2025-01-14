import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeChecksComponent from '~/vue_merge_request_widget/components/merge_checks.vue';
import mergeChecksQuery from '~/vue_merge_request_widget/queries/merge_checks.query.graphql';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
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
    ${[{ identifier: 'discussions', status: 'FAILED' }]}                                             | ${'Merge blocked: 1 check failed'}
    ${[{ identifier: 'discussions', status: 'FAILED' }, { identifier: 'rebase', status: 'FAILED' }]} | ${'Merge blocked: 2 checks failed'}
    ${[{ identifier: 'discussions', status: 'WARNING' }]}                                            | ${'Merge with caution: Override added'}
  `('renders $text for $mergeabilityChecks', async ({ mergeabilityChecks, text }) => {
    mountComponent({ mergeabilityChecks });

    await waitForPromises();

    expect(wrapper.text()).toBe(text);
  });

  it.each`
    status       | statusIcon
    ${'FAILED'}  | ${'failed'}
    ${'PASSED'}  | ${'success'}
    ${'WARNING'} | ${'warning'}
  `('renders $statusIcon for $status result', async ({ status, statusIcon }) => {
    mountComponent({ mergeabilityChecks: [{ status, identifier: 'discussions' }] });

    await waitForPromises();

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(statusIcon);
  });

  it.each`
    identifier                    | componentName
    ${'conflict'}                 | ${'conflict'}
    ${'discussions_not_resolved'} | ${'discussions_not_resolved'}
    ${'need_rebase'}              | ${'need_rebase'}
  `('renders $identifier merge check', async ({ identifier, componentName }) => {
    shallowMountComponent({ mergeabilityChecks: [{ status: 'failed', identifier }] });

    wrapper.findComponent(StateContainer).vm.$emit('toggle');

    await waitForPromises();

    const { default: component } = await COMPONENTS[componentName]();

    expect(wrapper.findComponent(component).exists()).toBe(true);
  });

  it('renders ready to merge caution message when canMerge is false', async () => {
    mountComponent({
      canMerge: false,
      mergeabilityChecks: [{ status: 'WARNING', identifier: 'discussions' }],
    });

    await waitForPromises();

    expect(wrapper.text()).toBe('Ready to be merged with caution: Override added');
  });

  it('expands collapsed area', async () => {
    mountComponent();

    await waitForPromises();

    await wrapper.findByTestId('widget-toggle').trigger('click');

    expect(wrapper.findByTestId('merge-checks-full').exists()).toBe(true);
  });

  it('sorts merge checks', async () => {
    shallowMountComponent({
      mergeabilityChecks: [
        { identifier: 'discussions_not_resolved', status: 'SUCCESS' },
        { identifier: 'status_checks_must_pass', status: 'INACTIVE' },
        { identifier: 'need_rebase', status: 'FAILED' },
      ],
    });

    await waitForPromises();

    wrapper.vm.toggleCollapsed();

    expect(wrapper.vm.sortedChecks.length).toBe(2);
    expect(wrapper.vm.sortedChecks[0].status).toBe('FAILED');
    expect(wrapper.vm.sortedChecks[1].status).toBe('SUCCESS');
  });

  it('does not render check component if no message exists', async () => {
    mountComponent({
      mergeabilityChecks: [
        { identifier: 'discussions_not_resolved', status: 'SUCCESS' },
        { identifier: 'fakemessage', status: 'FAILED' },
      ],
    });

    await waitForPromises();

    await wrapper.findByTestId('widget-toggle').trigger('click');

    await waitForPromises();

    const mergeChecks = wrapper.findAllByTestId('merge-check');

    expect(mergeChecks.length).toBe(1);
  });

  describe('expansion', () => {
    const findMergeChecks = () => wrapper.findAllByTestId('merge-check');

    beforeEach(async () => {
      mountComponent({
        mergeabilityChecks: [
          { identifier: 'discussions_not_resolved', status: 'SUCCESS' },
          { identifier: 'discussions_not_resolved', status: 'INACTIVE' },
          { identifier: 'need_rebase', status: 'FAILED' },
        ],
      });

      await waitForPromises();
    });

    it('shows failed checks before user expands section', () => {
      expect(findMergeChecks().length).toBe(1);
    });

    it('shows all checks when user expands section', async () => {
      await wrapper.findByTestId('widget-toggle').trigger('click');

      expect(findMergeChecks().length).toBe(2);
    });

    it('shows failed checks when user collapses section', async () => {
      await wrapper.findByTestId('widget-toggle').trigger('click');

      expect(findMergeChecks().length).toBe(2);

      await wrapper.findByTestId('widget-toggle').trigger('click');

      expect(findMergeChecks().length).toBe(1);
    });
  });

  describe('checking merge checks', () => {
    const findMergeChecks = () => wrapper.findAllByTestId('merge-check');

    beforeEach(() => {
      mountComponent({
        mergeabilityChecks: [
          { identifier: 'discussions_not_resolved', status: 'CHECKING' },
          { identifier: 'not_approved', status: 'SUCCESS' },
        ],
      });

      return waitForPromises();
    });

    it('renders checking text', () => {
      expect(wrapper.text()).toContain('Checking if merge request can be merged...');
    });

    it('renders checks expanded by default', () => {
      expect(findMergeChecks()).toHaveLength(1);
    });
  });
});
