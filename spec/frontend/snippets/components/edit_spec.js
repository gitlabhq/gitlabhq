import VueApollo, { ApolloMutation } from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import { deprecatedCreateFlash as Flash } from '~/flash';
import * as urlUtils from '~/lib/utils/url_utility';
import SnippetEditApp from '~/snippets/components/edit.vue';
import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import SnippetBlobActionsEdit from '~/snippets/components/snippet_blob_actions_edit.vue';
import TitleField from '~/vue_shared/components/form/title.vue';
import FormFooterActions from '~/vue_shared/components/form/form_footer_actions.vue';
import {
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_VISIBILITY_INTERNAL,
  SNIPPET_VISIBILITY_PUBLIC,
} from '~/snippets/constants';
import UpdateSnippetMutation from '~/snippets/mutations/updateSnippet.mutation.graphql';
import CreateSnippetMutation from '~/snippets/mutations/createSnippet.mutation.graphql';
import { testEntries } from '../test_utils';

jest.mock('~/flash');

const TEST_UPLOADED_FILES = ['foo/bar.txt', 'alpha/beta.js'];
const TEST_API_ERROR = 'Ufff';
const TEST_MUTATION_ERROR = 'Bummer';

const TEST_ACTIONS = {
  NO_CONTENT: {
    ...testEntries.created.diff,
    content: '',
  },
  NO_PATH: {
    ...testEntries.created.diff,
    filePath: '',
  },
  VALID: {
    ...testEntries.created.diff,
  },
};

const TEST_WEB_URL = '/snippets/7';

const createTestSnippet = () => ({
  webUrl: TEST_WEB_URL,
  id: 7,
  title: 'Snippet Title',
  description: 'Lorem ipsum snippet desc',
  visibilityLevel: SNIPPET_VISIBILITY_PRIVATE,
});

