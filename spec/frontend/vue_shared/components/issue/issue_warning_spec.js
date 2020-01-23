import { shallowMount } from '@vue/test-utils';
import IssueWarning from '~/vue_shared/components/issue/issue_warning.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('Issue Warning Component', () => {
  let wrapper;

  const findIcon = () => wrapper.find(Icon);
  const findLockedBlock = () => wrapper.find({ ref: 'locked' });
  const findConfidentialBlock = () => wrapper.find({ ref: 'confidential' });
  const findLockedAndConfidentialBlock = () => wrapper.find({ ref: 'lockedAndConfidential' });

  const createComponent = props => {
    wrapper = shallowMount(IssueWarning, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when issue is locked but not confidential', () => {
    beforeEach(() => {
      createComponent({
        isLocked: true,
        lockedIssueDocsPath: 'locked-path',
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

  describe('when issue is confidential but not locked', () => {
    beforeEach(() => {
      createComponent({
        isLocked: false,
        isConfidential: true,
        confidentialIssueDocsPath: 'confidential-path',
      });
    });

    it('renders information about confidential issue', () => {
      expect(findConfidentialBlock().exists()).toBe(true);
      expect(findConfidentialBlock().element).toMatchSnapshot();
    });

    it('renders warning icon', () => {
      expect(wrapper.find(Icon).exists()).toBe(true);
    });

    it('does not render information about locked issue', () => {
      expect(findLockedBlock().exists()).toBe(false);
    });

    it('does not render information about locked and confidential issue', () => {
      expect(findLockedAndConfidentialBlock().exists()).toBe(false);
    });
  });

  describe('when issue is locked and confidential', () => {
    beforeEach(() => {
      createComponent({
        isLocked: true,
        isConfidential: true,
      });
    });

    it('renders information about locked and confidential issue', () => {
      expect(findLockedAndConfidentialBlock().exists()).toBe(true);
      expect(findLockedAndConfidentialBlock().element).toMatchSnapshot();
    });

    it('does not render warning icon', () => {
      expect(wrapper.find(Icon).exists()).toBe(false);
    });

    it('does not render information about locked issue', () => {
      expect(findLockedBlock().exists()).toBe(false);
    });

    it('does not render information about confidential issue', () => {
      expect(findConfidentialBlock().exists()).toBe(false);
    });
  });
});
