import { mount } from '@vue/test-utils';
import { GlAlert, GlLink } from '@gitlab/ui';
import WorkItemInformation from '~/work_items/components/work_item_information.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

const createComponent = () => mount(WorkItemInformation);

describe('Work item information alert', () => {
  let wrapper;
  const tasksHelpPath = helpPagePath('user/tasks');

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

  it('should have the correct text for title', () => {
    expect(findAlert().props('title')).toBe(WorkItemInformation.i18n.tasksInformationTitle);
  });

  it('should have the correct link to work item link', () => {
    expect(findHelpLink().exists()).toBe(true);
    expect(findHelpLink().attributes('href')).toBe(tasksHelpPath);
  });
});
