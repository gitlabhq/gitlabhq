import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlFormCheckbox } from '@gitlab/ui';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import * as urlUtils from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn(),
  setUrlParams: jest.fn(),
  visitUrl: jest.fn(),
}));

describe('BlamePreferences', () => {
  let wrapper;

  const createComponent = ({ hasRevsFile = true } = {}) => {
    wrapper = shallowMount(BlamePreferences, { propsData: { hasRevsFile } });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findLearnToIgnoreItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('when revs file exists', () => {
    beforeEach(() => createComponent());

    it('shows dropdown with correct text', () => {
      expect(findDropdown().props('toggleText')).toBe('Blame preferences');
    });

    it('shows checkbox with correct text', () => {
      expect(findCheckbox().text()).toBe('Ignore specific revisions');
    });

    it('shows learn more button', () => {
      expect(findLearnToIgnoreItem().text()).toBe('Learn more');
    });
  });

  describe('when revs file does not exist', () => {
    beforeEach(() => createComponent({ hasRevsFile: false }));

    it('does not show a checkbox', () => {
      expect(findCheckbox().exists()).toBe(false);
    });

    it('shows learn to ignore button', () => {
      expect(findLearnToIgnoreItem().text()).toBe('Learn to ignore specific revisions');
    });
  });

  describe('ignore revs functionality', () => {
    const mockUrl = 'mock-url?ignore_revs=true';

    beforeEach(() => {
      urlUtils.setUrlParams.mockReturnValue(mockUrl);
      createComponent();
    });

    it('updates URL when checkbox is checked', async () => {
      await findCheckbox().vm.$emit('input', true);

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(mockUrl);
      expect(findDropdown().props('loading')).toBe(true);
    });

    it('shows checked state when URL param is true', () => {
      urlUtils.getParameterByName.mockReturnValue('true');
      createComponent();

      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('shows unchecked state when URL param is false', () => {
      urlUtils.getParameterByName.mockReturnValue('false');
      createComponent();

      expect(findCheckbox().attributes('checked')).toBe('false');
    });
  });
});
