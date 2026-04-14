import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';

describe('WorkItemCommentLocked', () => {
  let wrapper;

  const createComponent = ({ workItemType = 'Task' } = {}) => {
    wrapper = shallowMount(WorkItemCommentLocked, {
      propsData: {
        workItemType,
      },
      stubs: {
        GlSprintf,
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
      'Discussion is locked. Only members can comment.',
    );
  });

  it('renders learn more link which links to locked discussions docs path', () => {
    expect(findLearnMoreLink().attributes('href')).toBe(
      '/help/user/discussions/_index.md#prevent-comments-by-locking-the-discussion',
    );
  });
});
