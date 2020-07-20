import Api from '~/api';
import { mount, shallowMount } from '@vue/test-utils';
import PipelineNewForm from '~/pipeline_new/components/pipeline_new_form.vue';
import { GlNewDropdown, GlNewDropdownItem, GlForm } from '@gitlab/ui';
import { mockRefs, mockParams, mockPostParams, mockProjectId } from '../mock_data';

describe('Pipeline New Form', () => {
  let wrapper;

  const dummySubmitEvent = {
    preventDefault() {},
  };

  const findForm = () => wrapper.find(GlForm);
  const findDropdown = () => wrapper.find(GlNewDropdown);
  const findDropdownItems = () => wrapper.findAll(GlNewDropdownItem);
  const findVariableRows = () => wrapper.findAll('[data-testid="ci-variable-row"]');
  const findRemoveIcons = () => wrapper.findAll('[data-testid="remove-ci-variable-row"]');
  const findKeyInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-key"]');

  const createComponent = (term = '', props = {}, method = shallowMount) => {
    wrapper = method(PipelineNewForm, {
      propsData: {
        projectId: mockProjectId,
        pipelinesPath: '',
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
    jest.spyOn(Api, 'createPipeline').mockResolvedValue({ data: { web_url: '/' } });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Dropdown with branches and tags', () => {
    it('displays dropdown with all branches and tags', () => {
      createComponent();
      expect(findDropdownItems().length).toBe(mockRefs.length);
    });

    it('when user enters search term the list is filtered', () => {
      createComponent('master');

      expect(findDropdownItems().length).toBe(1);
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
    it('displays the correct values for the provided query params', () => {
      expect(findDropdown().props('text')).toBe('tag-1');

      return wrapper.vm.$nextTick().then(() => {
        expect(findVariableRows().length).toBe(3);
      });
    });

    it('does not display remove icon for last row', () => {
      expect(findRemoveIcons().length).toBe(2);
    });

    it('removes ci variable row on remove icon button click', () => {
      findRemoveIcons()
        .at(1)
        .trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(findVariableRows().length).toBe(2);
      });
    });

    it('creates a pipeline on submit', () => {
      findForm().vm.$emit('submit', dummySubmitEvent);

      expect(Api.createPipeline).toHaveBeenCalledWith(mockProjectId, mockPostParams);
    });

    it('creates blank variable on input change event', () => {
      findKeyInputs()
        .at(2)
        .trigger('change');

      return wrapper.vm.$nextTick().then(() => {
        expect(findVariableRows().length).toBe(4);
      });
    });
  });
});
