import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';
import { revisionCardDefaultProps as defaultProps } from './mock_data';

describe('RepoDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RepoDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
        GlListboxItem,
      },
    });
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  describe('Source Revision', () => {
    beforeEach(() => {
      createComponent();
    });

    it('set hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProps.selectedProject.id);
    });

    it('displays the project name in the disabled dropdown', () => {
      expect(findGlCollapsibleListbox().props('toggleText')).toBe(
        defaultProps.selectedProject.name,
      );
      expect(findGlCollapsibleListbox().props('disabled')).toBe(true);
    });

    it('does not emit `changeTargetProject` event', async () => {
      wrapper.vm.emitTargetProject('foo');
      await nextTick();
      expect(wrapper.emitted('changeTargetProject')).toBeUndefined();
    });
  });

  describe('Target Revision', () => {
    beforeEach(() => {
      const projects = [
        {
          name: 'some-to-name',
          id: '1',
        },
      ];

      createComponent({ paramsName: 'from', projects });
    });

    it('set hidden input of the selected project', () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProps.selectedProject.id);
    });

    it('displays matching project name of the source revision initially in the dropdown', () => {
      expect(findGlCollapsibleListbox().props('toggleText')).toBe(
        defaultProps.selectedProject.name,
      );
    });

    it('updates the hidden input value when dropdown item is selected', () => {
      const repoId = '1';
      findGlCollapsibleListbox().vm.$emit('select', repoId);
      expect(findHiddenInput().attributes('value')).toBe(repoId);
    });

    it('emits `selectProject` event when another target project is selected', async () => {
      const repoId = '1';
      findGlCollapsibleListbox().vm.$emit('select', repoId);

      await nextTick();

      expect(wrapper.emitted('selectProject')[0][0]).toEqual({
        direction: 'from',
        project: { id: '1', name: 'some-to-name' },
      });
    });
  });
});
