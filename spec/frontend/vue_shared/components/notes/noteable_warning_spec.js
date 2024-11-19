import { GlIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';

describe('Issue Warning Component', () => {
  let wrapper;

  const findIcon = (w = wrapper) => w.findComponent(GlIcon);
  const findLockedBlock = (w = wrapper) => w.findComponent({ ref: 'locked' });
  const findConfidentialBlock = (w = wrapper) => w.findComponent({ ref: 'confidential' });
  const findLockedAndConfidentialBlock = (w = wrapper) =>
    w.findComponent({ ref: 'lockedAndConfidential' });

  const createComponent = (props, mountFn = shallowMount) =>
    mountFn(NoteableWarning, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });

  describe('when issue is locked but not confidential', () => {
    beforeEach(() => {
      wrapper = createComponent({
        isLocked: true,
        lockedNoteableDocsPath: 'locked-path',
        isConfidential: false,
      });
    });

    it('renders information about locked issue', () => {
      expect(findLockedBlock().exists()).toBe(true);
      expect(findLockedBlock().element).toMatchSnapshot();
    });

    it('renders warning icon', () => {
      expect(findIcon().exists()).toBe(true);
    });

    it('does not render information about locked and confidential issue', () => {
      expect(findLockedAndConfidentialBlock().exists()).toBe(false);
    });

    it('does not render information about confidential issue', () => {
      expect(findConfidentialBlock().exists()).toBe(false);
    });
  });

  describe('when noteable is confidential but not locked', () => {
    beforeEach(() => {
      wrapper = createComponent({
        isLocked: false,
        isConfidential: true,
        confidentialNoteableDocsPath: 'confidential-path',
      });
    });

    it('renders information about confidential issue', async () => {
      expect(findConfidentialBlock().exists()).toBe(true);
      expect(findConfidentialBlock().element).toMatchSnapshot();

      await nextTick();
      expect(findConfidentialBlock(wrapper).text()).toContain('This is a confidential issue.');
    });

    it('renders warning icon', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
    });

    it('does not render information about locked noteable', () => {
      expect(findLockedBlock().exists()).toBe(false);
    });

    it('does not render information about locked and confidential noteable', () => {
      expect(findLockedAndConfidentialBlock().exists()).toBe(false);
    });
  });

  describe('when noteable is locked and confidential', () => {
    beforeEach(() => {
      wrapper = createComponent({
        isLocked: true,
        isConfidential: true,
      });
    });

    it('renders information about locked and confidential noteable', () => {
      expect(findLockedAndConfidentialBlock().exists()).toBe(true);
      expect(findLockedAndConfidentialBlock().element).toMatchSnapshot();
    });

    it('does not render warning icon', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });

    it('does not render information about locked noteable', () => {
      expect(findLockedBlock().exists()).toBe(false);
    });

    it('does not render information about confidential noteable', () => {
      expect(findConfidentialBlock().exists()).toBe(false);
    });
  });

  describe('when noteableType prop is defined', () => {
    let wrapperLocked;
    let wrapperConfidential;
    let wrapperLockedAndConfidential;

    beforeEach(() => {
      wrapperLocked = createComponent(
        {
          isLocked: true,
          isConfidential: false,
        },
        mount,
      );
      wrapperConfidential = createComponent(
        {
          isLocked: false,
          isConfidential: true,
        },
        mount,
      );
      wrapperLockedAndConfidential = createComponent(
        {
          isLocked: true,
          isConfidential: true,
        },
        mount,
      );
    });

    it('renders confidential & locked messages with noteable "issue"', () => {
      expect(findLockedBlock(wrapperLocked).text()).toContain(
        'The discussion in this issue is locked.',
      );
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential issue.',
      );
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This issue is confidential and its discussion is locked.',
      );
    });

    it('renders confidential & locked messages with noteable "epic"', async () => {
      wrapperLocked.setProps({
        noteableType: 'Epic',
      });
      wrapperConfidential.setProps({
        noteableType: 'Epic',
      });
      wrapperLockedAndConfidential.setProps({
        noteableType: 'Epic',
      });

      await nextTick();

      expect(findLockedBlock(wrapperLocked).text()).toContain(
        'The discussion in this epic is locked.',
      );

      await nextTick();
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential epic.',
      );

      await nextTick();
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This epic is confidential and its discussion is locked.',
      );
    });

    it('renders confidential & locked messages with noteable "merge request"', async () => {
      wrapperLocked.setProps({
        noteableType: 'MergeRequest',
      });
      wrapperConfidential.setProps({
        noteableType: 'MergeRequest',
      });
      wrapperLockedAndConfidential.setProps({
        noteableType: 'MergeRequest',
      });

      await nextTick();
      expect(findLockedBlock(wrapperLocked).text()).toContain(
        'The discussion in this merge request is locked.',
      );

      await nextTick();
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential merge request.',
      );

      await nextTick();
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This merge request is confidential and its discussion is locked.',
      );
    });
  });
});
