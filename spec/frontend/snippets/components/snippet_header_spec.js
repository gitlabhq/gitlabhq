import { GlModal, GlButton, GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import SnippetHeader, { i18n } from '~/snippets/components/snippet_header.vue';
import DeleteSnippetMutation from '~/snippets/mutations/delete_snippet.mutation.graphql';
import axios from '~/lib/utils/axios_utils';
import { createAlert, VARIANT_DANGER, VARIANT_SUCCESS } from '~/alert';
import CanCreateProjectSnippet from 'shared_queries/snippet/project_permissions.query.graphql';
import CanCreatePersonalSnippet from 'shared_queries/snippet/user_permissions.query.graphql';
import { getCanCreateProjectSnippetMock, getCanCreatePersonalSnippetMock } from '../mock_data';

const ERROR_MSG = 'Foo bar';
const ERR = { message: ERROR_MSG };

const MUTATION_TYPES = {
  RESOLVE: jest.fn().mockResolvedValue({ data: { destroySnippet: { errors: [] } } }),
  REJECT: jest.fn().mockRejectedValue(ERR),
};

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Snippet header component', () => {
  let wrapper;
  let snippet;
  let mock;
  let mockApollo;

  const reportAbusePath = '/-/snippets/42/mark_as_spam';
  const canReportSpam = true;

  const GlEmoji = { template: '<img/>' };

  function createComponent({
    permissions = {},
    snippetProps = {},
    provide = {},
    canCreateProjectSnippetMock = jest.fn().mockResolvedValue(getCanCreateProjectSnippetMock()),
    canCreatePersonalSnippetMock = jest.fn().mockResolvedValue(getCanCreatePersonalSnippetMock()),
    deleteSnippetMock = MUTATION_TYPES.RESOLVE,
  } = {}) {
    const defaultProps = Object.assign(snippet, snippetProps);
    if (permissions) {
      Object.assign(defaultProps.userPermissions, {
        ...permissions,
      });
    }

    mockApollo = createMockApollo([
      [CanCreateProjectSnippet, canCreateProjectSnippetMock],
      [CanCreatePersonalSnippet, canCreatePersonalSnippetMock],
      [DeleteSnippetMutation, deleteSnippetMock],
    ]);

    wrapper = mount(SnippetHeader, {
      provide: {
        reportAbusePath,
        canReportSpam,
        ...provide,
      },
      propsData: {
        snippet: {
          ...defaultProps,
        },
      },
      stubs: {
        GlEmoji,
      },
      apolloProvider: mockApollo,
    });
  }

  const findAuthorEmoji = () => wrapper.findComponent(GlEmoji);
  const findAuthoredMessage = () => wrapper.find('[data-testid="authored-message"]').text();
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findButtonsAsModel = () =>
    findButtons().wrappers.map((x) => ({
      text: x.text(),
      href: x.attributes('href'),
      category: x.props('category'),
      variant: x.props('variant'),
      disabled: x.props('disabled'),
    }));
  const findResponsiveDropdown = () => wrapper.findComponent(GlDropdown);
  // We can't search by component here since we are full mounting and the attributes are applied to a child of the GlDropdownItem
  const findResponsiveDropdownItems = () => findResponsiveDropdown().findAll('[role="menuitem"]');
  const findResponsiveDropdownItemsAsModel = () =>
    findResponsiveDropdownItems().wrappers.map((x) => ({
      disabled: x.attributes('disabled'),
      href: x.attributes('href'),
      title: x.attributes('title'),
      text: x.text(),
    }));
  const findDeleteModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    gon.relative_url_root = '/foo/';
    snippet = {
      id: 'gid://gitlab/PersonalSnippet/50',
      title: 'The property of Thor',
      visibilityLevel: 'private',
      webUrl: 'http://personal.dev.null/42',
      userPermissions: {
        adminSnippet: true,
        updateSnippet: true,
        reportSnippet: false,
      },
      project: null,
      author: {
        name: 'Thor Odinson',
        status: null,
      },
      blobs: [Blob],
      createdAt: new Date(differenceInMilliseconds(32 * 24 * 3600 * 1000)).toISOString(),
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mockApollo = null;
    mock.restore();
  });

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.detail-page-header').exists()).toBe(true);
  });

  it('renders a message showing snippet creation date and author', () => {
    createComponent();

    const text = findAuthoredMessage();
    expect(text).toContain('Authored 1 month ago by');
    expect(text).toContain('Thor Odinson');
  });

  describe('author status', () => {
    it('is rendered when it is set', () => {
      snippet.author.status = {
        message: 'At work',
        emoji: 'hammer',
      };
      createComponent();

      expect(findAuthorEmoji().attributes('title')).toBe(snippet.author.status.message);
      expect(findAuthorEmoji().attributes('data-name')).toBe(snippet.author.status.emoji);
    });

    it('is not rendered when the user has no status', () => {
      createComponent();

      expect(findAuthorEmoji().exists()).toBe(false);
    });
  });

  it('renders a message showing only snippet creation date if author is null', () => {
    snippet.author = null;

    createComponent();

    const text = findAuthoredMessage();
    expect(text).toBe('Authored 1 month ago');
  });

  it('renders a action buttons', () => {
    createComponent();

    expect(findButtonsAsModel()).toEqual([
      {
        category: 'primary',
        disabled: false,
        href: `${snippet.webUrl}/edit`,
        text: 'Edit',
        variant: 'default',
      },
      {
        category: 'secondary',
        disabled: false,
        text: 'Delete',
        variant: 'danger',
      },
      {
        category: 'primary',
        disabled: false,
        text: 'Submit as spam',
        variant: 'default',
      },
    ]);
  });

  it('renders responsive dropdown for action buttons', () => {
    createComponent();

    expect(findResponsiveDropdownItemsAsModel()).toEqual([
      {
        href: `${snippet.webUrl}/edit`,
        text: 'Edit',
      },
      {
        text: 'Delete',
      },
      {
        text: 'Submit as spam',
        title: 'Submit as spam',
      },
    ]);
  });

  it.each`
    permissions                                      | buttons
    ${{ adminSnippet: false, updateSnippet: false }} | ${['Submit as spam']}
    ${{ adminSnippet: true, updateSnippet: false }}  | ${['Delete', 'Submit as spam']}
    ${{ adminSnippet: false, updateSnippet: true }}  | ${['Edit', 'Submit as spam']}
  `('with permissions ($permissions), renders buttons ($buttons)', ({ permissions, buttons }) => {
    createComponent({
      permissions: {
        ...permissions,
      },
    });

    expect(findButtonsAsModel().map((x) => x.text)).toEqual(buttons);
  });

  it('with canCreateSnippet permission, renders create button', async () => {
    createComponent({
      canCreateProjectSnippetMock: jest
        .fn()
        .mockResolvedValue(getCanCreateProjectSnippetMock(true)),
      canCreatePersonalSnippetMock: jest
        .fn()
        .mockResolvedValue(getCanCreatePersonalSnippetMock(true)),
    });

    await waitForPromises();

    expect(findButtonsAsModel()).toEqual(
      expect.arrayContaining([
        {
          category: 'secondary',
          disabled: false,
          href: `/foo/-/snippets/new`,
          text: 'New snippet',
          variant: 'confirm',
        },
      ]),
    );
  });

  describe('submit snippet as spam', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      request | variant            | text
      ${200}  | ${VARIANT_SUCCESS} | ${i18n.snippetSpamSuccess}
      ${500}  | ${VARIANT_DANGER}  | ${i18n.snippetSpamFailure}
    `(
      'renders a "$variant" alert message with "$text" message for a request with a "$request" response',
      async ({ request, variant, text }) => {
        const submitAsSpamBtn = findButtons().at(2);
        mock.onPost(reportAbusePath).reply(request);
        submitAsSpamBtn.trigger('click');
        await waitForPromises();

        expect(createAlert).toHaveBeenLastCalledWith({
          message: expect.stringContaining(text),
          variant,
        });
      },
    );
  });

  describe('with guest user', () => {
    beforeEach(() => {
      createComponent({
        permissions: {
          adminSnippet: false,
          updateSnippet: false,
        },
        provide: {
          reportAbusePath: null,
          canReportSpam: false,
        },
      });
    });

    it('does not show any action buttons', () => {
      expect(findButtons()).toHaveLength(0);
    });

    it('does not show responsive action dropdown', () => {
      expect(findResponsiveDropdown().exists()).toBe(false);
    });
  });

  it('renders modal for deletion of a snippet', () => {
    createComponent();
    expect(wrapper.findComponent(GlModal).exists()).toBe(true);
  });

  it.each`
    blobs                 | isDisabled | condition
    ${[Blob]}             | ${false}   | ${'no binary'}
    ${[Blob, BinaryBlob]} | ${true}    | ${'several blobs. incl. a binary'}
    ${[BinaryBlob]}       | ${true}    | ${'binary'}
  `('renders Edit button when snippet contains $condition file', ({ blobs, isDisabled }) => {
    createComponent({
      snippetProps: {
        blobs,
      },
    });
    expect(wrapper.find('[href*="edit"]').props('disabled')).toBe(isDisabled);
  });

  describe('Delete mutation', () => {
    const deleteSnippet = async () => {
      // Click delete action
      findButtons().at(1).trigger('click');
      await nextTick();

      expect(findDeleteModal().props().visible).toBe(true);

      // Click delete button in delete modal
      document.querySelector('[data-testid="delete-snippet"').click();
      await waitForPromises();
    };

    it('dispatches a mutation to delete the snippet with correct variables', async () => {
      createComponent();

      await deleteSnippet();

      expect(MUTATION_TYPES.RESOLVE).toHaveBeenCalledWith({
        id: snippet.id,
      });
    });

    it('sets error message if mutation fails', async () => {
      createComponent({ deleteSnippetMock: MUTATION_TYPES.REJECT });
      expect(Boolean(wrapper.vm.errorMessage)).toBe(false);

      await deleteSnippet();

      expect(document.querySelector('[data-testid="delete-alert"').textContent.trim()).toBe(
        ERROR_MSG,
      );
    });

    describe('in case of successful mutation, closes modal and redirects to correct listing', () => {
      useMockLocationHelper();

      const createDeleteSnippet = async (snippetProps = {}) => {
        createComponent({
          snippetProps,
        });

        await deleteSnippet();
      };

      it('redirects to dashboard/snippets for personal snippet', async () => {
        await createDeleteSnippet();

        // Check that the modal is hidden after deleting the snippet
        expect(findDeleteModal().props().visible).toBe(false);

        expect(window.location.pathname).toBe(`${gon.relative_url_root}dashboard/snippets`);
      });

      it('redirects to project snippets for project snippet', async () => {
        const fullPath = 'foo/bar';
        await createDeleteSnippet({
          project: {
            fullPath,
          },
        });

        // Check that the modal is hidden after deleting the snippet
        expect(findDeleteModal().props().visible).toBe(false);

        expect(window.location.pathname).toBe(`${fullPath}/-/snippets`);
      });
    });
  });
});
