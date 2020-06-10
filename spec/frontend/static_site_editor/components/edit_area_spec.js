import { shallowMount } from '@vue/test-utils';

import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';

import EditArea from '~/static_site_editor/components/edit_area.vue';
import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';
import EditHeader from '~/static_site_editor/components/edit_header.vue';
import UnsavedChangesConfirmDialog from '~/static_site_editor/components/unsaved_changes_confirm_dialog.vue';

import {
  sourceContentTitle as title,
  sourceContent as content,
  sourceContentBody as body,
  returnUrl,
} from '../mock_data';

describe('~/static_site_editor/components/edit_area.vue', () => {
  let wrapper;
  const savingChanges = true;
  const newBody = `new ${body}`;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditArea, {
      propsData: {
        title,
        content,
        returnUrl,
        savingChanges,
        ...propsData,
      },
    });
  };

  const findEditHeader = () => wrapper.find(EditHeader);
  const findRichContentEditor = () => wrapper.find(RichContentEditor);
  const findPublishToolbar = () => wrapper.find(PublishToolbar);
  const findUnsavedChangesConfirmDialog = () => wrapper.find(UnsavedChangesConfirmDialog);

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders edit header', () => {
    expect(findEditHeader().exists()).toBe(true);
    expect(findEditHeader().props('title')).toBe(title);
  });

  it('renders rich content editor', () => {
    expect(findRichContentEditor().exists()).toBe(true);
    expect(findRichContentEditor().props('value')).toBe(body);
  });

  it('renders publish toolbar', () => {
    expect(findPublishToolbar().exists()).toBe(true);
    expect(findPublishToolbar().props()).toMatchObject({
      returnUrl,
      savingChanges,
      saveable: false,
    });
  });

  it('renders unsaved changes confirm dialog', () => {
    expect(findUnsavedChangesConfirmDialog().exists()).toBe(true);
    expect(findUnsavedChangesConfirmDialog().props('modified')).toBe(false);
  });

  describe('when content changes', () => {
    beforeEach(() => {
      findRichContentEditor().vm.$emit('input', newBody);

      return wrapper.vm.$nextTick();
    });

    it('sets publish toolbar as saveable', () => {
      expect(findPublishToolbar().props('saveable')).toBe(true);
    });

    it('sets unsaved changes confirm dialog as modified', () => {
      expect(findUnsavedChangesConfirmDialog().props('modified')).toBe(true);
    });

    it('sets publish toolbar as not saveable when content changes are rollback', () => {
      findRichContentEditor().vm.$emit('input', body);

      return wrapper.vm.$nextTick().then(() => {
        expect(findPublishToolbar().props('saveable')).toBe(false);
      });
    });
  });
});
