import { shallowMount } from '@vue/test-utils';
import DescriptionField from '~/issues/show/components/fields/description.vue';
import eventHub from '~/issues/show/event_hub';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';

describe('Description field component', () => {
  let wrapper;

  const findTextarea = () => wrapper.findComponent({ ref: 'textarea' });
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);

  const mountComponent = ({ description = 'test', contentEditorOnIssues = false } = {}) =>
    shallowMount(DescriptionField, {
      attachTo: document.body,
      propsData: {
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        quickActionsDocsPath: '/',
        value: description,
      },
      provide: {
        glFeatures: {
          contentEditorOnIssues,
        },
      },
      stubs: {
        MarkdownField,
      },
    });

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit');
  });

  it('renders markdown field with description', () => {
    wrapper = mountComponent();

    expect(findTextarea().element.value).toBe('test');
  });

  it('renders markdown field with a markdown description', () => {
    const markdown = '**test**';

    wrapper = mountComponent({ description: markdown });

    expect(findTextarea().element.value).toBe(markdown);
  });

  it('focuses field when mounted', () => {
    wrapper = mountComponent();

    expect(document.activeElement).toBe(findTextarea().element);
  });

  it('triggers update with meta+enter', () => {
    wrapper = mountComponent();

    findTextarea().trigger('keydown.enter', { metaKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });

  it('triggers update with ctrl+enter', () => {
    wrapper = mountComponent();

    findTextarea().trigger('keydown.enter', { ctrlKey: true });

    expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
  });

  describe('when contentEditorOnIssues feature flag is on', () => {
    beforeEach(() => {
      wrapper = mountComponent({ contentEditorOnIssues: true });
    });

    it('uses the MarkdownEditor component to edit markdown', () => {
      expect(findMarkdownEditor().props()).toMatchObject({
        value: 'test',
        renderMarkdownPath: '/',
        autofocus: true,
        supportsQuickActions: true,
        quickActionsDocsPath: expect.any(String),
        markdownDocsPath: '/',
        enableAutocomplete: true,
      });
    });

    it('triggers update with meta+enter', () => {
      findMarkdownEditor().vm.$emit('keydown', {
        type: 'keydown',
        keyCode: 13,
        metaKey: true,
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
    });

    it('triggers update with ctrl+enter', () => {
      findMarkdownEditor().vm.$emit('keydown', {
        type: 'keydown',
        keyCode: 13,
        ctrlKey: true,
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
    });

    it('emits input event when MarkdownEditor emits input event', () => {
      const markdown = 'markdown';

      findMarkdownEditor().vm.$emit('input', markdown);

      expect(wrapper.emitted('input')).toEqual([[markdown]]);
    });
  });
});
