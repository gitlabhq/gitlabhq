import { shallowMount } from '@vue/test-utils';

import { GlFormInput, GlFormTextarea } from '@gitlab/ui';

import EditMetaControls from '~/static_site_editor/components/edit_meta_controls.vue';

import { mergeRequestMeta } from '../mock_data';

describe('~/static_site_editor/components/edit_meta_controls.vue', () => {
  let wrapper;
  let mockSelect;
  let mockGlFormInputTitleInstance;
  const { title, description } = mergeRequestMeta;
  const newTitle = 'New title';
  const newDescription = 'New description';

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditMetaControls, {
      propsData: {
        title,
        description,
        ...propsData,
      },
    });
  };

  const buildMocks = () => {
    mockSelect = jest.fn();
    mockGlFormInputTitleInstance = { $el: { select: mockSelect } };
    wrapper.vm.$refs.title = mockGlFormInputTitleInstance;
  };

  const findGlFormInputTitle = () => wrapper.find(GlFormInput);
  const findGlFormTextAreaDescription = () => wrapper.find(GlFormTextarea);

  beforeEach(() => {
    buildWrapper();
    buildMocks();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the title input', () => {
    expect(findGlFormInputTitle().exists()).toBe(true);
  });

  it('renders the description input', () => {
    expect(findGlFormTextAreaDescription().exists()).toBe(true);
  });

  it('forwards the title prop to the title input', () => {
    expect(findGlFormInputTitle().attributes().value).toBe(title);
  });

  it('forwards the description prop to the description input', () => {
    expect(findGlFormTextAreaDescription().attributes().value).toBe(description);
  });

  it('calls select on the title input when mounted', () => {
    expect(mockGlFormInputTitleInstance.$el.select).toHaveBeenCalled();
  });

  describe('when inputs change', () => {
    const storageKey = 'sse-merge-request-meta-local-storage-editable';

    afterEach(() => {
      localStorage.removeItem(storageKey);
    });

    it.each`
      findFn                           | key              | value
      ${findGlFormInputTitle}          | ${'title'}       | ${newTitle}
      ${findGlFormTextAreaDescription} | ${'description'} | ${newDescription}
    `('emits updated settings when $findFn input updates', ({ key, value, findFn }) => {
      findFn().vm.$emit('input', value);

      const newSettings = { ...mergeRequestMeta, [key]: value };

      expect(wrapper.emitted('updateSettings')[0][0]).toMatchObject(newSettings);
    });
  });
});
