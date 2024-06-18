import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NewBranchForm from '~/jira_connect/branches/components/new_branch_form.vue';
import {
  I18N_PAGE_TITLE_WITH_BRANCH_NAME,
  I18N_PAGE_TITLE_DEFAULT,
} from '~/jira_connect/branches/constants';
import JiraConnectNewBranchPage from '~/jira_connect/branches/pages/index.vue';
import { sprintf } from '~/locale';

describe('NewBranchForm', () => {
  let wrapper;

  const findPageTitle = () => wrapper.find('h1');
  const findNewBranchForm = () => wrapper.findComponent(NewBranchForm);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  function createComponent({ provide } = {}) {
    wrapper = shallowMount(JiraConnectNewBranchPage, {
      provide: {
        initialBranchName: '',
        successStateSvgPath: '',
        ...provide,
      },
    });
  }

  describe('page title', () => {
    it.each`
      initialBranchName    | pageTitle
      ${undefined}         | ${I18N_PAGE_TITLE_DEFAULT}
      ${'ap1-test-button'} | ${sprintf(I18N_PAGE_TITLE_WITH_BRANCH_NAME, { jiraIssue: 'ap1-test-button' })}
    `(
      'sets page title to "$pageTitle" when initial branch name is "$initialBranchName"',
      ({ initialBranchName, pageTitle }) => {
        createComponent({ provide: { initialBranchName } });

        expect(findPageTitle().text()).toBe(pageTitle);
      },
    );
  });

  it('renders NewBranchForm by default', () => {
    createComponent();

    expect(findNewBranchForm().exists()).toBe(true);
    expect(findEmptyState().exists()).toBe(false);
  });

  describe('when `success` event emitted from NewBranchForm', () => {
    it('renders the success state', async () => {
      createComponent();

      const newBranchForm = findNewBranchForm();
      await newBranchForm.vm.$emit('success');

      expect(findNewBranchForm().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});
