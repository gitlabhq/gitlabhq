import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarConfidentialityContent from '~/sidebar/components/confidential/sidebar_confidentiality_content.vue';

describe('Sidebar Confidentiality Content', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findText = () => wrapper.find('[data-testid="confidential-text"]');

  const createComponent = (confidential = false) => {
    wrapper = shallowMount(SidebarConfidentialityContent, {
      propsData: {
        confidential,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when issue is non-confidential', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a non-confidential icon', () => {
      expect(findIcon().props('name')).toBe('eye');
    });

    it('does not add `is-active` class to the icon', () => {
      expect(findIcon().classes()).not.toContain('is-active');
    });

    it('displays a non-confidential text', () => {
      expect(findText().text()).toBe('Not confidential');
    });
  });

  describe('when issue is confidential', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('renders a non-confidential icon', () => {
      expect(findIcon().props('name')).toBe('eye-slash');
    });

    it('does not add `is-active` class to the icon', () => {
      expect(findIcon().classes()).toContain('is-active');
    });

    it('displays a non-confidential text', () => {
      expect(findText().text()).toBe('This  is confidential');
    });
  });
});
