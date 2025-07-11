import { GlDrawer, GlAccordion, GlAccordionItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ManageExclusionsDrawer from '~/pages/projects/shared/permissions/components/manage_exclusions_drawer.vue';

const defaultProps = {
  open: true,
  exclusionRules: ['*.log', 'node_modules/', 'secrets.json'],
};

describe('ManageExclusionsDrawer', () => {
  let wrapper;

  const mountComponent = (props = {}, mountFn = mountExtended) => {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    return mountFn(ManageExclusionsDrawer, {
      propsData,
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findTextarea = () => wrapper.findByTestId('exclusion-rules-textarea');
  const findSaveButton = () => wrapper.findByTestId('save-exclusions-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const findAccordionItem = () => wrapper.findComponent(GlAccordionItem);

  beforeEach(() => {
    wrapper = mountComponent();
  });

  describe('rendering', () => {
    it('renders the drawer with correct props', () => {
      const drawer = findDrawer();

      expect(drawer.exists()).toBe(true);
      expect(drawer.props('open')).toBe(true);
    });

    it('renders the correct title', () => {
      expect(wrapper.text()).toContain('Manage Exclusions');
    });

    it('renders the textarea with correct label', () => {
      const textarea = findTextarea();

      expect(textarea.exists()).toBe(true);
      expect(wrapper.text()).toContain('Files or directories');
    });

    it('renders save and cancel buttons', () => {
      expect(findSaveButton().exists()).toBe(true);
      expect(findCancelButton().exists()).toBe(true);
      expect(findSaveButton().text()).toBe('Save exclusions');
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders the examples accordion', () => {
      const accordion = findAccordion();
      const accordionItem = findAccordionItem();

      expect(accordion.exists()).toBe(true);
      expect(accordionItem.exists()).toBe(true);
      expect(accordionItem.props('title')).toBe('View examples of exclusions.');
    });
  });

  describe('data initialization', () => {
    it('initializes local rules from props', () => {
      expect(wrapper.vm.localRules).toBe('*.log\nnode_modules/\nsecrets.json');
    });

    it('handles empty exclusion rules', () => {
      wrapper = mountComponent({ exclusionRules: [] });
      expect(wrapper.vm.localRules).toBe('');
    });

    it('updates local rules when exclusion rules prop changes', async () => {
      const newRules = ['*.tmp', 'build/'];
      await wrapper.setProps({ exclusionRules: newRules });

      expect(wrapper.vm.localRules).toBe('*.tmp\nbuild/');
    });

    it('resets local rules when drawer opens', async () => {
      // Change local rules
      wrapper.vm.localRules = 'modified content';

      // Close and open drawer
      await wrapper.setProps({ open: false });
      await wrapper.setProps({ open: true });

      expect(wrapper.vm.localRules).toBe('*.log\nnode_modules/\nsecrets.json');
    });
  });

  describe('user interactions', () => {
    it('updates local rules when textarea content changes', async () => {
      const textarea = findTextarea();
      const newContent = '*.tmp\nbuild/\ndist/';

      await textarea.setValue(newContent);

      expect(wrapper.vm.localRules).toBe(newContent);
    });

    it('emits save event with parsed rules when save button is clicked', async () => {
      const textarea = findTextarea();
      await textarea.setValue('*.tmp\n\nbuild/\n  \ndist/\n');

      await findSaveButton().trigger('click');

      expect(wrapper.emitted('save')).toHaveLength(1);
      expect(wrapper.emitted('save')[0][0]).toEqual(['*.tmp', 'build/', 'dist/']);
    });

    it('filters out empty lines and trims whitespace when saving', async () => {
      const textarea = findTextarea();
      await textarea.setValue('  *.tmp  \n\n  build/  \n\n  \n  dist/  \n');

      await findSaveButton().trigger('click');

      expect(wrapper.emitted('save')[0][0]).toEqual(['*.tmp', 'build/', 'dist/']);
    });

    it('emits close event when cancel button is clicked', async () => {
      await findCancelButton().trigger('click');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('resets local rules to original when cancel is clicked', async () => {
      const textarea = findTextarea();
      await textarea.setValue('modified content');

      await findCancelButton().trigger('click');

      expect(wrapper.vm.localRules).toBe('*.log\nnode_modules/\nsecrets.json');
    });

    it('emits close event when drawer close event is triggered', async () => {
      const drawer = findDrawer();

      await drawer.vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });

  describe('examples accordion', () => {
    it('shows example patterns when accordion is expanded', () => {
      const accordionContent = wrapper.text();

      // Check for example descriptions
      expect(accordionContent).toContain('Excludes all .env files');
      expect(accordionContent).toContain('Excludes entire secrets directory');
      expect(accordionContent).toContain('Excludes all .key files in any subdirectory');
      expect(accordionContent).toContain('Excludes the specified file');
      expect(accordionContent).toContain(
        'Allows the specified file in the specified directory, even if excluded by previous rules',
      );
    });

    it('includes specific example patterns', () => {
      const accordionContent = wrapper.text();

      // Check for specific examples
      expect(accordionContent).toContain('*.env');
      expect(accordionContent).toContain('secrets/');
      expect(accordionContent).toContain('**/*.key');
      expect(accordionContent).toContain('config/production.yml');
      expect(accordionContent).toContain('!secrets/file.json');
    });
  });

  describe('drawer visibility', () => {
    it('shows drawer when open prop is true', () => {
      wrapper = mountComponent({ open: true });

      expect(findDrawer().props('open')).toBe(true);
    });

    it('hides drawer when open prop is false', () => {
      wrapper = mountComponent({ open: false });

      expect(findDrawer().props('open')).toBe(false);
    });
  });

  describe('edge cases', () => {
    it('handles single rule correctly', () => {
      wrapper = mountComponent({ exclusionRules: ['single-rule.txt'] });

      expect(wrapper.vm.localRules).toBe('single-rule.txt');
    });

    it('handles rules with special characters', () => {
      const specialRules = ['*.log', 'path/with spaces/', 'file-with-dashes.txt'];
      wrapper = mountComponent({ exclusionRules: specialRules });

      expect(wrapper.vm.localRules).toBe('*.log\npath/with spaces/\nfile-with-dashes.txt');
    });

    it('saves empty rules array when textarea is empty', async () => {
      const textarea = findTextarea();
      await textarea.setValue('');

      await findSaveButton().trigger('click');

      expect(wrapper.emitted('save')[0][0]).toEqual([]);
    });

    it('saves empty rules array when textarea contains only whitespace', async () => {
      const textarea = findTextarea();
      await textarea.setValue('   \n\n  \n  ');

      await findSaveButton().trigger('click');

      expect(wrapper.emitted('save')[0][0]).toEqual([]);
    });
  });

  describe('accessibility', () => {
    it('has proper form labels', () => {
      const label = wrapper.find('label[for="exclusion-rules-textarea"]');
      expect(label.exists()).toBe(true);
      expect(label.text()).toContain('Files or directories');
    });

    it('provides help text for the textarea', () => {
      expect(wrapper.text()).toContain('Add each exclusion on a separate line.');
    });
  });
});
