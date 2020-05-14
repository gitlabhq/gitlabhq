import { shallowMount } from '@vue/test-utils';

import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';

import EditArea from '~/static_site_editor/components/edit_area.vue';
import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';
import EditHeader from '~/static_site_editor/components/edit_header.vue';

import { sourceContentTitle as title, sourceContent as content, returnUrl } from '../mock_data';

describe('~/static_site_editor/components/edit_area.vue', () => {
  let wrapper;
  const savingChanges = true;
  const newContent = `new ${content}`;

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
    expect(findRichContentEditor().props('value')).toBe(content);
  });

  it('renders publish toolbar', () => {
    expect(findPublishToolbar().exists()).toBe(true);
    expect(findPublishToolbar().props('returnUrl')).toBe(returnUrl);
    expect(findPublishToolbar().props('savingChanges')).toBe(savingChanges);
    expect(findPublishToolbar().props('saveable')).toBe(false);
  });

  describe('when content changes', () => {
    beforeEach(() => {
      findRichContentEditor().vm.$emit('input', newContent);

      return wrapper.vm.$nextTick();
    });

    it('sets publish toolbar as saveable when content changes', () => {
      expect(findPublishToolbar().props('saveable')).toBe(true);
    });

    it('sets publish toolbar as not saveable when content changes are rollback', () => {
      findRichContentEditor().vm.$emit('input', content);

      return wrapper.vm.$nextTick().then(() => {
        expect(findPublishToolbar().props('saveable')).toBe(false);
      });
    });
  });
});
