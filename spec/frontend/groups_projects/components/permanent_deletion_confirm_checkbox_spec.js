import { GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PermanentDeletionConfirmCheckbox from '~/groups_projects/components/permanent_deletion_confirm_checkbox.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

describe('PermanentDeletionConfirmCheckbox', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PermanentDeletionConfirmCheckbox, {
      propsData: {
        resourceType: RESOURCE_TYPES.PROJECT,
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findLink = () => wrapper.findComponent(GlLink);

  it('renders checkbox component', () => {
    createComponent();

    expect(findCheckbox().exists()).toBe(true);
  });

  it('renders link to export help page', () => {
    createComponent();

    expect(findLink().exists()).toBe(true);
    expect(findLink().attributes('target')).toBe('_blank');
  });

  describe('when resourceType is project', () => {
    beforeEach(() => {
      createComponent({ resourceType: RESOURCE_TYPES.PROJECT });
    });

    it('renders project-specific message', () => {
      const expectedText = `This action permanently deletes this project and all its data. Your administrator cannot restore it. View data export options.`;
      const expectedHelpPath =
        '/help/user/project/settings/import_export#export-a-project-and-its-data';

      expect(findCheckbox().text().replace(/\s+/g, ' ')).toContain(expectedText);
      expect(findLink().attributes('href')).toBe(expectedHelpPath);
    });
  });

  describe('when resourceType is group', () => {
    beforeEach(() => {
      createComponent({ resourceType: RESOURCE_TYPES.GROUP });
    });

    it('renders group-specific message', () => {
      const expectedText = `This action permanently deletes this group and all its data. Your administrator cannot restore it. View data export options.`;
      const expectedHelpPath = '/help/user/project/settings/import_export#export-a-group';

      expect(findCheckbox().text().replace(/\s+/g, ' ')).toContain(expectedText);
      expect(findLink().attributes('href')).toBe(expectedHelpPath);
    });
  });

  describe('when checked prop is true', () => {
    it('sets initial checked state', () => {
      createComponent({ checked: true });

      expect(findCheckbox().props('checked')).toBe(true);
    });
  });

  describe('when checked prop is not provided', () => {
    it('defaults checked state to false', () => {
      createComponent();

      expect(findCheckbox().props('checked')).toBe(false);
    });
  });

  describe('when checkbox is toggled', () => {
    it('emits change event with true', () => {
      createComponent();

      findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('change')).toEqual([[true]]);
    });

    it('emits change event with false', () => {
      createComponent({ checked: true });

      findCheckbox().vm.$emit('input', false);

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });
});
