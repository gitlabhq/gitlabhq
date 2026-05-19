import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import {
  GlAlert,
  GlButton,
  GlFormInput,
  GlFormGroup,
  GlCollapsibleListbox,
  GlFormCheckbox,
  GlForm,
  GlModal,
} from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import * as urlUtils from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WikiForm from '~/wikis/components/wiki_form.vue';
import WikiTemplate from '~/wikis/components/wiki_template.vue';
import DeleteWikiModal from '~/wikis/components/delete_wiki_modal.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { WIKI_FORMAT_LABEL, WIKI_FORMAT_UPDATED_ACTION } from '~/wikis/constants';
import getAutoCommitMessagePreference from '~/wikis/graphql/auto_commit_message_preference.query.graphql';
import { DRAWIO_ORIGIN } from 'spec/test_constants';
import { ignoreConsoleMessages } from 'helpers/console_watcher';
import { mockLocation, restoreLocation } from '../test_utils';

Vue.use(VueApollo);

jest.mock('~/emoji');
jest.mock('~/lib/graphql');

describe('WikiForm', () => {
  ignoreConsoleMessages([/timers APIs are not replaced with fake timers/]);

  let wrapper;
  let mock;
  let trackingSpy;

  const findForm = () => wrapper.find('form');
  const findTitle = () => wrapper.find('#wiki_title');
  const findPath = () => wrapper.find('#wiki_path');
  const findGeneratePathCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findFormat = () => wrapper.find('#wiki_format');
  const findMessageFormInput = () => wrapper.find("input[name='wiki[message]']");
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCancelButton = () => wrapper.findByTestId('wiki-cancel-button');

  const findMarkdownHelpLink = () => wrapper.findByTestId('wiki-markdown-help-link');
  const findTemplatesDropdown = () => wrapper.findComponent(WikiTemplate);
  const findPathGenerationToggle = () => wrapper.findByTestId('path-generation-toggle');

  const getFormData = () => new FormData(findForm().element);

  const setFormat = (value) => {
    const format = findFormat();

    return format.find(`option[value=${value}]`).setSelected();
  };

  const inputTitle = (value) => wrapper.findByTestId('wiki-title-textbox').setValue(value);

  const triggerFormSubmit = async () => {
    findForm().element.dispatchEvent(new Event('submit'));

    await nextTick();
  };

  const pageInfoNew = {
    persisted: false,
    slug: '',
    uploadsPath: '/project/path/-/wikis/attachments',
    wikiPath: '/project/path/-/wikis',
    helpPath: '/help/user/project/wiki/_index',
    markdownHelpPath: '/help/user/markdown',
    markdownPreviewPath: '/project/path/-/wikis/.md/preview-markdown',
    createPath: '/project/path/-/wikis/new',
  };

  const pageInfoPersisted = {
    ...pageInfoNew,
    persisted: true,
    slug: 'My-page',
    title: 'My page',
    content: '  My page content  ',
    format: 'markdown',
    path: '/project/path/-/wikis/home',
  };

  const pageInfoEditSidebar = {
    ...pageInfoNew,
    persisted: true,
    slug: '_sidebar',
    title: '_sidebar',
    content: '  My page content  ',
    format: 'markdown',
    path: '/project/path/-/wikis/_sidebar/edit',
  };

  const pageInfoNewSidebar = {
    ...pageInfoNew,
    persisted: false,
    slug: '_sidebar',
    title: '_sidebar',
    path: '/project/path/-/wikis/_sidebar',
  };

  const pageInfoWithFrontmatter = () => ({
    frontMatter: { foo: 'bar', title: 'real page title' },
    persisted: true,
    lastCommitSha: 'abcdef123',
    slug: 'foo/bar',
    title: 'bar',
    content: 'foo bar',
  });

  const formatOptions = {
    Markdown: 'markdown',
    RDoc: 'rdoc',
    AsciiDoc: 'asciidoc',
    Org: 'org',
  };
  function createWrapper({
    mountFn = shallowMountExtended,
    persisted = false,
    pageInfo,
    provide = {},
    templates = [],
    autoCommitMessageQueryHandler,
  } = {}) {
    const apolloProvider = createMockApollo([
      [
        getAutoCommitMessagePreference,
        autoCommitMessageQueryHandler ||
          jest.fn().mockResolvedValue({
            data: { currentUser: { id: '1', userPreferences: { wikiUseAutoCommitMessage: true } } },
          }),
      ],
    ]);

    wrapper = mountFn(WikiForm, {
      apolloProvider,
      provide: {
        isEditingPath: true,
        templates,
        formatOptions,
        pageInfo: {
          ...(persisted ? pageInfoPersisted : pageInfoNew),
          ...pageInfo,
        },
        wikiUrl: '',
        templatesUrl: '',
        pageHeading: '',
        csrfToken: '',
        pagePersisted: false,
        drawioUrl: null,
        glFeatures: { wikiImmersiveEditor: true },
        ...provide,
      },
      stubs: {
        GlAlert,
        GlButton,
        GlFormInput,
        GlFormGroup,
        GlForm,
        GlModal,
      },
    });
  }

  beforeEach(() => {
    jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue(null);

    trackingSpy = mockTracking(undefined, null, jest.spyOn);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('displays markdown editor', () => {
    createWrapper({ persisted: true });

    const markdownEditor = findMarkdownEditor();

    expect(markdownEditor.props()).toEqual(
      expect.objectContaining({
        value: pageInfoPersisted.content,
        renderMarkdownPath: pageInfoPersisted.markdownPreviewPath,
        uploadsPath: pageInfoPersisted.uploadsPath,
        autofocus: pageInfoPersisted.persisted,
        immersive: true,
        supportsTableOfContents: true,
      }),
    );

    expect(markdownEditor.props('formFieldProps')).toMatchObject({
      id: 'wiki_content',
    });
  });

  it('empties the title field if random_title=true is set in the URL', () => {
    mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/new?random_title=true');

    createWrapper({ persisted: true, mountFn: mountExtended });

    expect(findTitle().element.value).toBe('');

    restoreLocation();
  });

  it('enables immersive mode on markdown editor', () => {
    createWrapper();

    expect(findMarkdownEditor().props().immersive).toBe(true);
  });

  it('passes the form actions to the markdown editor #header slot', () => {
    createWrapper();

    expect(findMarkdownEditor().find('[data-testid="wiki-form-actions"]').exists()).toBe(true);
  });

  it('does not render the delete wiki modal', () => {
    createWrapper();

    expect(wrapper.findComponent(DeleteWikiModal).exists()).toBe(false);
  });

  describe('when wiki page is a template', () => {
    beforeEach(() => {
      mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/templates/abc');
    });

    afterEach(() => {
      restoreLocation();
    });

    it('makes sure commit message includes "Create template" for a new page', async () => {
      createWrapper({ persisted: false, mountFn: mountExtended });

      await inputTitle('my page');

      expect(findMessageFormInput().attributes('value')).toBe('Create template my page');
    });

    it('makes sure commit message includes "Update template" for an existing page', async () => {
      createWrapper({ persisted: true, mountFn: mountExtended });

      await inputTitle('my page');

      expect(findMessageFormInput().attributes('value')).toBe('Update template my page');
    });

    it('does not show any help text for title', () => {
      createWrapper({ persisted: true });

      expect(wrapper.text()).not.toContain(
        'You can move this page by adding the path to the beginning of the title.',
      );
      expect(wrapper.text()).not.toContain(
        'You can specify the full path for the new file. We will automatically create any missing directories.',
      );
    });

    it('does not show templates dropdown', () => {
      createWrapper({ persisted: true });

      expect(findTemplatesDropdown().exists()).toBe(false);
    });

    it('shows placeholder for title field', () => {
      createWrapper({ persisted: true });

      expect(findTitle().attributes('placeholder')).toBe('Template title');
    });

    it('disables file attachments', () => {
      createWrapper({ persisted: true });

      expect(findMarkdownEditor().props('disableAttachments')).toBe(true);
    });
  });

  describe('templates dropdown', () => {
    const templates = [
      { title: 'Markdown template 1', format: 'markdown', path: '/project/path/-/wikis/template1' },
      { title: 'Markdown template 2', format: 'markdown', path: '/project/path/-/wikis/template2' },
      { title: 'Rdoc template', format: 'rdoc', path: '/project/path/-/wikis/template3' },
      { title: 'Asciidoc template', format: 'asciidoc', path: '/project/path/-/wikis/template4' },
      { title: 'Org template', format: 'org', path: '/project/path/-/wikis/template5' },
    ];

    it('shows the dropdown when page is not a template', () => {
      createWrapper({ templates, mountFn: mountExtended });

      expect(findTemplatesDropdown().exists()).toBe(true);
    });

    it('shows templates dropdown even if no templates to show', () => {
      createWrapper({ mountFn: mountExtended });

      expect(findTemplatesDropdown().exists()).toBe(true);
    });

    it.each`
      format        | visibleTemplates
      ${'markdown'} | ${['Markdown template 1', 'Markdown template 2']}
      ${'rdoc'}     | ${['Rdoc template']}
      ${'asciidoc'} | ${['Asciidoc template']}
      ${'org'}      | ${['Org template']}
    `('shows appropriate templates for format $format', async ({ format, visibleTemplates }) => {
      createWrapper({ templates, mountFn: mountExtended });

      await setFormat(format);

      expect(
        findTemplatesDropdown()
          .findComponent(GlCollapsibleListbox)
          .props('items')
          .map(({ text }) => text),
      ).toEqual(visibleTemplates);
    });
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
      createWrapper({ persisted, mountFn: mountExtended });

      await findTitle().setValue(title);

      expect(findMessageFormInput().attributes('value')).toBe(message);
    },
  );

  it('sets the commit message to "Update My page" when the page first loads when persisted', async () => {
    createWrapper({ persisted: true, mountFn: mountExtended });

    await nextTick();

    expect(findMessageFormInput().attributes('value')).toBe('Update My page');
  });

  it('does not trim page content by default', () => {
    createWrapper({ persisted: true });

    expect(findMarkdownEditor().props().value).toBe('  My page content  ');
  });

  it.each`
    format        | enabled  | action
    ${'markdown'} | ${true}  | ${'displays'}
    ${'rdoc'}     | ${false} | ${'hides'}
    ${'asciidoc'} | ${false} | ${'hides'}
    ${'org'}      | ${false} | ${'hides'}
  `('$action preview in the markdown field when format is $format', async ({ format, enabled }) => {
    createWrapper({ mountFn: mountExtended });

    await setFormat(format);

    expect(findMarkdownEditor().vm.$attrs['enable-preview']).toBe(enabled);
  });

  describe('when wiki content is updated', () => {
    beforeEach(async () => {
      createWrapper({ mountFn: mountExtended, persisted: true });

      await findMarkdownEditor().vm.$emit('input', ' Lorem ipsum dolar sit! ');
    });

    describe('form submit', () => {
      beforeEach(async () => {
        await triggerFormSubmit();
      });

      it('submits the content', () => {
        expect([...getFormData().entries()]).toEqual([
          ['authenticity_token', ''],
          ['_method', 'put'],
          ['wiki[last_commit_sha]', ''],
          ['wiki[message]', 'Update My page'],
          ['wiki[title]', 'My-page'],
          ['wiki[format]', 'markdown'],
          ['wiki[content]', ' Lorem ipsum dolar sit! '],
        ]);
      });

      it('triggers wiki format tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'wiki_format_updated', {
          extra: {
            old_format: 'markdown',
            project_path: '/project/path/-/wikis/home',
            value: 'markdown',
          },
          label: 'wiki_format',
        });
      });

      it('tracks editor type used', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
          label: 'markdown_editor',
          property: 'Wiki',
        });
      });

      it('does not trim page content', () => {
        expect(findMarkdownEditor().props().value).toBe(' Lorem ipsum dolar sit! ');
      });
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

  it.each`
    format        | enabled  | action
    ${'markdown'} | ${true}  | ${'enables'}
    ${'rdoc'}     | ${false} | ${'disables'}
    ${'asciidoc'} | ${false} | ${'disables'}
    ${'org'}      | ${false} | ${'disables'}
  `('$action content editor when format is $format', async ({ format, enabled }) => {
    createWrapper({ mountFn: mountExtended });

    setFormat(format);

    await nextTick();

    expect(findMarkdownEditor().props().enableContentEditor).toBe(enabled);
  });

  describe('when markdown editor activates the content editor', () => {
    beforeEach(async () => {
      createWrapper({ mountFn: mountExtended, persisted: true });

      await findMarkdownEditor().vm.$emit('contentEditor');
    });

    it('disables the format dropdown', () => {
      expect(findFormat().element.getAttribute('disabled')).toBeDefined();
    });

    describe('when triggering form submit', () => {
      const updatedMarkdown = 'hello **world**';

      beforeEach(async () => {
        findMarkdownEditor().vm.$emit('input', updatedMarkdown);
        await triggerFormSubmit();
      });

      it('triggers tracking events on form submit', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, WIKI_FORMAT_UPDATED_ACTION, {
          label: WIKI_FORMAT_LABEL,
          extra: {
            value: findFormat().element.value,
            old_format: pageInfoPersisted.format,
            project_path: pageInfoPersisted.path,
          },
        });
      });
    });
  });

  describe('when drawioURL is provided', () => {
    it('enables drawio editor in the Markdown Editor', () => {
      createWrapper({ provide: { drawioUrl: DRAWIO_ORIGIN } });

      expect(findMarkdownEditor().props().drawioEnabled).toBe(true);
    });
  });

  describe('when drawioURL is empty', () => {
    it('disables drawio editor in the Markdown Editor', () => {
      createWrapper();

      expect(findMarkdownEditor().props().drawioEnabled).toBe(false);
    });
  });

  describe('path field', () => {
    beforeEach(() => {
      createWrapper({
        mountFn: mountExtended,
        pageInfo: pageInfoWithFrontmatter(),
      });
    });

    it('shows the path field', () => {
      expect(findPath().exists()).toBe(true);
    });

    it("retains page's frontmatter on form submit", async () => {
      await findForm().trigger('submit');

      expect([...getFormData().entries()]).toEqual([
        ['authenticity_token', ''],
        ['_method', 'put'],
        ['wiki[last_commit_sha]', 'abcdef123'],
        ['wiki[message]', 'Update real page title'],
        ['wiki[title]', 'foo/bar'],
        ['wiki[format]', 'markdown'],
        ['wiki[content]', '---\nfoo: bar\ntitle: real page title\n---\nfoo bar'],
      ]);
    });

    describe('if generate path from title is unchecked', () => {
      it("saves page's title in frontmatter on submit", async () => {
        await findTitle().setValue('new title');
        await findForm().trigger('submit');

        expect([...getFormData().entries()]).toEqual([
          ['authenticity_token', ''],
          ['_method', 'put'],
          ['wiki[last_commit_sha]', 'abcdef123'],
          ['wiki[message]', 'Update new title'],
          ['wiki[title]', 'foo/bar'],
          ['wiki[format]', 'markdown'],
          ['wiki[content]', '---\nfoo: bar\ntitle: new title\n---\nfoo bar'],
        ]);
      });
    });
  });

  describe('title placeholder functionality', () => {
    const pageInfoWithNewPageTitle = {
      persisted: false,
      slug: 'parent/path/{new_page_title}',
      title: 'parent/path/{new_page_title}',
      uploadsPath: '/project/path/-/wikis/attachments',
      wikiPath: '/project/path/-/wikis',
      helpPath: '/help/user/project/wiki/_index',
      markdownHelpPath: '/help/user/markdown',
      markdownPreviewPath: '/project/path/-/wikis/.md/preview-markdown',
      createPath: '/project/path/-/wikis/new',
    };

    describe('when creating a new page with placeholder in title', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          pageInfo: pageInfoWithNewPageTitle,
        });
      });

      it('renders the correct initial value in the title input', () => {
        expect(findTitle().element.value).toBe('{Give this page a title}');
      });

      it('sets the path to the parent path', () => {
        expect(findPath().element.value).toBe('parent/path/');
      });

      it('clears placeholder when user starts typing', async () => {
        await findTitle().setValue('My New Page');
        expect(findTitle().element.value).toBe('My New Page');
      });

      it('clears placeholder when user presses a printable key', async () => {
        await findTitle().trigger('focus');
        await findTitle().trigger('keydown', {
          key: 'M',
          ctrlKey: false,
          metaKey: false,
          altKey: false,
        });
        expect(findTitle().element.value).toBe('');
      });

      it('does not clear placeholder for non-printable keys', async () => {
        await findTitle().trigger('focus');
        await findTitle().trigger('keydown', {
          key: 'Enter',
          ctrlKey: false,
          metaKey: false,
          altKey: false,
        });
        expect(findTitle().element.value).toBe('{Give this page a title}');
      });

      it('does not clear placeholder for modifier key combinations', async () => {
        await findTitle().trigger('focus');
        await findTitle().trigger('keydown', {
          key: 'a',
          ctrlKey: true,
          metaKey: false,
          altKey: false,
        });
        expect(findTitle().element.value).toBe('{Give this page a title}');
      });
    });

    describe('when creating a new page with parent and a custom path', () => {
      beforeEach(async () => {
        createWrapper({
          mountFn: mountExtended,
          pageInfo: pageInfoWithNewPageTitle,
        });

        await nextTick();
      });

      it('does not overwrite a custom path when generating path from title is disabled', async () => {
        findPathGenerationToggle().vm.$emit('change', false);
        await nextTick();

        findPath().setValue('parent/path/custom-slug');
        await nextTick();

        await findTitle().setValue('My New Page');
        await nextTick();

        expect(findPath().element.value).toBe('parent/path/custom-slug');
      });

      it('restores parent path in generated path when re-enabling path generation', async () => {
        await findTitle().setValue('My New Page');
        await nextTick();

        findPathGenerationToggle().vm.$emit('change', false);
        await nextTick();

        findPathGenerationToggle().vm.$emit('change', true);
        await nextTick();

        expect(findPath().element.value).toBe('parent/path/My-New-Page');
      });
    });

    describe('when creating a new page without placeholder in title', () => {
      const pageInfoWithoutPlaceholder = {
        persisted: false,
        slug: 'normal-page',
        title: 'normal-page',
        uploadsPath: '/project/path/-/wikis/attachments',
        wikiPath: '/project/path/-/wikis',
        helpPath: '/help/user/project/wiki/_index',
        markdownHelpPath: '/help/user/markdown',
        markdownPreviewPath: '/project/path/-/wikis/.md/preview-markdown',
        createPath: '/project/path/-/wikis/new',
      };

      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          pageInfo: pageInfoWithoutPlaceholder,
        });
      });

      it('renders the correct initial value in the title input', () => {
        expect(findTitle().element.value).toBe('normal-page');
      });

      it('handles normal input without placeholder logic', async () => {
        await findTitle().setValue('updated-title');
        expect(findTitle().element.value).toBe('updated-title');
      });
    });

    describe('when editing an existing page', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          persisted: true,
        });
      });

      it('renders the correct initial value in the title input', () => {
        expect(findTitle().element.value).not.toBe('parent/path/{Give this page a title}');
      });

      it('handles input normally without placeholder logic', async () => {
        await findTitle().setValue('updated-title');
        expect(findTitle().element.value).toBe('updated-title');
      });
    });
  });

  describe('title newline prevention', () => {
    beforeEach(() => {
      createWrapper({
        mountFn: mountExtended,
        persisted: true,
      });
    });

    it('prevents Enter key from inserting a newline', () => {
      const titleInput = findTitle();
      const event = new KeyboardEvent('keydown', { key: 'Enter', cancelable: true });
      titleInput.element.dispatchEvent(event);

      expect(event.defaultPrevented).toBe(true);
    });

    it('replaces newlines with spaces in pasted content', async () => {
      await inputTitle('line1\nline2\rline3\u2028line4\u2029line5');

      expect(findTitle().element.value).toBe('line1 line2 line3 line4 line5');
    });
  });

  describe.each`
    case                                                                                    | persisted | originalTitle                     | originalPath                      | titleInput   | expectedTitle | expectedPath
    ${'new page with parent path and title'}                                                | ${false}  | ${'parent/path/{new_page_title}'} | ${'parent/path/{new_page_title}'} | ${'My page'} | ${'My page'}  | ${'parent/path/My-page'}
    ${'new page with title'}                                                                | ${false}  | ${''}                             | ${''}                             | ${'My page'} | ${'My page'}  | ${'My-page'}
    ${'new page with no title'}                                                             | ${false}  | ${''}                             | ${''}                             | ${''}        | ${'Untitled'} | ${'untitled-20230730042400'}
    ${'new page with title (page reload) generates path from title'}                        | ${false}  | ${'Foo'}                          | ${''}                             | ${'Bar'}     | ${'Bar'}      | ${'Bar'}
    ${'new page with title and path (page reload) updates path with title'}                 | ${false}  | ${'Foo'}                          | ${'foo'}                          | ${'Bar'}     | ${'Bar'}      | ${'Bar'}
    ${'new page with title that is removed and no path (state inconsistency after reload)'} | ${false}  | ${'Foo'}                          | ${''}                             | ${''}        | ${'Untitled'} | ${'untitled-20230730042400'}
    ${'new page with path but no title (page reload)'}                                      | ${false}  | ${''}                             | ${'bar'}                          | ${''}        | ${'Untitled'} | ${'bar'}
    ${'existing page with updated title keeps path'}                                        | ${true}   | ${'Foo'}                          | ${'foo'}                          | ${'Bar'}     | ${'Bar'}      | ${'foo'}
    ${'existing page with removed title keeps path'}                                        | ${true}   | ${'Foo'}                          | ${'foo'}                          | ${''}        | ${'Untitled'} | ${'foo'}
    ${'existing page with no title updates path from title'}                                | ${true}   | ${'Untitled'}                     | ${'untitled-20221310061200'}      | ${'Bar'}     | ${'Bar'}      | ${'Bar'}
    ${'existing page with autogenerated path keeps path when title is removed'}             | ${true}   | ${'Untitled'}                     | ${'untitled-20221310061200'}      | ${''}        | ${'Untitled'} | ${'untitled-20221310061200'}
    ${'existing page with title and autogenerated path keeps path when title is removed'}   | ${true}   | ${'Foo'}                          | ${'untitled-20221310061200'}      | ${''}        | ${'Untitled'} | ${'untitled-20221310061200'}
  `(
    '$case',
    ({ persisted, originalTitle, originalPath, titleInput, expectedTitle, expectedPath }) => {
      let submittedFormData;

      beforeEach(async () => {
        jest
          .useFakeTimers({ legacyFakeTimers: false })
          .setSystemTime(new Date('2023-07-30T04:24:00'));
        createWrapper({
          mountFn: shallowMountExtended,
          persisted,
          pageInfo: {
            slug: originalPath,
            title: originalTitle,
          },
        });

        await waitForPromises();

        const input = wrapper.findByTestId('wiki-title-textbox');
        input.element.value = titleInput;
        await input.trigger('input');

        await nextTick();
        await triggerFormSubmit();

        submittedFormData = [...getFormData().entries()];
      });

      it(`submits "${expectedPath}" as the path`, () => {
        expect(submittedFormData).toContainEqual(['wiki[title]', expectedPath]);
      });

      it(`submits "${expectedTitle}" as the title`, () => {
        expect(submittedFormData).toContainEqual([
          'wiki[content]',
          expect.stringContaining(`---\ntitle: ${expectedTitle}\n---`),
        ]);
      });
    },
  );

  describe('adding a commit message', () => {
    let mutateSpy;

    beforeEach(async () => {
      createWrapper({ mountFn: shallowMountExtended });
      await waitForPromises();
      mutateSpy = jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate');

      wrapper.findByTestId('wiki-submit-message-mode').vm.$emit('select', 'CUSTOM');
    });

    afterEach(() => {
      mutateSpy.mockRestore();
    });

    it('shows the commit message modal', () => {
      expect(wrapper.findByTestId('commit-message-modal').props('visible')).toBe(true);
    });

    it('shows the input field', () => {
      expect(wrapper.findByTestId('wiki-message-textbox').isVisible()).toBe(true);
    });

    it('persists the preference via mutation', () => {
      expect(mutateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              wikiUseAutoCommitMessage: false,
            },
          },
        }),
      );
    });

    it('includes the commit message in the form', async () => {
      wrapper.findComponentByTestId('wiki-message-textbox').vm.$emit('input', 'Foobar');
      await nextTick();
      expect(wrapper.find('input[name="wiki[message]"]').attributes('value')).toBe('Foobar');
    });

    describe('auto commit message toggle', () => {
      const findToggle = () => wrapper.findByTestId('auto-commit-message-toggle');

      it('renders the toggle in the modal', () => {
        expect(findToggle().exists()).toBe(true);
        expect(findToggle().props('label')).toBe('Use the default commit message for future saves');
      });

      it('reflects the current preference value', () => {
        expect(findToggle().props('value')).toBe(false);
      });

      it('updates the preference when toggled on', async () => {
        mutateSpy.mockClear();

        findToggle().vm.$emit('change', true);
        await nextTick();

        expect(findToggle().props('value')).toBe(true);
        expect(mutateSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            variables: {
              input: {
                wikiUseAutoCommitMessage: true,
              },
            },
          }),
        );
      });

      it('does not submit the form when toggled', async () => {
        const submitSpy = jest.spyOn(findForm().element, 'submit');

        findToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(submitSpy).not.toHaveBeenCalled();
      });
    });
  });

  describe('saving through the commit message modal', () => {
    let submitSpy;

    beforeEach(async () => {
      createWrapper({
        pageInfo: { title: 'Foo' },
      });
      await waitForPromises();
      submitSpy = jest.spyOn(findForm().element, 'submit');

      wrapper.findByTestId('wiki-submit-message-mode').vm.$emit('select', 'CUSTOM');

      await waitForPromises();

      wrapper.findComponentByTestId('wiki-message-textbox').vm.$emit('input', 'Foobar');

      await nextTick();
    });

    it('saves the form when selecting the primary action on the commit message modal', async () => {
      wrapper.findComponentByTestId('commit-message-modal').vm.$emit('primary');
      await nextTick();

      expect(submitSpy).toHaveBeenCalled();
    });

    it.each(['secondary', 'cancel'])(
      'does not save the form when the commit message modal emits "%s"',
      async (event) => {
        wrapper.findComponentByTestId('commit-message-modal').vm.$emit(event);
        await nextTick();

        expect(submitSpy).not.toHaveBeenCalled();
      },
    );
  });

  describe('save message mode preference', () => {
    const immersiveProvide = { glFeatures: { wikiImmersiveEditor: true } };

    const autoCommitMessageQueryResponse = (value) =>
      jest.fn().mockResolvedValue({
        data: {
          currentUser: {
            id: '1',
            userPreferences: { wikiUseAutoCommitMessage: value },
          },
        },
      });

    describe('when clicking save button', () => {
      it('submits form directly when useAutoCommitMessage is true', async () => {
        createWrapper({
          pageInfo: { title: 'Foo' },
          autoCommitMessageQueryHandler: autoCommitMessageQueryResponse(true),
        });
        await waitForPromises();
        const submitSpy = jest.spyOn(findForm().element, 'submit');

        wrapper.findByTestId('wiki-submit-button').vm.$emit('click', new Event('click'));
        await nextTick();

        expect(submitSpy).toHaveBeenCalled();
      });

      it('opens commit message modal when useAutoCommitMessage is false', async () => {
        createWrapper({
          pageInfo: { title: 'Foo' },
          autoCommitMessageQueryHandler: autoCommitMessageQueryResponse(false),
        });
        await waitForPromises();
        const submitSpy = jest.spyOn(findForm().element, 'submit');

        wrapper.findByTestId('wiki-submit-button').vm.$emit('click', new Event('click'));
        await nextTick();

        expect(wrapper.findByTestId('commit-message-modal').props('visible')).toBe(true);
        expect(submitSpy).not.toHaveBeenCalled();
      });

      it('does not call the preference mutation', async () => {
        createWrapper({
          pageInfo: { title: 'Foo' },
        });
        await waitForPromises();
        const spy = jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate');

        wrapper.findByTestId('wiki-submit-button').vm.$emit('click', new Event('click'));
        await nextTick();

        expect(spy).not.toHaveBeenCalled();
        spy.mockRestore();
      });
    });

    describe.each`
      preference | selectedMode | shouldOpenCommitMessageModal | updatesPreference
      ${true}    | ${'AUTO'}    | ${false}                     | ${false}
      ${true}    | ${'CUSTOM'}  | ${true}                      | ${true}
      ${false}   | ${'AUTO'}    | ${false}                     | ${true}
      ${false}   | ${'CUSTOM'}  | ${true}                      | ${false}
    `(
      'when preference is $preference and selecting $selectedMode from dropdown',
      ({ preference, selectedMode, shouldOpenCommitMessageModal, updatesPreference }) => {
        let submitSpy;
        let mutateSpyLocal;

        beforeEach(async () => {
          createWrapper({
            pageInfo: { title: 'Foo' },
            autoCommitMessageQueryHandler: autoCommitMessageQueryResponse(preference),
          });
          await waitForPromises();
          submitSpy = jest.spyOn(findForm().element, 'submit');
          mutateSpyLocal = jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate');

          wrapper.findByTestId('wiki-submit-message-mode').vm.$emit('select', selectedMode);
          await waitForPromises();
        });

        afterEach(() => {
          mutateSpyLocal.mockRestore();
        });

        if (shouldOpenCommitMessageModal) {
          it('opens commit message modal', () => {
            expect(wrapper.findByTestId('commit-message-modal').props('visible')).toBe(true);
            expect(submitSpy).not.toHaveBeenCalled();
          });
        } else {
          it('submits form directly', () => {
            expect(submitSpy).toHaveBeenCalled();
          });
        }

        if (updatesPreference) {
          it('updates the preference via mutation', () => {
            expect(mutateSpyLocal).toHaveBeenCalledWith(
              expect.objectContaining({
                variables: {
                  input: {
                    wikiUseAutoCommitMessage: selectedMode === 'AUTO',
                  },
                },
              }),
            );
          });

          it('shows loading state on the save button while mutation is in-flight', async () => {
            createWrapper({
              pageInfo: { title: 'Foo' },
              provide: immersiveProvide,
              autoCommitMessageQueryHandler: autoCommitMessageQueryResponse(preference),
            });
            await waitForPromises();

            let resolveMutate;
            jest.spyOn(wrapper.vm.$apollo.provider.defaultClient, 'mutate').mockReturnValue(
              new Promise((resolve) => {
                resolveMutate = resolve;
              }),
            );

            wrapper.findByTestId('wiki-submit-message-mode').vm.$emit('select', selectedMode);
            await nextTick();

            expect(wrapper.findByTestId('wiki-submit-button').props('loading')).toBe(true);

            resolveMutate();
            await waitForPromises();

            expect(wrapper.findByTestId('wiki-submit-button').props('loading')).toBe(false);
          });
        } else {
          it('does not update the preference via mutation', () => {
            expect(mutateSpyLocal).not.toHaveBeenCalled();
          });
        }
      },
    );
  });

  describe('edit sidebar', () => {
    describe('when sidebar is persisted', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: shallowMountExtended,
          pageInfo: pageInfoEditSidebar,
          provide: {
            wikiUrl: '_sidebar',
            pagePersisted: true,
            isEditingPath: true,
          },
        });
      });

      it('shows an edit sidebar header', () => {
        expect(wrapper.text()).toContain('Edit Sidebar');
      });

      it('hides the title input', () => {
        expect(wrapper.findByTestId('wiki-title-textbox').exists()).toBe(false);
      });

      it('hides the path input', () => {
        expect(wrapper.findByTestId('wiki-path-textbox').exists()).toBe(false);
      });

      it('hides the generate path from title toggle', () => {
        expect(wrapper.findByTestId('path-generation-toggle').exists()).toBe(false);
      });

      it('renders the delete wiki modal', () => {
        expect(wrapper.findComponent(DeleteWikiModal).exists()).toBe(true);
      });

      it('includes a hidden wiki[title] input with value _sidebar', () => {
        const hiddenInput = wrapper.find('input[name="wiki[title]"][type="hidden"]');
        expect(hiddenInput.exists()).toBe(true);
        expect(hiddenInput.attributes('value')).toBe('_sidebar');
      });
    });

    describe('when sidebar is not persisted', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: shallowMountExtended,
          pageInfo: pageInfoNewSidebar,
          provide: {
            wikiUrl: '_sidebar',
            isEditingPath: true,
          },
        });
      });

      it('shows a create custom sidebar header', () => {
        expect(wrapper.text()).toContain('Create custom sidebar');
      });
    });
  });

  describe('classic mode', () => {
    const provide = { glFeatures: { wikiImmersiveEditor: false } };

    it.each`
      title   | display
      ${''}   | ${'empty string'}
      ${' '}  | ${'whitespace only'}
      ${null} | ${'null'}
    `('shows an error on attempted submit if the title is $display', async ({ title }) => {
      createWrapper({ persisted: true, mountFn: mountExtended, provide });

      expect(findTitle().props('state')).toBe(null);

      findTitle().setValue(title);
      await findForm().trigger('submit');

      expect(findTitle().props('state')).toBe(false);

      findTitle().setValue('my page');
      await findForm().trigger('submit');

      expect(findTitle().props('state')).toBe(true);
    });

    it.each`
      value         | text
      ${'markdown'} | ${'[Link Title](page-slug)'}
      ${'rdoc'}     | ${'{Link title}[link:page-slug]'}
      ${'asciidoc'} | ${'link:page-slug[Link title]'}
      ${'org'}      | ${'[[page-slug]]'}
    `('updates the link help message when format=$value is selected', async ({ value, text }) => {
      createWrapper({ mountFn: mountExtended, provide });

      await setFormat(value);

      expect(wrapper.text()).toContain(text);
    });

    it('shows correct link for wiki specific markdown docs', () => {
      createWrapper({ mountFn: mountExtended, provide });

      expect(findMarkdownHelpLink().attributes().href).toBe(
        '/help/user/project/wiki/markdown#links',
      );
    });

    describe('if generate path from title is checked', () => {
      beforeEach(async () => {
        createWrapper({
          mountFn: mountExtended,
          pageInfo: pageInfoWithFrontmatter(),
          provide,
        });
        await findGeneratePathCheckbox().vm.$emit('input', true);
      });

      it("does not save page's title in frontmatter on submit", async () => {
        await findTitle().setValue('new title');
        await findForm().trigger('submit');

        expect([...getFormData().entries()]).toEqual([
          ['authenticity_token', ''],
          ['_method', 'put'],
          ['wiki[last_commit_sha]', 'abcdef123'],
          ['wiki[title]', 'new-title'],
          ['wiki[format]', 'markdown'],
          ['wiki[content]', '---\nfoo: bar\n---\nfoo bar'],
          ['wiki[message]', 'Update new title'],
        ]);
      });
    });
  });

  describe('keyboard shortcut form submission', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('submits the form when ctrl+enter is triggered on the markdown editor', async () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');
      const ctrlEnterEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        ctrlKey: true,
      });

      findMarkdownEditor().vm.$emit('keydown', ctrlEnterEvent);
      await nextTick();

      expect(submitSpy).toHaveBeenCalled();
    });

    it('submits the form when meta+enter is triggered on the markdown editor', async () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');
      const metaEnterEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        metaKey: true,
      });

      findMarkdownEditor().vm.$emit('keydown', metaEnterEvent);
      await nextTick();

      expect(submitSpy).toHaveBeenCalled();
    });
  });
});
