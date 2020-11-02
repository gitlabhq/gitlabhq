import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import EditMetaModal from '~/static_site_editor/components/edit_meta_modal.vue';
import EditMetaControls from '~/static_site_editor/components/edit_meta_controls.vue';
import { MR_META_LOCAL_STORAGE_KEY } from '~/static_site_editor/constants';
import { sourcePath, mergeRequestMeta, mergeRequestTemplates } from '../mock_data';

describe('~/static_site_editor/components/edit_meta_modal.vue', () => {
  useLocalStorageSpy();

  let wrapper;
  let resetCachedEditable;
  let mockEditMetaControlsInstance;
  const { title, description } = mergeRequestMeta;

  const buildWrapper = (propsData = {}, data = {}) => {
    wrapper = shallowMount(EditMetaModal, {
      propsData: {
        sourcePath,
        ...propsData,
      },
      data: () => data,
    });
  };

  const buildMocks = () => {
    resetCachedEditable = jest.fn();
    mockEditMetaControlsInstance = { resetCachedEditable };
    wrapper.vm.$refs.editMetaControls = mockEditMetaControlsInstance;
  };

  const findGlModal = () => wrapper.find(GlModal);
  const findEditMetaControls = () => wrapper.find(EditMetaControls);
  const findLocalStorageSync = () => wrapper.find(LocalStorageSync);

  beforeEach(() => {
    localStorage.setItem(MR_META_LOCAL_STORAGE_KEY);
  });

  beforeEach(() => {
    buildWrapper();
    buildMocks();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('initializes initial merge request meta with local storage data', async () => {
    const localStorageMeta = {
      title: 'stored title',
      description: 'stored description',
      templates: null,
      currentTemplate: null,
    };

    findLocalStorageSync().vm.$emit('input', localStorageMeta);

    await wrapper.vm.$nextTick();

    expect(findEditMetaControls().props()).toEqual(localStorageMeta);
  });

  it('renders the modal', () => {
    expect(findGlModal().exists()).toBe(true);
  });

  it('renders the edit meta controls', () => {
    expect(findEditMetaControls().exists()).toBe(true);
  });

  it('contains the sourcePath in the title', () => {
    expect(findEditMetaControls().props('title')).toContain(sourcePath);
  });

  it('forwards the title prop', () => {
    expect(findEditMetaControls().props('title')).toBe(title);
  });

  it('forwards the description prop', () => {
    expect(findEditMetaControls().props('description')).toBe(description);
  });

  it('forwards the templates prop', () => {
    expect(findEditMetaControls().props('templates')).toBe(null);
  });

  it('forwards the currentTemplate prop', () => {
    expect(findEditMetaControls().props('currentTemplate')).toBe(null);
  });

  describe('when save button is clicked', () => {
    beforeEach(() => {
      findGlModal().vm.$emit('primary', mergeRequestMeta);
    });

    it('removes merge request meta from local storage', () => {
      expect(findLocalStorageSync().props().clear).toBe(true);
    });

    it('emits the primary event with mergeRequestMeta', () => {
      expect(wrapper.emitted('primary')).toEqual([[mergeRequestMeta]]);
    });
  });

  describe('when templates exist', () => {
    const template1 = mergeRequestTemplates[0];

    beforeEach(() => {
      buildWrapper({}, { templates: mergeRequestTemplates, currentTemplate: null });
    });

    it('sets the currentTemplate on the changeTemplate event', async () => {
      findEditMetaControls().vm.$emit('changeTemplate', template1);

      await wrapper.vm.$nextTick();

      expect(findEditMetaControls().props().currentTemplate).toBe(template1);

      findEditMetaControls().vm.$emit('changeTemplate', null);

      await wrapper.vm.$nextTick();

      expect(findEditMetaControls().props().currentTemplate).toBe(null);
    });

    it('updates the description on the changeTemplate event', async () => {
      findEditMetaControls().vm.$emit('changeTemplate', template1);

      await wrapper.vm.$nextTick();

      expect(findEditMetaControls().props().description).toEqual(template1.content);
    });
  });

  it('emits the hide event', () => {
    findGlModal().vm.$emit('hide');
    expect(wrapper.emitted('hide')).toEqual([[]]);
  });

  it('stores merge request meta changes in local storage when changes happen', async () => {
    const newMeta = { title: 'new title', description: 'new description' };

    findEditMetaControls().vm.$emit('updateSettings', newMeta);

    await wrapper.vm.$nextTick();

    expect(findLocalStorageSync().props('value')).toEqual(newMeta);
  });
});
