import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';

const createComponent = ({ workItemType = 'Task', isProjectArchived = false } = {}) =>
  shallowMount(WorkItemCommentLocked, {
    propsData: {
      workItemType,
      isProjectArchived,
    },
  });

describe('WorkItemCommentLocked', () => {
  let wrapper;
  const findLockedIcon = () => wrapper.findComponent(GlIcon);
  const findLearnMoreLink = () => wrapper.findComponent(GlLink);

  it('renders the locked icon', () => {
    wrapper = createComponent();
    expect(findLockedIcon().props('name')).toBe('lock');
  });

  it('has the learn more link', () => {
    wrapper = createComponent();
    expect(findLearnMoreLink().attributes('href')).toBe(
      WorkItemCommentLocked.constantOptions.lockedIssueDocsPath,
    );
  });

  describe('when the project is archived', () => {
    beforeEach(() => {
      wrapper = createComponent({ isProjectArchived: true });
    });

    it('learn more link is directed to archived project docs path', () => {
      expect(findLearnMoreLink().attributes('href')).toBe(
        WorkItemCommentLocked.constantOptions.archivedProjectDocsPath,
      );
    });
  });
});
