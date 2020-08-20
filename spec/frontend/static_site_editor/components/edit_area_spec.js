import { shallowMount } from '@vue/test-utils';

import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import { EDITOR_TYPES } from '~/vue_shared/components/rich_content_editor/constants';

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

jest.mock('~/static_site_editor/services/formatter', () => jest.fn(str => `${str} format-pass`));

describe('~/static_site_editor/components/edit_area.vue', () => {
  let wrapper;
  const formattedBody = `${body} format-pass`;
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

  it('renders rich content editor with a format pass', () => {
    expect(findRichContentEditor().exists()).toBe(true);
    expect(findRichContentEditor().props('content')).toBe(formattedBody);
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

    it('updates parsedSource with new content', () => {
      const newContent = 'New content';
      const spySyncParsedSource = jest.spyOn(wrapper.vm.parsedSource, 'sync');

      findRichContentEditor().vm.$emit('input', newContent);

      expect(spySyncParsedSource).toHaveBeenCalledWith(newContent, true);
    });

    it('sets publish toolbar as saveable', () => {
      expect(findPublishToolbar().props('saveable')).toBe(true);
    });

    it('sets unsaved changes confirm dialog as modified', () => {
      expect(findUnsavedChangesConfirmDialog().props('modified')).toBe(true);
    });

    it('sets publish toolbar as not saveable when content changes are rollback', () => {
      findRichContentEditor().vm.$emit('input', formattedBody);

      return wrapper.vm.$nextTick().then(() => {
        expect(findPublishToolbar().props('saveable')).toBe(false);
      });
    });
  });

  describe('when the mode changes', () => {
    let resetInitialValue;

    const setInitialMode = mode => {
      wrapper.setData({ editorMode: mode });
    };

    const buildResetInitialValue = () => {
      resetInitialValue = jest.fn();
      findRichContentEditor().setMethods({ resetInitialValue });
    };

    afterEach(() => {
      setInitialMode(EDITOR_TYPES.wysiwyg);
      resetInitialValue = null;
    });

    it.each`
      initialMode              | targetMode               | resetValue
      ${EDITOR_TYPES.wysiwyg}  | ${EDITOR_TYPES.markdown} | ${`${content} format-pass format-pass`}
      ${EDITOR_TYPES.markdown} | ${EDITOR_TYPES.wysiwyg}  | ${`${body} format-pass format-pass`}
    `(
      'sets editorMode from $initialMode to $targetMode',
      ({ initialMode, targetMode, resetValue }) => {
        setInitialMode(initialMode);
        buildResetInitialValue();

        findRichContentEditor().vm.$emit('modeChange', targetMode);

        expect(resetInitialValue).toHaveBeenCalledWith(resetValue);
        expect(wrapper.vm.editorMode).toBe(targetMode);
      },
    );

    it('should format the content', () => {
      buildResetInitialValue();

      findRichContentEditor().vm.$emit('modeChange', EDITOR_TYPES.markdown);

      expect(resetInitialValue).toHaveBeenCalledWith(`${content} format-pass format-pass`);
    });
  });

  describe('when content is submitted', () => {
    it('should format the content', () => {
      findPublishToolbar().vm.$emit('submit', content);

      expect(wrapper.emitted('submit')[0][0].content).toBe(`${content} format-pass format-pass`);
    });
  });
});
