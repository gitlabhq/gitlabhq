import { ApolloMutation } from 'vue-apollo';
import { GlButton, GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { Blob, BinaryBlob } from 'jest/blob/components/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteSnippetMutation from '~/snippets/mutations/deleteSnippet.mutation.graphql';
import SnippetHeader from '~/snippets/components/snippet_header.vue';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';

describe('Snippet header component', () => {
  let wrapper;
  let snippet;
  let mutationTypes;
  let mutationVariables;

  let errorMsg;
  let err;
  const originalRelativeUrlRoot = gon.relative_url_root;

  function createComponent({
    loading = false,
    permissions = {},
    mutationRes = mutationTypes.RESOLVE,
    snippetProps = {},
  } = {}) {
    const defaultProps = Object.assign(snippet, snippetProps);
    if (permissions) {
      Object.assign(defaultProps.userPermissions, {
        ...permissions,
      });
    }
    const $apollo = {
      queries: {
        canCreateSnippet: {
          loading,
        },
      },
      mutate: mutationRes,
    };

    wrapper = mount(SnippetHeader, {
      mocks: { $apollo },
      propsData: {
        snippet: {
          ...defaultProps,
        },
      },
      stubs: {
        ApolloMutation,
      },
    });
  }

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
      },
      blobs: [Blob],
      createdAt: new Date(differenceInMilliseconds(32 * 24 * 3600 * 1000)).toISOString(),
    };

    mutationVariables = {
      mutation: DeleteSnippetMutation,
      variables: {
        id: snippet.id,
      },
    };

    errorMsg = 'Foo bar';
    err = { message: errorMsg };

    mutationTypes = {
      RESOLVE: jest.fn(() => Promise.resolve({ data: { destroySnippet: { errors: [] } } })),
      REJECT: jest.fn(() => Promise.reject(err)),
    };
  });

  afterEach(() => {
    wrapper.destroy();
    gon.relative_url_root = originalRelativeUrlRoot;
  });

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.detail-page-header').exists()).toBe(true);
  });

  it('renders a message showing snippet creation date and author', () => {
    createComponent();

    const text = wrapper.find('[data-testid="authored-message"]').text();
    expect(text).toContain('Authored 1 month ago by');
    expect(text).toContain('Thor Odinson');
  });

  it('renders a message showing only snippet creation date if author is null', () => {
    snippet.author = null;

    createComponent();

    const text = wrapper.find('[data-testid="authored-message"]').text();
    expect(text).toBe('Authored 1 month ago');
  });

  it('renders action buttons based on permissions', () => {
    createComponent({
      permissions: {
        adminSnippet: false,
        updateSnippet: false,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(0);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: false,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(1);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: true,
      },
    });
    expect(wrapper.findAll(GlButton).length).toEqual(2);

    createComponent({
      permissions: {
        adminSnippet: true,
        updateSnippet: true,
      },
    });
    wrapper.setData({
      canCreateSnippet: true,
    });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.findAll(GlButton).length).toEqual(3);
    });
  });

  it('renders modal for deletion of a snippet', () => {
    createComponent();
    expect(wrapper.find(GlModal).exists()).toBe(true);
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
    const { location } = window;

    beforeEach(() => {
      delete window.location;
      window.location = {
        pathname: '',
      };
    });

    afterEach(() => {
      window.location = location;
    });

    it('dispatches a mutation to delete the snippet with correct variables', () => {
      createComponent();
      wrapper.vm.deleteSnippet();
      expect(mutationTypes.RESOLVE).toHaveBeenCalledWith(mutationVariables);
    });

    it('sets error message if mutation fails', async () => {
      createComponent({ mutationRes: mutationTypes.REJECT });
      expect(Boolean(wrapper.vm.errorMessage)).toBe(false);

      wrapper.vm.deleteSnippet();

      await waitForPromises();

      expect(wrapper.vm.errorMessage).toEqual(errorMsg);
    });

    describe('in case of successful mutation, closes modal and redirects to correct listing', () => {
      const createDeleteSnippet = (snippetProps = {}) => {
        createComponent({
          snippetProps,
        });
        wrapper.vm.closeDeleteModal = jest.fn();

        wrapper.vm.deleteSnippet();
        return wrapper.vm.$nextTick();
      };

      it('redirects to dashboard/snippets for personal snippet', () => {
        return createDeleteSnippet().then(() => {
          expect(wrapper.vm.closeDeleteModal).toHaveBeenCalled();
          expect(window.location.pathname).toBe(`${gon.relative_url_root}dashboard/snippets`);
        });
      });

      it('redirects to project snippets for project snippet', () => {
        const fullPath = 'foo/bar';
        return createDeleteSnippet({
          project: {
            fullPath,
          },
        }).then(() => {
          expect(wrapper.vm.closeDeleteModal).toHaveBeenCalled();
          expect(window.location.pathname).toBe(`${fullPath}/-/snippets`);
        });
      });
    });
  });
});
