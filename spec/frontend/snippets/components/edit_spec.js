import { shallowMount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import Flash from '~/flash';

import { GlLoadingIcon } from '@gitlab/ui';
import { joinPaths, redirectTo } from '~/lib/utils/url_utility';

import SnippetEditApp from '~/snippets/components/edit.vue';
import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import TitleField from '~/vue_shared/components/form/title.vue';
import FormFooterActions from '~/vue_shared/components/form/form_footer_actions.vue';
import { SNIPPET_CREATE_MUTATION_ERROR, SNIPPET_UPDATE_MUTATION_ERROR } from '~/snippets/constants';

import UpdateSnippetMutation from '~/snippets/mutations/updateSnippet.mutation.graphql';
import CreateSnippetMutation from '~/snippets/mutations/createSnippet.mutation.graphql';

import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { ApolloMutation } from 'vue-apollo';

jest.mock('~/lib/utils/url_utility', () => ({
  getBaseURL: jest.fn().mockReturnValue('foo/'),
  redirectTo: jest.fn().mockName('redirectTo'),
  joinPaths: jest
    .fn()
    .mockName('joinPaths')
    .mockReturnValue('contentApiURL'),
}));

jest.mock('~/flash');

let flashSpy;

const contentMock = 'Foo Bar';
const rawPathMock = '/foo/bar';
const rawProjectPathMock = '/project/path';
const newlyEditedSnippetUrl = 'http://foo.bar';
const apiError = { message: 'Ufff' };
const mutationError = 'Bummer';

const attachedFilePath1 = 'foo/bar';
const attachedFilePath2 = 'alpha/beta';

const defaultProps = {
  snippetGid: 'gid://gitlab/PersonalSnippet/42',
  markdownPreviewPath: 'http://preview.foo.bar',
  markdownDocsPath: 'http://docs.foo.bar',
};

describe('Snippet Edit app', () => {
  let wrapper;
  let axiosMock;

  const resolveMutate = jest.fn().mockResolvedValue({
    data: {
      updateSnippet: {
        errors: [],
        snippet: {
          webUrl: newlyEditedSnippetUrl,
        },
      },
    },
  });

  const resolveMutateWithErrors = jest.fn().mockResolvedValue({
    data: {
      updateSnippet: {
        errors: [mutationError],
        snippet: {
          webUrl: newlyEditedSnippetUrl,
        },
      },
      createSnippet: {
        errors: [mutationError],
        snippet: null,
      },
    },
  });

  const rejectMutation = jest.fn().mockRejectedValue(apiError);

  const mutationTypes = {
    RESOLVE: resolveMutate,
    RESOLVE_WITH_ERRORS: resolveMutateWithErrors,
    REJECT: rejectMutation,
  };

  function createComponent({
    props = defaultProps,
    data = {},
    loading = false,
    mutationRes = mutationTypes.RESOLVE,
  } = {}) {
    const $apollo = {
      queries: {
        snippet: {
          loading,
        },
      },
      mutate: mutationRes,
    };

    wrapper = shallowMount(SnippetEditApp, {
      mocks: { $apollo },
      stubs: {
        FormFooterActions,
        ApolloMutation,
      },
      propsData: {
        ...props,
      },
      data() {
        return data;
      },
    });

    flashSpy = jest.spyOn(wrapper.vm, 'flashAPIFailure');
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findSubmitButton = () => wrapper.find('[data-testid="snippet-submit-btn"]');
  const findCancellButton = () => wrapper.find('[data-testid="snippet-cancel-btn"]');
  const clickSubmitBtn = () => wrapper.find('[data-testid="snippet-edit-form"]').trigger('submit');

  describe('rendering', () => {
    it('renders loader while the query is in flight', () => {
      createComponent({ loading: true });
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders all required components', () => {
      createComponent();

      expect(wrapper.contains(TitleField)).toBe(true);
      expect(wrapper.contains(SnippetDescriptionEdit)).toBe(true);
      expect(wrapper.contains(SnippetBlobEdit)).toBe(true);
      expect(wrapper.contains(SnippetVisibilityEdit)).toBe(true);
      expect(wrapper.contains(FormFooterActions)).toBe(true);
    });

    it('does not fail if there is no snippet yet (new snippet creation)', () => {
      const snippetGid = '';
      createComponent({
        props: {
          ...defaultProps,
          snippetGid,
        },
      });

      expect(wrapper.props('snippetGid')).toBe(snippetGid);
    });

    it.each`
      title    | content  | expectation
      ${''}    | ${''}    | ${true}
      ${'foo'} | ${''}    | ${true}
      ${''}    | ${'foo'} | ${true}
      ${'foo'} | ${'bar'} | ${false}
    `(
      'disables submit button unless both title and content are present',
      ({ title, content, expectation }) => {
        createComponent({
          data: {
            snippet: { title },
            content,
          },
        });
        const isBtnDisabled = Boolean(findSubmitButton().attributes('disabled'));
        expect(isBtnDisabled).toBe(expectation);
      },
    );

    it.each`
      isNew    | status        | expectation
      ${true}  | ${`new`}      | ${`/snippets`}
      ${false} | ${`existing`} | ${newlyEditedSnippetUrl}
    `('sets correct href for the cancel button on a $status snippet', ({ isNew, expectation }) => {
      createComponent({
        data: {
          snippet: { webUrl: newlyEditedSnippetUrl },
          newSnippet: isNew,
        },
      });

      expect(findCancellButton().attributes('href')).toBe(expectation);
    });
  });

  describe('functionality', () => {
    describe('handling of the data from GraphQL response', () => {
      const snippet = {
        blob: {
          rawPath: rawPathMock,
        },
      };
      const getResSchema = newSnippet => {
        return {
          data: {
            snippets: {
              edges: newSnippet ? [] : [snippet],
            },
          },
        };
      };

      const bootstrapForExistingSnippet = resp => {
        createComponent({
          data: {
            snippet,
          },
        });

        if (resp === 500) {
          axiosMock.onGet('contentApiURL').reply(500);
        } else {
          axiosMock.onGet('contentApiURL').reply(200, contentMock);
        }
        wrapper.vm.onSnippetFetch(getResSchema());
      };

      const bootstrapForNewSnippet = () => {
        createComponent();
        wrapper.vm.onSnippetFetch(getResSchema(true));
      };

      beforeEach(() => {
        axiosMock = new AxiosMockAdapter(axios);
      });

      afterEach(() => {
        axiosMock.restore();
      });

      it('fetches blob content with the additional query', () => {
        bootstrapForExistingSnippet();

        return waitForPromises().then(() => {
          expect(joinPaths).toHaveBeenCalledWith('foo/', rawPathMock);
          expect(wrapper.vm.newSnippet).toBe(false);
          expect(wrapper.vm.content).toBe(contentMock);
        });
      });

      it('flashes the error message if fetching content fails', () => {
        bootstrapForExistingSnippet(500);

        return waitForPromises().then(() => {
          expect(flashSpy).toHaveBeenCalled();
          expect(wrapper.vm.content).toBe('');
        });
      });

      it('does not fetch content for new snippet', () => {
        bootstrapForNewSnippet();

        return waitForPromises().then(() => {
          // we keep using waitForPromises to make sure we do not run failed test
          expect(wrapper.vm.newSnippet).toBe(true);
          expect(wrapper.vm.content).toBe('');
          expect(joinPaths).not.toHaveBeenCalled();
          expect(wrapper.vm.snippet).toEqual(wrapper.vm.$options.newSnippetSchema);
        });
      });
    });

    describe('form submission handling', () => {
      it.each`
        newSnippet | projectPath           | mutation                 | mutationName
        ${true}    | ${rawProjectPathMock} | ${CreateSnippetMutation} | ${'CreateSnippetMutation with projectPath'}
        ${true}    | ${''}                 | ${CreateSnippetMutation} | ${'CreateSnippetMutation without projectPath'}
        ${false}   | ${rawProjectPathMock} | ${UpdateSnippetMutation} | ${'UpdateSnippetMutation with projectPath'}
        ${false}   | ${''}                 | ${UpdateSnippetMutation} | ${'UpdateSnippetMutation without projectPath'}
      `('should submit $mutationName correctly', ({ newSnippet, projectPath, mutation }) => {
        createComponent({
          data: {
            newSnippet,
          },
          props: {
            ...defaultProps,
            projectPath,
          },
        });

        const mutationPayload = {
          mutation,
          variables: {
            input: newSnippet ? expect.objectContaining({ projectPath }) : expect.any(Object),
          },
        };

        clickSubmitBtn();

        expect(resolveMutate).toHaveBeenCalledWith(mutationPayload);
      });

      it('redirects to snippet view on successful mutation', () => {
        createComponent();
        clickSubmitBtn();

        return waitForPromises().then(() => {
          expect(redirectTo).toHaveBeenCalledWith(newlyEditedSnippetUrl);
        });
      });

      it('makes sure there are no unsaved changes in the snippet', () => {
        createComponent();
        clickSubmitBtn();

        return waitForPromises().then(() => {
          expect(wrapper.vm.originalContent).toBe(wrapper.vm.content);
          expect(wrapper.vm.hasChanges()).toBe(false);
        });
      });

      it.each`
        newSnippet | projectPath           | mutationName
        ${true}    | ${rawProjectPathMock} | ${'CreateSnippetMutation with projectPath'}
        ${true}    | ${''}                 | ${'CreateSnippetMutation without projectPath'}
        ${false}   | ${rawProjectPathMock} | ${'UpdateSnippetMutation with projectPath'}
        ${false}   | ${''}                 | ${'UpdateSnippetMutation without projectPath'}
      `(
        'does not redirect to snippet view if the seemingly successful' +
          ' $mutationName response contains errors',
        ({ newSnippet, projectPath }) => {
          createComponent({
            data: {
              newSnippet,
            },
            props: {
              ...defaultProps,
              projectPath,
            },
            mutationRes: mutationTypes.RESOLVE_WITH_ERRORS,
          });

          clickSubmitBtn();

          return waitForPromises().then(() => {
            expect(redirectTo).not.toHaveBeenCalled();
            expect(flashSpy).toHaveBeenCalledWith(mutationError);
          });
        },
      );

      it('flashes an error if mutation failed', () => {
        createComponent({
          mutationRes: mutationTypes.REJECT,
        });

        clickSubmitBtn();

        return waitForPromises().then(() => {
          expect(redirectTo).not.toHaveBeenCalled();
          expect(flashSpy).toHaveBeenCalledWith(apiError);
        });
      });

      it.each`
        isNew    | status        | expectation
        ${true}  | ${`new`}      | ${SNIPPET_CREATE_MUTATION_ERROR.replace('%{err}', '')}
        ${false} | ${`existing`} | ${SNIPPET_UPDATE_MUTATION_ERROR.replace('%{err}', '')}
      `(
        `renders the correct error message if mutation fails for $status snippet`,
        ({ isNew, expectation }) => {
          createComponent({
            data: {
              newSnippet: isNew,
            },
            mutationRes: mutationTypes.REJECT,
          });

          clickSubmitBtn();

          return waitForPromises().then(() => {
            expect(Flash).toHaveBeenCalledWith(expect.stringContaining(expectation));
          });
        },
      );
    });

    describe('correctly includes attached files into the mutation', () => {
      const createMutationPayload = expectation => {
        return expect.objectContaining({
          variables: {
            input: expect.objectContaining({ uploadedFiles: expectation }),
          },
        });
      };

      const updateMutationPayload = () => {
        return expect.objectContaining({
          variables: {
            input: expect.not.objectContaining({ uploadedFiles: expect.anything() }),
          },
        });
      };

      it.each`
        paths                                     | expectation
        ${[attachedFilePath1]}                    | ${[attachedFilePath1]}
        ${[attachedFilePath1, attachedFilePath2]} | ${[attachedFilePath1, attachedFilePath2]}
        ${[]}                                     | ${[]}
      `(`correctly sends paths for $paths.length files`, ({ paths, expectation }) => {
        createComponent({
          data: {
            newSnippet: true,
          },
        });

        const fixtures = paths.map(path => {
          return path ? `<input name="files[]" value="${path}">` : undefined;
        });
        wrapper.vm.$el.innerHTML += fixtures.join('');

        clickSubmitBtn();

        expect(resolveMutate).toHaveBeenCalledWith(createMutationPayload(expectation));
      });

      it(`neither fails nor sends 'uploadedFiles' to update mutation`, () => {
        createComponent();

        clickSubmitBtn();
        expect(resolveMutate).toHaveBeenCalledWith(updateMutationPayload());
      });
    });

    describe('on before unload', () => {
      let event;
      let returnValueSetter;

      beforeEach(() => {
        createComponent();

        event = new Event('beforeunload');
        returnValueSetter = jest.spyOn(event, 'returnValue', 'set');
      });

      it('does not prevent page navigation if there are no changes to the snippet content', () => {
        window.dispatchEvent(event);

        expect(returnValueSetter).not.toHaveBeenCalled();
      });

      it('prevents page navigation if there are some changes in the snippet content', () => {
        wrapper.setData({ content: 'new content' });

        window.dispatchEvent(event);

        expect(returnValueSetter).toHaveBeenCalledWith(
          'Are you sure you want to lose unsaved changes?',
        );
      });
    });
  });
});
