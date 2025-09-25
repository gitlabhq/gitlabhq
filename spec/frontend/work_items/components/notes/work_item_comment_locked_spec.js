import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';

describe('WorkItemCommentLocked', () => {
  let wrapper;

  const createComponent = ({ workItemType = 'Task' } = {}) => {
    wrapper = shallowMount(WorkItemCommentLocked, {
      propsData: {
        workItemType,
      },
    });
  };

  const findLockedIcon = () => wrapper.findComponent(GlIcon);
  const findLearnMoreLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders the locked icon', () => {
    expect(findLockedIcon().props('name')).toBe('lock');
  });

  it('renders text', () => {
    expect(wrapper.text()).toMatchInterpolatedText(
      'The discussion in this task is locked. Only project members can comment. Learn more.',
    );
  });

  it('renders learn more link which links to locked discussions docs path', () => {
    expect(findLearnMoreLink().attributes('href')).toBe(
      WorkItemCommentLocked.constantOptions.lockedIssueDocsPath,
    );
  });
});
