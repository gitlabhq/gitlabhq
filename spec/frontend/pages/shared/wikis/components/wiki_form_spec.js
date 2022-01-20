import { nextTick } from 'vue';
import { GlLoadingIcon, GlModal, GlAlert, GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { mockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import WikiForm from '~/pages/shared/wikis/components/wiki_form.vue';
import {
  CONTENT_EDITOR_LOADED_ACTION,
  SAVED_USING_CONTENT_EDITOR_ACTION,
  WIKI_CONTENT_EDITOR_TRACKING_LABEL,
  WIKI_FORMAT_LABEL,
  WIKI_FORMAT_UPDATED_ACTION,
} from '~/pages/shared/wikis/constants';

import MarkdownField from '~/vue_shared/components/markdown/field.vue';

jest.mock('~/emoji');

describe('WikiForm', () => {
  let wrapper;
  let mock;
  let trackingSpy;

  const findForm = () => wrapper.find('form');
  const findTitle = () => wrapper.find('#wiki_title');
  const findFormat = () => wrapper.find('#wiki_format');
  const findContent = () => wrapper.find('#wiki_content');
  const findMessage = () => wrapper.find('#wiki_message');
  const findSubmitButton = () => wrapper.findByTestId('wiki-submit-button');
  const findCancelButton = () => wrapper.findByTestId('wiki-cancel-button');
  const findUseNewEditorButton = () => wrapper.findByText('Use the new editor');
  const findToggleEditingModeButton = () => wrapper.findByTestId('toggle-editing-mode-button');
  const findDismissContentEditorAlertButton = () => wrapper.findByText('Try this later');
  const findSwitchToOldEditorButton = () =>
    wrapper.findByRole('button', { name: 'Switch me back to the classic editor.' });
  const findTitleHelpLink = () => wrapper.findByText('Learn more.');
  const findMarkdownHelpLink = () => wrapper.findByTestId('wiki-markdown-help-link');
  const findContentEditor = () => wrapper.findComponent(ContentEditor);
  const findClassicEditor = () => wrapper.findComponent(MarkdownField);

  const setFormat = (value) => {
    const format = findFormat();

    return format.find(`option[value=${value}]`).setSelected();
  };

  const triggerFormSubmit = () => {
    findForm().element.dispatchEvent(new Event('submit'));

    return nextTick();
  };

  const dispatchBeforeUnload = () => {
    const e = new Event('beforeunload');
    jest.spyOn(e, 'preventDefault');
    window.dispatchEvent(e);
    return e;
  };

  const pageInfoNew = {
    persisted: false,
    uploadsPath: '/project/path/-/wikis/attachments',
    wikiPath: '/project/path/-/wikis',
    helpPath: '/help/user/project/wiki/index',
    markdownHelpPath: '/help/user/markdown',
    markdownPreviewPath: '/project/path/-/wikis/.md/preview-markdown',
    createPath: '/project/path/-/wikis/new',
  };

  const pageInfoPersisted = {
    ...pageInfoNew,
    persisted: true,
    title: 'My page',
    content: '  My page content  ',
    format: 'markdown',
    path: '/project/path/-/wikis/home',
  };

  const formatOptions = {
    Markdown: 'markdown',
    RDoc: 'rdoc',
    AsciiDoc: 'asciidoc',
    Org: 'org',
  };

  function createWrapper({
    mountFn = shallowMount,
    persisted = false,
    pageInfo,
    glFeatures = { wikiSwitchBetweenContentEditorRawMarkdown: false },
  } = {}) {
    wrapper = extendedWrapper(
      mountFn(WikiForm, {
        provide: {
          formatOptions,
          glFeatures,
          pageInfo: {
            ...(persisted ? pageInfoPersisted : pageInfoNew),
            ...pageInfo,
          },
        },
        stubs: {
          MarkdownField,
          GlAlert,
          GlButton,
        },
      }),
    );
  }

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  it.each`
    title                | persisted | message
    ${'my page'}         | ${false}  | ${'Create my page'}
    ${'my-page'}         | ${false}  | ${'Create my page'}
    ${'somedir/my-page'} | ${false}  | ${'Create somedir/my page'}
    ${'my-page'}         | ${true}   | ${'Update my page'}
  `(
    'updates the commit message to $message when title is $title and persisted=$persisted',
    async ({ title, message, persisted }) => {
      createWrapper({ persisted });

      await findTitle().setValue(title);

      expect(findMessage().element.value).toBe(message);
    },
  );

  it('sets the commit message to "Update My page" when the page first loads when persisted', async () => {
    createWrapper({ persisted: true });

    await nextTick();

    expect(findMessage().element.value).toBe('Update My page');
  });

  it('does not trim page content by default', () => {
    createWrapper({ persisted: true });

    expect(findContent().element.value).toBe('  My page content  ');
  });

  it.each`
    value         | text
    ${'markdown'} | ${'[Link Title](page-slug)'}
    ${'rdoc'}     | ${'{Link title}[link:page-slug]'}
    ${'asciidoc'} | ${'link:page-slug[Link title]'}
    ${'org'}      | ${'[[page-slug]]'}
  `('updates the link help message when format=$value is selected', async ({ value, text }) => {
    createWrapper({ mountFn: mount });

    await setFormat(value);

    expect(wrapper.text()).toContain(text);
  });

  it('starts with no unload warning', () => {
    createWrapper();

    const e = dispatchBeforeUnload();
    expect(typeof e.returnValue).not.toBe('string');
    expect(e.preventDefault).not.toHaveBeenCalled();
  });

  it.each`
    persisted | titleHelpText                                                                                              | titleHelpLink
    ${true}   | ${'You can move this page by adding the path to the beginning of the title.'}                              | ${'/help/user/project/wiki/index#move-a-wiki-page'}
    ${false}  | ${'You can specify the full path for the new file. We will automatically create any missing directories.'} | ${'/help/user/project/wiki/index#create-a-new-wiki-page'}
  `(
    'shows appropriate title help text and help link for when persisted=$persisted',
    ({ persisted, titleHelpLink, titleHelpText }) => {
      createWrapper({ persisted });

      expect(wrapper.text()).toContain(titleHelpText);
      expect(findTitleHelpLink().attributes().href).toBe(titleHelpLink);
    },
  );

  it('shows correct link for wiki specific markdown docs', () => {
    createWrapper({ mountFn: mount });

    expect(findMarkdownHelpLink().attributes().href).toBe(
      '/help/user/markdown#wiki-specific-markdown',
    );
  });

  describe('when wiki content is updated', () => {
    beforeEach(async () => {
      createWrapper({ mountFn: mount, persisted: true });

      const input = findContent();

      await input.setValue(' Lorem ipsum dolar sit! ');
    });

    it('sets before unload warning', () => {
      const e = dispatchBeforeUnload();

      expect(e.preventDefault).toHaveBeenCalledTimes(1);
    });

    describe('form submit', () => {
      beforeEach(async () => {
        await triggerFormSubmit();
      });

      it('when form submitted, unsets before unload warning', () => {
        const e = dispatchBeforeUnload();
        expect(e.preventDefault).not.toHaveBeenCalled();
      });

      it('triggers wiki format tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledTimes(1);
      });

      it('does not trim page content', () => {
        expect(findContent().element.value).toBe(' Lorem ipsum dolar sit! ');
      });
    });
  });

  describe('submit button state', () => {
    it.each`
      title          | content        | buttonState   | disabledAttr
      ${'something'} | ${'something'} | ${'enabled'}  | ${false}
      ${''}          | ${'something'} | ${'disabled'} | ${true}
      ${'something'} | ${''}          | ${'disabled'} | ${true}
      ${''}          | ${''}          | ${'disabled'} | ${true}
      ${'   '}       | ${'   '}       | ${'disabled'} | ${true}
    `(
      "when title='$title', content='$content', then the button is $buttonState'",
      async ({ title, content, disabledAttr }) => {
        createWrapper();

        await findTitle().setValue(title);
        await findContent().setValue(content);

        expect(findSubmitButton().props().disabled).toBe(disabledAttr);
      },
    );

    it.each`
      persisted | buttonLabel
      ${true}   | ${'Save changes'}
      ${false}  | ${'Create page'}
    `('when persisted=$persisted, label is set to $buttonLabel', ({ persisted, buttonLabel }) => {
      createWrapper({ persisted });

      expect(findSubmitButton().text()).toBe(buttonLabel);
    });
  });

  describe('cancel button state', () => {
    it.each`
      persisted | redirectLink
      ${false}  | ${'/project/path/-/wikis'}
      ${true}   | ${'/project/path/-/wikis/home'}
    `(
      'when persisted=$persisted, redirects the user to appropriate path',
      ({ persisted, redirectLink }) => {
        createWrapper({ persisted });

        expect(findCancelButton().attributes().href).toBe(redirectLink);
      },
    );
  });

  describe('when wikiSwitchBetweenContentEditorRawMarkdown feature flag is not enabled', () => {
    beforeEach(() => {
      createWrapper({
        glFeatures: { wikiSwitchBetweenContentEditorRawMarkdown: false },
      });
    });

    it('hides toggle editing mode button', () => {
      expect(findToggleEditingModeButton().exists()).toBe(false);
    });
  });

  describe('when wikiSwitchBetweenContentEditorRawMarkdown feature flag is enabled', () => {
    beforeEach(() => {
      createWrapper({
        glFeatures: { wikiSwitchBetweenContentEditorRawMarkdown: true },
      });
    });

    it('hides gl-alert containing "use new editor" button', () => {
      expect(findUseNewEditorButton().exists()).toBe(false);
    });

    it('displays toggle editing mode button', () => {
      expect(findToggleEditingModeButton().exists()).toBe(true);
    });

    describe('when content editor is not active', () => {
      it('displays "Edit rich text" label in the toggle editing mode button', () => {
        expect(findToggleEditingModeButton().text()).toBe('Edit rich text');
      });

      describe('when clicking the toggle editing mode button', () => {
        beforeEach(() => {
          findToggleEditingModeButton().vm.$emit('click');
        });

        it('hides the classic editor', () => {
          expect(findClassicEditor().exists()).toBe(false);
        });

        it('hides the content editor', () => {
          expect(findContentEditor().exists()).toBe(true);
        });
      });
    });

    describe('when content editor is active', () => {
      let mockContentEditor;

      beforeEach(() => {
        mockContentEditor = {
          getSerializedContent: jest.fn(),
          setSerializedContent: jest.fn(),
        };

        findToggleEditingModeButton().vm.$emit('click');
      });

      it('hides switch to old editor button', () => {
        expect(findSwitchToOldEditorButton().exists()).toBe(false);
      });

      it('displays "Edit source" label in the toggle editing mode button', () => {
        expect(findToggleEditingModeButton().text()).toBe('Edit source');
      });

      describe('when clicking the toggle editing mode button', () => {
        const contentEditorFakeSerializedContent = 'fake content';

        beforeEach(() => {
          mockContentEditor.getSerializedContent.mockReturnValueOnce(
            contentEditorFakeSerializedContent,
          );

          findContentEditor().vm.$emit('initialized', mockContentEditor);
          findToggleEditingModeButton().vm.$emit('click');
        });

        it('hides the content editor', () => {
          expect(findContentEditor().exists()).toBe(false);
        });

        it('displays the classic editor', () => {
          expect(findClassicEditor().exists()).toBe(true);
        });

        it('updates the classic editor content field', () => {
          expect(findContent().element.value).toBe(contentEditorFakeSerializedContent);
        });
      });
    });
  });

  describe('wiki content editor', () => {
    it.each`
      format        | buttonExists
      ${'markdown'} | ${true}
      ${'rdoc'}     | ${false}
    `(
      'gl-alert containing "use new editor" button exists: $buttonExists if format is $format',
      async ({ format, buttonExists }) => {
        createWrapper();

        await setFormat(format);

        expect(findUseNewEditorButton().exists()).toBe(buttonExists);
      },
    );

    it('gl-alert containing "use new editor" button is dismissed on clicking dismiss button', async () => {
      createWrapper();

      await findDismissContentEditorAlertButton().trigger('click');

      expect(findUseNewEditorButton().exists()).toBe(false);
    });

    const assertOldEditorIsVisible = () => {
      expect(findContentEditor().exists()).toBe(false);
      expect(findClassicEditor().exists()).toBe(true);
      expect(findSubmitButton().props('disabled')).toBe(false);

      expect(wrapper.text()).not.toContain(
        "Switching will discard any changes you've made in the new editor.",
      );
      expect(wrapper.text()).not.toContain(
        "This editor is in beta and may not display the page's contents properly.",
      );
    };

    it('shows classic editor by default', () => {
      createWrapper({ persisted: true });

      assertOldEditorIsVisible();
    });

    describe('switch format to rdoc', () => {
      beforeEach(async () => {
        createWrapper({ persisted: true });

        await setFormat('rdoc');
      });

      it('continues to show the classic editor', assertOldEditorIsVisible);

      describe('switch format back to markdown', () => {
        beforeEach(async () => {
          await setFormat('markdown');
        });

        it(
          'still shows the classic editor and does not automatically switch to the content editor ',
          assertOldEditorIsVisible,
        );
      });
    });

    describe('clicking "use new editor": editor fails to load', () => {
      beforeEach(async () => {
        createWrapper({ mountFn: mount });
        mock.onPost(/preview-markdown/).reply(400);

        await findUseNewEditorButton().trigger('click');

        // try waiting for content editor to load (but it will never actually load)
        await waitForPromises();
      });

      it('disables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(true);
      });

      describe('clicking "switch to classic editor"', () => {
        beforeEach(() => {
          return findSwitchToOldEditorButton().trigger('click');
        });

        it('switches to classic editor directly without showing a modal', () => {
          expect(wrapper.findComponent(ContentEditor).exists()).toBe(false);
          expect(wrapper.findComponent(MarkdownField).exists()).toBe(true);
        });
      });
    });

    describe('clicking "use new editor": editor loads successfully', () => {
      beforeEach(async () => {
        createWrapper({ persisted: true, mountFn: mount });

        mock.onPost(/preview-markdown/).reply(200, { body: '<p>hello <strong>world</strong></p>' });

        await findUseNewEditorButton().trigger('click');
      });

      it('shows a tip to send feedback', () => {
        expect(wrapper.text()).toContain('Tell us your experiences with the new Markdown editor');
      });

      it('shows warnings that the rich text editor is in beta and may not work properly', () => {
        expect(wrapper.text()).toContain(
          "This editor is in beta and may not display the page's contents properly.",
        );
      });

      it('shows the rich text editor when loading finishes', async () => {
        // wait for content editor to load
        await waitForPromises();

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(ContentEditor).exists()).toBe(true);
      });

      it('sends tracking event when editor loads', async () => {
        // wait for content editor to load
        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, CONTENT_EDITOR_LOADED_ACTION, {
          label: WIKI_CONTENT_EDITOR_TRACKING_LABEL,
        });
      });

      it('disables the format dropdown', () => {
        expect(findFormat().element.getAttribute('disabled')).toBeDefined();
      });

      describe('when wiki content is updated', () => {
        beforeEach(() => {
          findContentEditor().vm.$emit('change', { empty: false });
        });

        it('sets before unload warning', () => {
          const e = dispatchBeforeUnload();
          expect(e.preventDefault).toHaveBeenCalledTimes(1);
        });

        it('unsets before unload warning on form submit', async () => {
          await triggerFormSubmit();

          const e = dispatchBeforeUnload();
          expect(e.preventDefault).not.toHaveBeenCalled();
        });

        it('triggers tracking events on form submit', async () => {
          await triggerFormSubmit();

          expect(trackingSpy).toHaveBeenCalledWith(undefined, SAVED_USING_CONTENT_EDITOR_ACTION, {
            label: WIKI_CONTENT_EDITOR_TRACKING_LABEL,
          });

          expect(trackingSpy).toHaveBeenCalledWith(undefined, WIKI_FORMAT_UPDATED_ACTION, {
            label: WIKI_FORMAT_LABEL,
            extra: {
              value: findFormat().element.value,
              old_format: pageInfoPersisted.format,
              project_path: pageInfoPersisted.path,
            },
          });
        });

        it('updates content from content editor on form submit', async () => {
          // old value
          expect(findContent().element.value).toBe('  My page content  ');

          // wait for content editor to load
          await waitForPromises();

          await triggerFormSubmit();

          expect(findContent().element.value).toBe('hello **world**');
        });
      });

      describe('clicking "switch to classic editor"', () => {
        let modal;

        beforeEach(async () => {
          modal = wrapper.findComponent(GlModal);
          jest.spyOn(modal.vm, 'show');

          findSwitchToOldEditorButton().trigger('click');
        });

        it('shows a modal confirming the change', () => {
          expect(modal.vm.show).toHaveBeenCalled();
        });

        describe('confirming "switch to classic editor" in the modal', () => {
          beforeEach(async () => {
            wrapper.vm.contentEditor.tiptapEditor.commands.setContent(
              '<p>hello __world__ from content editor</p>',
              true,
            );

            wrapper.findComponent(GlModal).vm.$emit('primary');

            await wrapper.vm.$nextTick();
          });

          it('switches to classic editor', () => {
            expect(wrapper.findComponent(ContentEditor).exists()).toBe(false);
            expect(wrapper.findComponent(MarkdownField).exists()).toBe(true);
          });

          it('does not show a warning about content editor', () => {
            expect(wrapper.text()).not.toContain(
              "This editor is in beta and may not display the page's contents properly.",
            );
          });

          it('the classic editor retains its old value and does not use the content from the content editor', () => {
            expect(findContent().element.value).toBe('  My page content  ');
          });
        });
      });
    });
  });
});
