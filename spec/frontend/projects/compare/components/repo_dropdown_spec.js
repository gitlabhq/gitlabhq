import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { revisionCardDefaultProps as defaultProps, targetProjects } from './mock_data';

jest.mock('~/alert');
describe('RepoDropdown component', () => {
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RepoDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlCollapsibleListboxItems = () => wrapper.findAllComponents(GlListboxItem);
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
        defaultProps.selectedProject.text,
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
    beforeEach(async () => {
      axiosMock.onGet(defaultProps.endpoint).reply(HTTP_STATUS_OK, targetProjects);

      createComponent({ paramsName: 'from' });
      await waitForPromises();
    });

    it('fetches target projects on created hook', () => {
      expect(findGlCollapsibleListboxItems()).toHaveLength(targetProjects.length);
    });

    it('set hidden input of the selected project', () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProps.selectedProject.id);
    });

    it('displays matching project name of the source revision initially in the dropdown', () => {
      expect(findGlCollapsibleListbox().props('toggleText')).toBe(
        defaultProps.selectedProject.text,
      );
    });

    it('updates the hidden input value when dropdown item is selected', async () => {
      const repoId = '6';
      findGlCollapsibleListbox().vm.$emit('select', repoId);
      await nextTick();
      expect(findHiddenInput().attributes('value')).toBe(repoId);
    });

    it('emits `selectProject` event when another target project is selected', async () => {
      const repoId = '6';
      findGlCollapsibleListbox().vm.$emit('select', repoId);

      await nextTick();
      expect(wrapper.emitted('selectProject')).toEqual([
        [
          {
            direction: 'from',
            project: {
              text: 'flightjs/Flight',
              value: '6',
            },
          },
        ],
      ]);
    });

    it('searches projects', async () => {
      findGlCollapsibleListbox().vm.$emit('search', 'test');

      jest.advanceTimersByTime(500);
      await waitForPromises();

      expect(axiosMock.history.get[1].params).toEqual({ search: 'test' });
    });
  });
  describe('On request failure', () => {
    it('shows alert', async () => {
      axiosMock.onGet('some/invalid/path').replyOnce(HTTP_STATUS_NOT_FOUND);

      createComponent({ paramsName: 'from' });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
    });
  });
});
