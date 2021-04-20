import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import WikiForm from '~/pages/shared/wikis/components/wiki_form.vue';

describe('WikiForm', () => {
  let wrapper;

  const findForm = () => wrapper.find('form');
  const findTitle = () => wrapper.find('#wiki_title');
  const findFormat = () => wrapper.find('#wiki_format');
  const findContent = () => wrapper.find('#wiki_content');
  const findMessage = () => wrapper.find('#wiki_message');
  const findSubmitButton = () => wrapper.findByTestId('wiki-submit-button');
  const findCancelButton = () => wrapper.findByTestId('wiki-cancel-button');
  const findTitleHelpLink = () => wrapper.findByTestId('wiki-title-help-link');
  const findMarkdownHelpLink = () => wrapper.findByTestId('wiki-markdown-help-link');

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
    content: 'My page content',
    format: 'markdown',
    path: '/project/path/-/wikis/home',
  };

  function createWrapper(persisted = false, pageInfo = {}) {
    wrapper = extendedWrapper(
      mount(
        WikiForm,
        {
          provide: {
            formatOptions: {
              Markdown: 'markdown',
              RDoc: 'rdoc',
              AsciiDoc: 'asciidoc',
              Org: 'org',
            },
            pageInfo: {
              ...(persisted ? pageInfoPersisted : pageInfoNew),
              ...pageInfo,
            },
          },
        },
        { attachToDocument: true },
      ),
    );

    jest.spyOn(wrapper.vm, 'onBeforeUnload');
  }

  afterEach(() => {
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
      createWrapper(persisted);

      findTitle().setValue(title);

      await wrapper.vm.$nextTick();

      expect(findMessage().element.value).toBe(message);
    },
  );

  it('sets the commit message to "Update My page" when the page first loads when persisted', async () => {
    createWrapper(true);

    await wrapper.vm.$nextTick();

    expect(findMessage().element.value).toBe('Update My page');
  });

  it.each`
    value         | text
    ${'markdown'} | ${'[Link Title](page-slug)'}
    ${'rdoc'}     | ${'{Link title}[link:page-slug]'}
    ${'asciidoc'} | ${'link:page-slug[Link title]'}
    ${'org'}      | ${'[[page-slug]]'}
  `('updates the link help message when format=$value is selected', async ({ value, text }) => {
    createWrapper();

    findFormat().find(`option[value=${value}]`).setSelected();

    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain(text);
  });

  it('starts with no unload warning', async () => {
    createWrapper();

    await wrapper.vm.$nextTick();

    window.dispatchEvent(new Event('beforeunload'));

    expect(wrapper.vm.onBeforeUnload).not.toHaveBeenCalled();
  });

  it.each`
    persisted | titleHelpText                                                                                              | titleHelpLink
    ${true}   | ${'You can move this page by adding the path to the beginning of the title.'}                              | ${'/help/user/project/wiki/index#move-a-wiki-page'}
    ${false}  | ${'You can specify the full path for the new file. We will automatically create any missing directories.'} | ${'/help/user/project/wiki/index#create-a-new-wiki-page'}
  `(
    'shows appropriate title help text and help link for when persisted=$persisted',
    async ({ persisted, titleHelpLink, titleHelpText }) => {
      createWrapper(persisted);

      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain(titleHelpText);
      expect(findTitleHelpLink().attributes().href).toEqual(titleHelpLink);
    },
  );

  it('shows correct link for wiki specific markdown docs', async () => {
    createWrapper();

    await wrapper.vm.$nextTick();

    expect(findMarkdownHelpLink().attributes().href).toEqual(
      '/help/user/markdown#wiki-specific-markdown',
    );
  });

  describe('when wiki content is updated', () => {
    beforeEach(() => {
      createWrapper();

      const input = findContent();
      input.setValue('Lorem ipsum dolar sit!');
      input.element.dispatchEvent(new Event('input'));

      return wrapper.vm.$nextTick();
    });

    it('sets before unload warning', () => {
      window.dispatchEvent(new Event('beforeunload'));

      expect(wrapper.vm.onBeforeUnload).toHaveBeenCalled();
    });

    it('when form submitted, unsets before unload warning', async () => {
      findForm().element.dispatchEvent(new Event('submit'));

      await wrapper.vm.$nextTick();

      window.dispatchEvent(new Event('beforeunload'));

      expect(wrapper.vm.onBeforeUnload).not.toHaveBeenCalled();
    });
  });

  describe('submit button state', () => {
    it.each`
      title          | content        | buttonState   | disabledAttr
      ${'something'} | ${'something'} | ${'enabled'}  | ${undefined}
      ${''}          | ${'something'} | ${'disabled'} | ${'disabled'}
      ${'something'} | ${''}          | ${'disabled'} | ${'disabled'}
      ${''}          | ${''}          | ${'disabled'} | ${'disabled'}
      ${'   '}       | ${'   '}       | ${'disabled'} | ${'disabled'}
    `(
      "when title='$title', content='$content', then the button is $buttonState'",
      async ({ title, content, disabledAttr }) => {
        createWrapper();

        findTitle().setValue(title);
        findContent().setValue(content);

        await wrapper.vm.$nextTick();

        expect(findSubmitButton().attributes().disabled).toBe(disabledAttr);
      },
    );

    it.each`
      persisted | buttonLabel
      ${true}   | ${'Save changes'}
      ${false}  | ${'Create page'}
    `('when persisted=$persisted, label is set to $buttonLabel', ({ persisted, buttonLabel }) => {
      createWrapper(persisted);

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
        createWrapper(persisted);

        expect(findCancelButton().attributes().href).toEqual(redirectLink);
      },
    );
  });
});
