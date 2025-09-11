import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussionLocked from '~/wikis/wiki_notes/components/wiki_discussion_locked.vue';

describe('WikiDiscussionLocked', () => {
  let wrapper;

  const createWrapper = (provideData) =>
    shallowMountExtended(WikiDiscussionLocked, {
      provide: {
        isContainerArchived: false,
        containerType: 'Project',
        ...provideData,
      },
    });

  describe('renders correctly', () => {
    const shouldRenderLockIcon = () => {
      expect(wrapper.findComponent(GlIcon).props('name')).toBe('lock');
    };

    describe('when isContainerArchived is false', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should render lock icon', () => {
        shouldRenderLockIcon();
      });

      it('should render locked discussion warning', async () => {
        expect(await wrapper.text()).toContain(
          'The discussion in this Wiki is locked. Only project members can comment.',
        );
      });

      it('should not render archived project warning', async () => {
        expect(await wrapper.text()).not.toContain(
          'This project is archived and cannot be commented on.',
        );
      });
    });

    describe('when isContainerArchived is true', () => {
      beforeEach(() => {
        wrapper = createWrapper({ isContainerArchived: true });
      });
      it('should render lock icon', () => {
        shouldRenderLockIcon();
      });

      it('should not render locked discussion warning', async () => {
        expect(await wrapper.text()).not.toContain(
          'The discussion in this Wiki is locked. Only project members can comment.',
        );
      });

      it('should render archived project warning by default', async () => {
        expect(await wrapper.text()).toContain(
          'This project is archived and cannot be commented on.',
        );
      });

      it('should render archived group warning when containerType is wiki', async () => {
        wrapper = createWrapper({ isContainerArchived: true, containerType: 'group' });

        expect(await wrapper.text()).toContain(
          'This group is archived and cannot be commented on.',
        );
      });
    });
  });
});
