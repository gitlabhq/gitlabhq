import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';

const defaultProps = {
  paramsName: 'to',
};

const projectToId = '1';
const projectToName = 'some-to-name';
const projectFromId = '2';
const projectFromName = 'some-from-name';

const defaultProvide = {
  projectTo: { id: projectToId, name: projectToName },
  projectsFrom: [
    { id: projectFromId, name: projectFromName },
    { id: 3, name: 'some-from-another-name' },
  ],
};

describe('RepoDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMount(RepoDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  describe('Source Revision', () => {
    beforeEach(() => {
      createComponent();
    });

    it('set hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(projectToId);
    });

    it('displays the project name in the disabled dropdown', () => {
      expect(findGlDropdown().props('text')).toBe(projectToName);
      expect(findGlDropdown().props('disabled')).toBe(true);
    });

    it('does not emit `changeTargetProject` event', async () => {
      wrapper.vm.emitTargetProject('foo');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('changeTargetProject')).toBeUndefined();
    });
  });

  describe('Target Revision', () => {
    beforeEach(() => {
      createComponent({ paramsName: 'from' });
    });

    it('set hidden input of the selected project', () => {
      expect(findHiddenInput().attributes('value')).toBe(projectToId);
    });

    it('displays matching project name of the source revision initially in the dropdown', () => {
      expect(findGlDropdown().props('text')).toBe(projectToName);
    });

    it('updates the hiddin input value when onClick method is triggered', async () => {
      const repoId = '100';
      wrapper.vm.onClick({ id: repoId });
      await wrapper.vm.$nextTick();
      expect(findHiddenInput().attributes('value')).toBe(repoId);
    });

    it('emits `changeTargetProject` event when another target project is selected', async () => {
      const index = 1;
      const { projectsFrom } = defaultProvide;
      findGlDropdown().findAll(GlDropdownItem).at(index).vm.$emit('click');
      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('changeTargetProject')[0][0]).toEqual(projectsFrom[index].name);
    });
  });
});
