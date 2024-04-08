import { GlButton, GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CodeDropdownItem from '~/vue_shared/components/code_dropdown/code_dropdown_item.vue';

describe('CodeDropdownItem', () => {
  let wrapper;
  const link = 'ssh://foo.bar';
  const label = 'SSH';
  const testId = 'some-selector';
  const defaultPropsData = {
    link,
    label,
    testId,
  };

  const findCopyButton = () => wrapper.findComponent(GlButton);

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CodeDropdownItem, {
      propsData,
      stubs: {
        GlFormInputGroup,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('default', () => {
    it('sets form group label', () => {
      expect(wrapper.findComponent(GlFormGroup).attributes('label')).toBe(label);
    });

    it('sets form input group label', () => {
      expect(wrapper.findComponent(GlFormInputGroup).props('label')).toBe(label);
    });

    it('sets form input group link', () => {
      expect(wrapper.findComponent(GlFormInputGroup).props('value')).toBe(link);
    });

    it('sets the copy tooltip text', () => {
      expect(findCopyButton().attributes('title')).toBe('Copy URL');
    });

    it('sets the copy tooltip link', () => {
      expect(findCopyButton().attributes('data-clipboard-text')).toBe(link);
    });

    it('sets the qa selector', () => {
      expect(findCopyButton().attributes('data-testid')).toBe(testId);
    });
  });
});
