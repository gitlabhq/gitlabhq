import { mount, shallowMount } from '@vue/test-utils';
import { GlNewDropdown, GlNewDropdownItem, GlForm } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import PipelineNewForm from '~/pipeline_new/components/pipeline_new_form.vue';
import { mockRefs, mockParams, mockPostParams, mockProjectId } from '../mock_data';
import { redirectTo } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
}));

const pipelinesPath = '/root/project/-/pipleines';
const postResponse = { id: 1 };

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;

  const dummySubmitEvent = {
    preventDefault() {},
  };

  const findForm = () => wrapper.find(GlForm);
  const findDropdown = () => wrapper.find(GlNewDropdown);
  const findDropdownItems = () => wrapper.findAll(GlNewDropdownItem);
  const findVariableRows = () => wrapper.findAll('[data-testid="ci-variable-row"]');
  const findRemoveIcons = () => wrapper.findAll('[data-testid="remove-ci-variable-row"]');
  const findKeyInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-key"]');
  const getExpectedPostParams = () => JSON.parse(mock.history.post[0].data);

  const createComponent = (term = '', props = {}, method = shallowMount) => {
    wrapper = method(PipelineNewForm, {
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        refs: mockRefs,
        defaultBranch: 'master',
        settingsLink: '',
        ...props,
      },
      data() {
        return {
          searchTerm: term,
        };
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onPost(pipelinesPath).reply(200, postResponse);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('Dropdown with branches and tags', () => {
    it('displays dropdown with all branches and tags', () => {
      createComponent();
      expect(findDropdownItems()).toHaveLength(mockRefs.length);
    });

    it('when user enters search term the list is filtered', () => {
      createComponent('master');

      expect(findDropdownItems()).toHaveLength(1);
      expect(
        findDropdownItems()
          .at(0)
          .text(),
      ).toBe('master');
    });
  });

  describe('Form', () => {
    beforeEach(() => {
      createComponent('', mockParams, mount);
    });
    it('displays the correct values for the provided query params', async () => {
      expect(findDropdown().props('text')).toBe('tag-1');

      await wrapper.vm.$nextTick();

      expect(findVariableRows()).toHaveLength(3);
    });

    it('does not display remove icon for last row', () => {
      expect(findRemoveIcons()).toHaveLength(2);
    });

    it('removes ci variable row on remove icon button click', async () => {
      findRemoveIcons()
        .at(1)
        .trigger('click');

      await wrapper.vm.$nextTick();

      expect(findVariableRows()).toHaveLength(2);
    });

    it('creates a pipeline on submit', async () => {
      findForm().vm.$emit('submit', dummySubmitEvent);

      await waitForPromises();

      expect(getExpectedPostParams()).toEqual(mockPostParams);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${postResponse.id}`);
    });

    it('creates blank variable on input change event', async () => {
      findKeyInputs()
        .at(2)
        .trigger('change');

      await wrapper.vm.$nextTick();

      expect(findVariableRows()).toHaveLength(4);
    });
  });
});
