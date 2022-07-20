import { mount } from '@vue/test-utils';
import { GlAlert, GlLink } from '@gitlab/ui';
import WorkItemInformation from '~/work_items/components/work_item_information.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

const createComponent = () => mount(WorkItemInformation);

describe('Work item information alert', () => {
  let wrapper;
  const tasksHelpPath = helpPagePath('user/tasks');
  const workItemsHelpPath = helpPagePath('development/work_items');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should be visible', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('should emit `work-item-banner-dismissed` event when cross icon is clicked', () => {
    findAlert().vm.$emit('dismiss');
    expect(wrapper.emitted('work-item-banner-dismissed').length).toBe(1);
  });

  it('the alert variant should be tip', () => {
    expect(findAlert().props('variant')).toBe('tip');
  });

  it('should have the correct text for primary button and link', () => {
    expect(findAlert().props('title')).toBe(WorkItemInformation.i18n.tasksInformationTitle);
    expect(findAlert().props('primaryButtonText')).toBe(
      WorkItemInformation.i18n.learnTasksButtonText,
    );
    expect(findAlert().props('primaryButtonLink')).toBe(tasksHelpPath);
  });

  it('should have the correct link to work item link', () => {
    expect(findHelpLink().exists()).toBe(true);
    expect(findHelpLink().attributes('href')).toBe(workItemsHelpPath);
  });
});
