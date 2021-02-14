import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import axios from '~/lib/utils/axios_utils';
import EditMetaControls from '~/static_site_editor/components/edit_meta_controls.vue';
import EditMetaModal from '~/static_site_editor/components/edit_meta_modal.vue';
import { MR_META_LOCAL_STORAGE_KEY } from '~/static_site_editor/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  sourcePath,
  mergeRequestMeta,
  mergeRequestTemplates,
  project as namespaceProject,
} from '../mock_data';

describe('~/static_site_editor/components/edit_meta_modal.vue', () => {
  useLocalStorageSpy();

  let wrapper;
  let mockAxios;
  const { title, description } = mergeRequestMeta;
  const [namespace, project] = namespaceProject.split('/');

  const buildWrapper = (propsData = {}, data = {}) => {
    wrapper = shallowMount(EditMetaModal, {
      propsData: {
        sourcePath,
        namespace,
        project,
        ...propsData,
      },
      data: () => data,
    });
  };

  const buildMockAxios = () => {
    mockAxios = new MockAdapter(axios);
    const templatesMergeRequestsPath = `templates/merge_request`;
    mockAxios
      .onGet(`${namespace}/${project}/${templatesMergeRequestsPath}`)
      .reply(200, mergeRequestTemplates);
  };

  const buildMockRefs = () => {
    wrapper.vm.$refs.editMetaControls = { resetCachedEditable: jest.fn() };
  };

  const findGlModal = () => wrapper.find(GlModal);
  const findEditMetaControls = () => wrapper.find(EditMetaControls);
  const findLocalStorageSync = () => wrapper.find(LocalStorageSync);

  beforeEach(() => {
    localStorage.setItem(MR_META_LOCAL_STORAGE_KEY);

    buildMockAxios();
    buildWrapper();
    buildMockRefs();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    mockAxios.restore();

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
