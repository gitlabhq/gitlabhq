import { GlAvatar, GlButton, GlFormSelect, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';

describe('JiraImportForm', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(JiraImportForm);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows a dropdown to choose the Jira project to import from', () => {
    expect(wrapper.find(GlFormSelect).exists()).toBe(true);
  });

  it('shows a label which will be applied to imported Jira projects', () => {
    expect(wrapper.find(GlLabel).attributes('title')).toBe('jira-import::KEY-1');
  });

  it('shows information to the user', () => {
    expect(wrapper.find('p').text()).toBe(
      "For each Jira issue successfully imported, we'll create a new GitLab issue with the following data:",
    );
  });

  it('shows jira.issue.summary for the Title', () => {
    expect(wrapper.find('[id="jira-project-title"]').text()).toBe('jira.issue.summary');
  });

  it('shows an avatar for the Reporter', () => {
    expect(wrapper.find(GlAvatar).exists()).toBe(true);
  });

  it('shows jira.issue.description.content for the Description', () => {
    expect(wrapper.find('[id="jira-project-description"]').text()).toBe(
      'jira.issue.description.content',
    );
  });

  it('shows a Next button', () => {
    const nextButton = wrapper
      .findAll(GlButton)
      .at(0)
      .text();

    expect(nextButton).toBe('Next');
  });

  it('shows a Cancel button', () => {
    const cancelButton = wrapper
      .findAll(GlButton)
      .at(1)
      .text();

    expect(cancelButton).toBe('Cancel');
  });
});
