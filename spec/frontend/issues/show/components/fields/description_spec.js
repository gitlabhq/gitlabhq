import { shallowMount } from '@vue/test-utils';
import DescriptionField from '~/issues/show/components/fields/description.vue';
import eventHub from '~/issues/show/event_hub';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('Description field component', () => {
  let wrapper;
  let trackingSpy;

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const mountComponent = ({ description = 'test' } = {}) => {
    wrapper = shallowMount(DescriptionField, {
      attachTo: document.body,
      propsData: {
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        value: description,
      },
      stubs: {
        MarkdownField,
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
    jest.spyOn(eventHub, '$emit');

    mountComponent();
  });

  it('uses the MarkdownEditor component to edit markdown', () => {
    expect(findMarkdownEditor().props()).toMatchObject({
      value: 'test',
      renderMarkdownPath: '/',
      autofocus: true,
      supportsQuickActions: true,
      markdownDocsPath: '/',
      enableAutocomplete: true,
    });
  });

  describe.each`
    testDescription                 | metaKey  | ctrlKey
    ${'when meta+enter is pressed'} | ${true}  | ${false}
    ${'when ctrl+enter is pressed'} | ${false} | ${true}
  `('$testDescription', ({ metaKey, ctrlKey }) => {
    beforeEach(() => {
      findMarkdownEditor().vm.$emit('keydown', {
        type: 'keydown',
        keyCode: 13,
        metaKey,
        ctrlKey,
      });
    });

    it('triggers update', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith('update.issuable');
    });

    it('tracks event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
        label: 'markdown_editor',
        property: 'Issue',
      });
    });
  });

  it('emits input event when MarkdownEditor emits input event', () => {
    const markdown = 'markdown';

    findMarkdownEditor().vm.$emit('input', markdown);

    expect(wrapper.emitted('input')).toEqual([[markdown]]);
  });
});