describe('Snippet Edit app', () => {
  let wrapper;
  let fakeApollo;
  const relativeUrlRoot = '/foo/';
  const originalRelativeUrlRoot = gon.relative_url_root;
  const GetSnippetQuerySpy = jest.fn().mockResolvedValue({
    data: { snippets: { nodes: [createTestSnippet()] } },
  });

  const mutationTypes = {
    RESOLVE: jest.fn().mockResolvedValue({
      data: {
        updateSnippet: {
          errors: [],
          snippet: createTestSnippet(),
        },
      },
    }),
    RESOLVE_WITH_ERRORS: jest.fn().mockResolvedValue({
      data: {
        updateSnippet: {
          errors: [TEST_MUTATION_ERROR],
          snippet: createTestSnippet(),
        },
        createSnippet: {
          errors: [TEST_MUTATION_ERROR],
          snippet: null,
        },
      },
    }),
    REJECT: jest.fn().mockRejectedValue(TEST_API_ERROR),
  };

  function createComponent({
    props = {},
    loading = false,
    mutationRes = mutationTypes.RESOLVE,
    selectedLevel = SNIPPET_VISIBILITY_PRIVATE,
    withApollo = false,
  } = {}) {
    let componentData = {
      mocks: {
        $apollo: {
          queries: {
            snippet: { loading },
          },
          mutate: mutationRes,
        },
      },
    };

    if (withApollo) {
      const localVue = createLocalVue();
      localVue.use(VueApollo);

      const requestHandlers = [[GetSnippetQuery, GetSnippetQuerySpy]];
      fakeApollo = createMockApollo(requestHandlers);
      componentData = {
        localVue,
        apolloProvider: fakeApollo,
      };
    }

    wrapper = shallowMount(SnippetEditApp, {
      ...componentData,
      stubs: {
        ApolloMutation,
        FormFooterActions,
      },
      provide: {
        selectedLevel,
      },
      propsData: {
        snippetGid: 'gid://gitlab/PersonalSnippet/42',
        markdownPreviewPath: 'http://preview.foo.bar',
        markdownDocsPath: 'http://docs.foo.bar',
        ...props,
      },
    });
  }

  beforeEach(() => {
    gon.relative_url_root = relativeUrlRoot;
    jest.spyOn(urlUtils, 'redirectTo').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    gon.relative_url_root = originalRelativeUrlRoot;
  });

  const findBlobActions = () => wrapper.find(SnippetBlobActionsEdit);
  const findSubmitButton = () => wrapper.find('[data-testid="snippet-submit-btn"]');
  const findCancelButton = () => wrapper.find('[data-testid="snippet-cancel-btn"]');
  const hasDisabledSubmit = () => Boolean(findSubmitButton().attributes('disabled'));

  const clickSubmitBtn = () => wrapper.find('[data-testid="snippet-edit-form"]').trigger('submit');
  const triggerBlobActions = actions => findBlobActions().vm.$emit('actions', actions);
  const setUploadFilesHtml = paths => {
    wrapper.vm.$el.innerHTML = paths.map(path => `<input name="files[]" value="${path}">`).join('');
  };
  const getApiData = ({
    id,
    title = '',
    description = '',
    visibilityLevel = SNIPPET_VISIBILITY_PRIVATE,
  } = {}) => ({
    id,
    title,
    description,
    visibilityLevel,
    blobActions: [],
  });

  // Ideally we wouldn't call this method directly, but we don't have a way to trigger
  // apollo responses yet.
  const loadSnippet = (...nodes) => {
    if (nodes.length) {
      wrapper.setData({
        snippet: nodes[0],
        newSnippet: false,
      });
    } else {
      wrapper.setData({
        newSnippet: true,
      });
    }
  };

  describe('rendering', () => {
    it('renders loader while the query is in flight', () => {
      createComponent({ loading: true });
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it.each([[{}], [{ snippetGid: '' }]])(
      'should render all required components with %s',
      props => {
        createComponent(props);

        expect(wrapper.find(TitleField).exists()).toBe(true);
        expect(wrapper.find(SnippetDescriptionEdit).exists()).toBe(true);
        expect(wrapper.find(SnippetVisibilityEdit).exists()).toBe(true);
        expect(wrapper.find(FormFooterActions).exists()).toBe(true);
        expect(findBlobActions().exists()).toBe(true);
      },
    );

    it.each`
      title    | actions                                          | shouldDisable
      ${''}    | ${[]}                                            | ${true}
      ${''}    | ${[TEST_ACTIONS.VALID]}                          | ${true}
      ${'foo'} | ${[]}                                            | ${false}
      ${'foo'} | ${[TEST_ACTIONS.VALID]}                          | ${false}
      ${'foo'} | ${[TEST_ACTIONS.VALID, TEST_ACTIONS.NO_CONTENT]} | ${true}
      ${'foo'} | ${[TEST_ACTIONS.VALID, TEST_ACTIONS.NO_PATH]}    | ${false}
    `(
      'should handle submit disable (title=$title, actions=$actions, shouldDisable=$shouldDisable)',
      async ({ title, actions, shouldDisable }) => {
        createComponent();

        loadSnippet({ title });
        triggerBlobActions(actions);

        await wrapper.vm.$nextTick();

        expect(hasDisabledSubmit()).toBe(shouldDisable);
      },
    );

    it.each`
      projectPath       | snippetArg               | expectation
      ${''}             | ${[]}                    | ${urlUtils.joinPaths('/', relativeUrlRoot, '-', 'snippets')}
      ${'project/path'} | ${[]}                    | ${urlUtils.joinPaths('/', relativeUrlRoot, 'project/path/-', 'snippets')}
      ${''}             | ${[createTestSnippet()]} | ${TEST_WEB_URL}
      ${'project/path'} | ${[createTestSnippet()]} | ${TEST_WEB_URL}
    `(
      'should set cancel href when (projectPath=$projectPath, snippet=$snippetArg)',
      async ({ projectPath, snippetArg, expectation }) => {
        createComponent({
          props: { projectPath },
        });

        loadSnippet(...snippetArg);

        await wrapper.vm.$nextTick();

        expect(findCancelButton().attributes('href')).toBe(expectation);
      },
    );
  });

  describe('functionality', () => {
    it('does not fetch snippet when create a new snippet', async () => {
      createComponent({ props: { snippetGid: '' }, withApollo: true });

      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();

      expect(GetSnippetQuerySpy).not.toHaveBeenCalled();
    });

    describe('default visibility', () => {
      it.each([SNIPPET_VISIBILITY_PRIVATE, SNIPPET_VISIBILITY_INTERNAL, SNIPPET_VISIBILITY_PUBLIC])(
        'marks %s visibility by default',
        async visibility => {
          createComponent({
            props: { snippetGid: '' },
            selectedLevel: visibility,
          });
          expect(wrapper.vm.snippet.visibilityLevel).toEqual(visibility);
        },
      );
    });

    describe('form submission handling', () => {
      it.each`
        snippetArg               | projectPath       | uploadedFiles          | input                                                                       | mutation
        ${[]}                    | ${'project/path'} | ${[]}                  | ${{ ...getApiData(), projectPath: 'project/path', uploadedFiles: [] }}      | ${CreateSnippetMutation}
        ${[]}                    | ${''}             | ${[]}                  | ${{ ...getApiData(), projectPath: '', uploadedFiles: [] }}                  | ${CreateSnippetMutation}
        ${[]}                    | ${''}             | ${TEST_UPLOADED_FILES} | ${{ ...getApiData(), projectPath: '', uploadedFiles: TEST_UPLOADED_FILES }} | ${CreateSnippetMutation}
        ${[createTestSnippet()]} | ${'project/path'} | ${[]}                  | ${getApiData(createTestSnippet())}                                          | ${UpdateSnippetMutation}
        ${[createTestSnippet()]} | ${''}             | ${[]}                  | ${getApiData(createTestSnippet())}                                          | ${UpdateSnippetMutation}
      `(
        'should submit mutation with (snippet=$snippetArg, projectPath=$projectPath, uploadedFiles=$uploadedFiles)',
        async ({ snippetArg, projectPath, uploadedFiles, mutation, input }) => {
          createComponent({
            props: {
              projectPath,
            },
          });
          loadSnippet(...snippetArg);
          setUploadFilesHtml(uploadedFiles);

          await wrapper.vm.$nextTick();

          clickSubmitBtn();

          expect(mutationTypes.RESOLVE).toHaveBeenCalledWith({
            mutation,
            variables: {
              input,
            },
          });
        },
      );

      it('should redirect to snippet view on successful mutation', async () => {
        createComponent();
        loadSnippet(createTestSnippet());

        clickSubmitBtn();

        await waitForPromises();

        expect(urlUtils.redirectTo).toHaveBeenCalledWith(TEST_WEB_URL);
      });

      it.each`
        snippetArg               | projectPath       | mutationRes                          | expectMessage
        ${[]}                    | ${'project/path'} | ${mutationTypes.RESOLVE_WITH_ERRORS} | ${`Can't create snippet: ${TEST_MUTATION_ERROR}`}
        ${[]}                    | ${''}             | ${mutationTypes.RESOLVE_WITH_ERRORS} | ${`Can't create snippet: ${TEST_MUTATION_ERROR}`}
        ${[]}                    | ${''}             | ${mutationTypes.REJECT}              | ${`Can't create snippet: ${TEST_API_ERROR}`}
        ${[createTestSnippet()]} | ${'project/path'} | ${mutationTypes.RESOLVE_WITH_ERRORS} | ${`Can't update snippet: ${TEST_MUTATION_ERROR}`}
        ${[createTestSnippet()]} | ${''}             | ${mutationTypes.RESOLVE_WITH_ERRORS} | ${`Can't update snippet: ${TEST_MUTATION_ERROR}`}
      `(
        'should flash error with (snippet=$snippetArg, projectPath=$projectPath)',
        async ({ snippetArg, projectPath, mutationRes, expectMessage }) => {
          createComponent({
            props: {
              projectPath,
            },
            mutationRes,
          });
          loadSnippet(...snippetArg);

          clickSubmitBtn();

          await waitForPromises();

          expect(urlUtils.redirectTo).not.toHaveBeenCalled();
          expect(Flash).toHaveBeenCalledWith(expectMessage);
        },
      );
    });

    describe('on before unload', () => {
      it.each`
        condition                       | expectPrevented | action
        ${'there are no actions'}       | ${false}        | ${() => triggerBlobActions([])}
        ${'there are actions'}          | ${true}         | ${() => triggerBlobActions([testEntries.updated.diff])}
        ${'the snippet is being saved'} | ${false}        | ${() => clickSubmitBtn()}
      `(
        'handles before unload prevent when $condition (expectPrevented=$expectPrevented)',
        ({ expectPrevented, action }) => {
          createComponent();
          loadSnippet();

          action();

          const event = new Event('beforeunload');
          const returnValueSetter = jest.spyOn(event, 'returnValue', 'set');

          window.dispatchEvent(event);

          if (expectPrevented) {
            expect(returnValueSetter).toHaveBeenCalledWith(
              'Are you sure you want to lose unsaved changes?',
            );
          } else {
            expect(returnValueSetter).not.toHaveBeenCalled();
          }
        },
      );
    });
  });
});
