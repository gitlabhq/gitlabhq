import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import NoteableWarning from '~/vue_shared/components/notes/noteable_warning.vue';

describe('Issue Warning Component', () => {
  let wrapper;

  const findIcon = (w = wrapper) => w.find(GlIcon);
  const findLockedBlock = (w = wrapper) => w.find({ ref: 'locked' });
  const findConfidentialBlock = (w = wrapper) => w.find({ ref: 'confidential' });
  const findLockedAndConfidentialBlock = (w = wrapper) => w.find({ ref: 'lockedAndConfidential' });

  const createComponent = props =>
    shallowMount(NoteableWarning, {
      propsData: {
        ...props,
      },
    });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
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

      await wrapper.vm.$nextTick();
      expect(findConfidentialBlock(wrapper).text()).toContain('This is a confidential issue.');
    });

    it('renders warning icon', () => {
      expect(wrapper.find(GlIcon).exists()).toBe(true);
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
      expect(wrapper.find(GlIcon).exists()).toBe(false);
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
      wrapperLocked = createComponent({
        isLocked: true,
        isConfidential: false,
      });
      wrapperConfidential = createComponent({
        isLocked: false,
        isConfidential: true,
      });
      wrapperLockedAndConfidential = createComponent({
        isLocked: true,
        isConfidential: true,
      });
    });

    afterEach(() => {
      wrapperLocked.destroy();
      wrapperConfidential.destroy();
      wrapperLockedAndConfidential.destroy();
    });

    it('renders confidential & locked messages with noteable "issue"', () => {
      expect(findLockedBlock(wrapperLocked).text()).toContain('This issue is locked.');
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential issue.',
      );
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This issue is confidential and locked.',
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

      await wrapperLocked.vm.$nextTick();
      expect(findLockedBlock(wrapperLocked).text()).toContain('This epic is locked.');

      await wrapperConfidential.vm.$nextTick();
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential epic.',
      );

      await wrapperLockedAndConfidential.vm.$nextTick();
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This epic is confidential and locked.',
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

      await wrapperLocked.vm.$nextTick();
      expect(findLockedBlock(wrapperLocked).text()).toContain('This merge request is locked.');

      await wrapperConfidential.vm.$nextTick();
      expect(findConfidentialBlock(wrapperConfidential).text()).toContain(
        'This is a confidential merge request.',
      );

      await wrapperLockedAndConfidential.vm.$nextTick();
      expect(findLockedAndConfidentialBlock(wrapperLockedAndConfidential).text()).toContain(
        'This merge request is confidential and locked.',
      );
    });
  });
});
