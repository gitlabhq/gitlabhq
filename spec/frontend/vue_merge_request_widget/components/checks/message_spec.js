import { mountExtended } from 'helpers/vue_test_utils_helper';
import MessageComponent from '~/vue_merge_request_widget/components/checks/message.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = mountExtended(MessageComponent, {
    propsData,
  });
}

describe('Merge request merge checks message component', () => {
  it.each`
    identifier                      | expectedText
    ${'commits_status'}             | ${'Source branch exists and contains commits.'}
    ${'ci_must_pass'}               | ${'Pipeline must succeed.'}
    ${'conflict'}                   | ${'Merge conflicts must be resolved.'}
    ${'discussions_not_resolved'}   | ${'Unresolved discussions must be resolved.'}
    ${'draft_status'}               | ${'Merge request must not be draft.'}
    ${'not_open'}                   | ${'Merge request must be open.'}
    ${'need_rebase'}                | ${'Merge request must be rebased, because a fast-forward merge is not possible.'}
    ${'not_approved'}               | ${'All required approvals must be given.'}
    ${'merge_request_blocked'}      | ${'Merge request dependencies must be merged.'}
    ${'status_checks_must_pass'}    | ${'Status checks must pass.'}
    ${'jira_association_missing'}   | ${'Either the title or description must reference a Jira issue.'}
    ${'requested_changes'}          | ${'The change requests must be completed or resolved.'}
    ${'approvals_syncing'}          | ${'The merge request approvals are currently syncing.'}
    ${'locked_paths'}               | ${'All paths must be unlocked'}
    ${'locked_lfs_files'}           | ${'All LFS files must be unlocked.'}
    ${'security_policy_violations'} | ${'All policy rules must be satisfied.'}
  `('renders failure reason text', ({ identifier, expectedText }) => {
    factory({ check: { status: 'success', identifier } });

    expect(wrapper.text()).toBe(expectedText);
  });

  it.each`
    status        | icon
    ${'success'}  | ${'success'}
    ${'failed'}   | ${'failed'}
    ${'inactive'} | ${'neutral'}
  `('renders $icon icon for $status result', ({ status, icon }) => {
    factory({ check: { status, identifier: 'discussions_not_resolved' } });

    expect(wrapper.findComponent(StatusIcon).props('iconName')).toBe(icon);
  });

  it('renders loading icon when status is CHECKING', () => {
    factory({ check: { status: 'CHECKING', identifier: 'discussions_not_resolved' } });

    expect(wrapper.findByTestId('checking-icon').exists()).toBe(true);
  });
});
