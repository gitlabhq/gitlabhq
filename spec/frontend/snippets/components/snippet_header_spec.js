import {
  GlModal,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import {
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import SnippetHeader, { i18n } from '~/snippets/components/snippet_header.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import DeleteSnippetMutation from '~/snippets/mutations/delete_snippet.mutation.graphql';
import axios from '~/lib/utils/axios_utils';
import { createAlert, VARIANT_DANGER, VARIANT_SUCCESS } from '~/alert';
import CanCreateProjectSnippet from 'shared_queries/snippet/project_permissions.query.graphql';
import CanCreatePersonalSnippet from 'shared_queries/snippet/user_permissions.query.graphql';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
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

    wrapper = mountExtended(SnippetHeader, {
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
        CloneCodeDropdown,
        GlButton,
        GlDisclosureDropdown,
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
        GlIcon,
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      apolloProvider: mockApollo,
    });
  }

  const findAuthoredMessage = () => wrapper.findByTestId('authored-message').text();
  const findEditButton = () => wrapper.findByTestId('snippet-action-button');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemAt = (i) => findDropdownItems().at(i).props('item');
  const findSpamAction = () => wrapper.findByText('Submit as spam');
  const findDeleteAction = () => wrapper.findByText('Delete');
  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findDeleteModalDeleteAction = () => wrapper.findByTestId('delete-snippet-button');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => getBinding(findIcon().element, 'gl-tooltip');
  const findSpamIcon = () => wrapper.findByTestId('snippets-spam-icon');
  const findCodeDropdown = () => wrapper.findComponent(CloneCodeDropdown);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);

  const webUrl = 'http://foo.bar';
  const dummyHTTPUrl = webUrl;
  const dummySSHUrl = 'ssh://foo.bar';
  const title = 'The property of Thor';

  beforeEach(() => {
    gon.relative_url_root = '/foo/';
    snippet = {
      id: 'gid://gitlab/PersonalSnippet/50',
      title,
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
        username: null,
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

  it('renders snippets title', () => {
    createComponent();

    expect(wrapper.text().trim()).toContain(title);
  });

  it('does not render spam icon when author is not banned', () => {
    createComponent();

    expect(findSpamIcon().exists()).toBe(false);
  });

  it('renders a message showing snippet creation date and author full name, without username when not available', () => {
    createComponent();

    const text = findAuthoredMessage();
    expect(text).toContain('Authored 1 month ago by');
    expect(text).toContain('Thor Odinson');
  });

  it('renders a message showing snippet creation date and author full name', () => {
    snippet.author.username = 'todinson';
    createComponent();

    const text = findAuthoredMessage();
    expect(text).toContain('Authored 1 month ago by');
    expect(text).toContain('Thor Odinson');
  });

  it('renders a message showing only snippet creation date if author is null', () => {
    snippet.author = null;

    createComponent();

    const text = findAuthoredMessage();
    expect(text).toBe('Authored 1 month ago');
  });

  it('renders an edit button on sm and up screens', () => {
    createComponent();

    expect(findEditButton().attributes('href')).toEqual(`${snippet.webUrl}/edit`);
    expect(findEditButton().attributes('class')).toContain('gl-hidden');
    expect(findEditButton().attributes('class')).toContain('sm:gl-inline-flex');
  });

  it('renders dropdown for action buttons', () => {
    createComponent();

    expect(findDropdownItemAt(0).text).toBe('Edit');
    expect(findDropdownItemAt(0).href).toBe(`${snippet.webUrl}/edit`);
    expect(findDropdownItemAt(1).text).toBe('Submit as spam');
    expect(findDropdownItemAt(2).text).toBe('Delete');
  });

  describe('imported badge', () => {
    it('renders when snippet is imported', () => {
      createComponent({
        snippetProps: { imported: true },
      });

      expect(findImportedBadge().props('importableType')).toBe('snippet');
    });

    it('does not render when snippet is not imported', () => {
      createComponent({
        snippetProps: { imported: false },
      });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });

  it.each`
    permissions                                      | buttons
    ${{ adminSnippet: false, updateSnippet: false }} | ${['Submit as spam']}
    ${{ adminSnippet: true, updateSnippet: false }}  | ${['Submit as spam', 'Delete']}
    ${{ adminSnippet: false, updateSnippet: true }}  | ${['Edit', 'Submit as spam']}
  `('with permissions ($permissions), renders buttons ($buttons)', ({ permissions, buttons }) => {
    createComponent({
      permissions: {
        ...permissions,
      },
    });

    expect(findDropdownItems().wrappers.map((x) => x.props('item').text)).toEqual(buttons);
  });

  it('with canCreateSnippet permission, renders new snippet button', async () => {
    createComponent({
      canCreateProjectSnippetMock: jest
        .fn()
        .mockResolvedValue(getCanCreateProjectSnippetMock(true)),
      canCreatePersonalSnippetMock: jest
        .fn()
        .mockResolvedValue(getCanCreatePersonalSnippetMock(true)),
    });

    await waitForPromises();

    expect(findDropdownItemAt(1).text).toBe('New snippet');
    expect(findDropdownItemAt(1).href).toBe('/foo/-/snippets/new');
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
        mock.onPost(reportAbusePath).reply(request);
        findDropdown().trigger('click');
        findSpamAction().trigger('click');
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
      expect(findEditButton().exists()).toBe(false);
    });

    it('does not show action dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
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
    const openDeleteSnippetModal = async () => {
      // Click delete action
      findDropdown().trigger('click');
      findDeleteAction().trigger('click');

      await nextTick();
    };

    const deleteSnippet = async () => {
      await openDeleteSnippetModal();

      expect(findDeleteModal().props().visible).toBe(true);

      // Click delete button in delete modal
      findDeleteModalDeleteAction().trigger('click');

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

      expect(wrapper.findByTestId('delete-alert').text()).toBe(ERROR_MSG);
    });

    it('puts the `Delete snippet` modal button in the loading state on click', async () => {
      createComponent();

      expect(findDeleteModalDeleteAction().props('loading')).toBe(false);

      await openDeleteSnippetModal();
      findDeleteModalDeleteAction().trigger('click');
      await nextTick();

      expect(findDeleteModalDeleteAction().props('loading')).toBe(true);
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

  describe('when author of snippet is banned', () => {
    it('renders spam icon and tooltip', () => {
      createComponent({
        snippetProps: {
          hidden: true,
        },
      });

      expect(findIcon().props()).toMatchObject({
        ariaLabel: 'Hidden',
        name: 'spam',
        size: 16,
      });

      expect(findIcon().attributes('title')).toBe(
        'This snippet is hidden because its author has been banned',
      );

      expect(findTooltip()).toBeDefined();
    });
  });

  describe('Code button rendering', () => {
    it.each`
      httpUrlToRepo   | sshUrlToRepo   | shouldRender    | isRendered
      ${null}         | ${null}        | ${'Should not'} | ${false}
      ${null}         | ${dummySSHUrl} | ${'Should'}     | ${true}
      ${dummyHTTPUrl} | ${null}        | ${'Should'}     | ${true}
      ${dummyHTTPUrl} | ${dummySSHUrl} | ${'Should'}     | ${true}
    `(
      '$shouldRender render "Code" button when `httpUrlToRepo` is $httpUrlToRepo and `sshUrlToRepo` is $sshUrlToRepo',
      ({ httpUrlToRepo, sshUrlToRepo, isRendered }) => {
        createComponent({
          snippetProps: {
            sshUrlToRepo,
            httpUrlToRepo,
            webUrl,
          },
        });
        expect(findCodeDropdown().exists()).toBe(isRendered);
      },
    );

    it.each`
      snippetVisibility                   | projectVisibility                  | condition | embeddable
      ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${VISIBILITY_LEVEL_PUBLIC_STRING}  | ${'not'}  | ${false}
      ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${VISIBILITY_LEVEL_PUBLIC_STRING}  | ${'not'}  | ${false}
      ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${undefined}                       | ${''}     | ${true}
      ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${VISIBILITY_LEVEL_PUBLIC_STRING}  | ${''}     | ${true}
      ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${VISIBILITY_LEVEL_PUBLIC_STRING}  | ${'not'}  | ${false}
      ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${undefined}                       | ${'not'}  | ${false}
      ${'foo'}                            | ${undefined}                       | ${'not'}  | ${false}
      ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${VISIBILITY_LEVEL_PRIVATE_STRING} | ${'not'}  | ${false}
    `(
      'is $condition embeddable if snippetVisibility is $snippetVisibility and projectVisibility is $projectVisibility',
      ({ snippetVisibility, projectVisibility, embeddable }) => {
        createComponent({
          snippetProps: {
            sshUrlToRepo: dummySSHUrl,
            httpUrlToRepo: dummyHTTPUrl,
            visibilityLevel: snippetVisibility,
            webUrl,
            project: {
              visibility: projectVisibility,
            },
          },
        });
        expect(findCodeDropdown().props('embeddable')).toBe(embeddable);
      },
    );
  });
});
