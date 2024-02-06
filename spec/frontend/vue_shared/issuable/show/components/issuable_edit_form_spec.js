import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import IssuableEditForm from '~/vue_shared/issuable/show/components/issuable_edit_form.vue';
import IssuableEventHub from '~/vue_shared/issuable/show/event_hub';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import MarkdownToolbar from '~/vue_shared/components/markdown/toolbar.vue';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import Autosave from '~/autosave';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

jest.mock('~/autosave');

const issuableEditFormProps = {
  issuable: mockIssuable,
  ...mockIssuableShowProps,
};

const createComponent = ({ propsData = issuableEditFormProps } = {}) =>
  shallowMount(IssuableEditForm, {
    propsData,
    stubs: {
      MarkdownEditor,
      MarkdownField,
      MarkdownToolbar,
      EditorModeSwitcher,
    },
    slots: {
      'edit-form-actions': `
        <button class="js-save">Save changes</button>
        <button class="js-cancel">Cancel</button>
      `,
    },
  });

describe('IssuableEditForm', () => {
  let wrapper;
  const assertEvent = (eventSpy) => {
    expect(eventSpy).toHaveBeenNthCalledWith(1, 'update.issuable', expect.any(Function));
    expect(eventSpy).toHaveBeenNthCalledWith(2, 'close.form', expect.any(Function));
  };

  beforeEach(() => {
    wrapper = createComponent();
    jest.spyOn(Autosave.prototype, 'reset');
  });

  afterEach(() => {
    // note: the order of wrapper.destroy() and jest.resetAllMocks() matters.
    // maybe it'll help with investigation on how to remove this wrapper.destroy() call
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
    jest.resetAllMocks();
  });

  describe('watch', () => {
    describe('issuable', () => {
      it('sets title and description to `issuable.title` and `issuable.description` when those values are available', async () => {
        wrapper.setProps({
          issuable: {
            ...issuableEditFormProps.issuable,
            title: 'Foo',
            description: 'Foobar',
          },
        });

        await nextTick();

        expect(wrapper.vm.title).toBe('Foo');
        expect(wrapper.vm.description).toBe('Foobar');
      });

      it('sets title and description to empty string when `issuable.title` and `issuable.description` is unavailable', async () => {
        wrapper.setProps({
          issuable: {
            ...issuableEditFormProps.issuable,
            title: null,
            description: null,
          },
        });

        await nextTick();

        expect(wrapper.vm.title).toBe('');
        expect(wrapper.vm.description).toBe('');
      });
    });
  });

  describe('created', () => {
    it('binds `update.issuable` and `close.form` event listeners', () => {
      const eventOnSpy = jest.spyOn(IssuableEventHub, '$on');
      const wrapperTemp = createComponent();

      assertEvent(eventOnSpy);

      wrapperTemp.destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `update.issuable` and `close.form` event listeners', () => {
      const wrapperTemp = createComponent();
      const eventOffSpy = jest.spyOn(IssuableEventHub, '$off');

      wrapperTemp.destroy();

      assertEvent(eventOffSpy);
    });
  });

  describe('methods', () => {
    describe('initAutosave', () => {
      it('initializes autosave', () => {
        expect(Autosave.mock.calls).toEqual([[expect.any(Element), ['/', '', 'title']]]);
      });
    });

    describe('resetAutosave', () => {
      it('resets title on "update.issuable event"', () => {
        const clearDescriptionAutosaveSpy = jest.fn();
        markdownEditorEventHub.$on(CLEAR_AUTOSAVE_ENTRY_EVENT, clearDescriptionAutosaveSpy);

        IssuableEventHub.$emit('update.issuable');
        expect(Autosave.prototype.reset).toHaveBeenCalled();
        expect(clearDescriptionAutosaveSpy).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders title input field', () => {
      const titleInputEl = wrapper.find('[data-testid="title"]');

      expect(titleInputEl.exists()).toBe(true);
      expect(titleInputEl.findComponent(GlFormInput).attributes()).toMatchObject({
        'aria-label': 'Title',
        placeholder: 'Title',
      });
    });

    it('renders description textarea field', () => {
      const descriptionEl = wrapper.find('[data-testid="description"]');

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.findComponent(MarkdownField).props()).toMatchObject({
        markdownPreviewPath: issuableEditFormProps.descriptionPreviewPath,
        markdownDocsPath: issuableEditFormProps.descriptionHelpPath,
        enableAutocomplete: issuableEditFormProps.enableAutocomplete,
        textareaValue: mockIssuable.description,
      });
      expect(descriptionEl.find('textarea').attributes()).toMatchObject({
        'data-supports-quick-actions': 'true',
        'aria-label': 'Description',
        placeholder: 'Write a comment or drag your files here…',
      });
    });

    it('allows switching to rich text editor', () => {
      const descriptionEl = wrapper.find('[data-testid="description"]');

      expect(descriptionEl.text()).toContain('Switch to rich text editing');
    });

    it('renders form actions', () => {
      const actionsEl = wrapper.find('[data-testid="actions"]');

      expect(actionsEl.find('button.js-save').exists()).toBe(true);
      expect(actionsEl.find('button.js-cancel').exists()).toBe(true);
    });

    describe('events', () => {
      const eventObj = {
        preventDefault: jest.fn(),
        stopPropagation: jest.fn(),
      };

      it('component emits `keydown-title` event with event object and issuableMeta params via gl-form-input', () => {
        const titleInputEl = wrapper.findComponent(GlFormInput);

        titleInputEl.vm.$emit('keydown', eventObj, 'title');
        expect(wrapper.emitted('keydown-title')).toHaveLength(1);
        expect(wrapper.emitted('keydown-title')[0]).toMatchObject([
          eventObj,
          {
            issuableTitle: wrapper.vm.title,
            issuableDescription: wrapper.vm.description,
          },
        ]);
      });

      it('component emits `keydown-description` event with event object and issuableMeta params via textarea', () => {
        const descriptionInputEl = wrapper.find('[data-testid="description"] textarea');

        descriptionInputEl.trigger('keydown', eventObj, 'description');
        expect(wrapper.emitted('keydown-description')).toHaveLength(1);
        expect(wrapper.emitted('keydown-description')[0]).toMatchObject([
          eventObj,
          {
            issuableTitle: wrapper.vm.title,
            issuableDescription: wrapper.vm.description,
          },
        ]);
      });
    });
  });
});
