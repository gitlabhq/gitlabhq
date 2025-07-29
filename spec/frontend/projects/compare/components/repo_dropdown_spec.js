import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import RepoDropdown from '~/projects/compare/components/repo_dropdown.vue';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { revisionCardDefaultProps as defaultProps } from './mock_data';

jest.mock('~/alert');

describe('RepoDropdown component', () => {
  let wrapper;
  let mock;

  const createComponent = (props = {}, status = HTTP_STATUS_OK) => {
    mock = new MockAdapter(axios);

    mock.onGet('/target_projects').reply(status, props.projects || []);

    wrapper = shallowMount(RepoDropdown, {
      provide: {
        targetProjectsPath: '/target_projects',
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  describe('Source Revision', () => {
    beforeEach(() => {
      createComponent({ disabled: true });
    });

    afterEach(() => {
      mock.restore();
    });

    it('set hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe(defaultProps.selectedProject.value);
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
    describe('when target projects request succeeds', () => {
      beforeEach(async () => {
        const projects = [
          {
            full_name: 'some-to-name',
            id: '1',
          },
        ];

        createComponent({ paramsName: 'from', projects });

        await waitForPromises();
      });

      it('set hidden input of the selected project', () => {
        expect(findHiddenInput().attributes('value')).toBe(defaultProps.selectedProject.value);
      });

      it('displays matching project name of the source revision initially in the dropdown', () => {
        expect(findGlCollapsibleListbox().props('toggleText')).toBe(
          defaultProps.selectedProject.text,
        );
      });

      it('updates the hidden input value when dropdown item is selected', () => {
        const repoId = '1';
        findGlCollapsibleListbox().vm.$emit('select', repoId);
        expect(findHiddenInput().attributes('value')).toBe(repoId);
      });

      it('emits `selectProject` event when another target project is selected', async () => {
        findGlCollapsibleListbox().vm.$emit('select', '1');

        await nextTick();

        expect(wrapper.emitted().selectProject).toEqual([
          [
            {
              direction: 'from',
              project: { full_name: 'some-to-name', id: '1', text: 'some-to-name', value: '1' },
            },
          ],
        ]);
      });

      it('sets items on drodpown to projects from API', () => {
        expect(findGlCollapsibleListbox().props('items')).toEqual([
          {
            full_name: 'some-to-name',
            id: '1',
            value: '1',
            text: 'some-to-name',
          },
        ]);
      });

      it('searches projects from search event', async () => {
        findGlCollapsibleListbox().vm.$emit('search', 'Test project');

        await waitForPromises();

        expect(mock.history.get.at(-1)).toEqual(
          expect.objectContaining({
            params: { search: 'Test project' },
          }),
        );
      });
    });
  });

  describe('when target projects request fails', () => {
    beforeEach(async () => {
      createComponent({ paramsName: 'from' }, HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await waitForPromises();
    });

    it('calls createAlert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.anything(),
        message: 'An error occurred while retrieving target projects.',
      });
    });
  });
});
