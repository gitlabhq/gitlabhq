import { GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { merge } from 'lodash';

import VueApollo, { ApolloMutation } from 'vue-apollo';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubPerformanceWebAPI } from 'helpers/performance';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import { createAlert } from '~/alert';
import * as urlUtils from '~/lib/utils/url_utility';
import SnippetEditApp from '~/snippets/components/edit.vue';
import SnippetBlobActionsEdit from '~/snippets/components/snippet_blob_actions_edit.vue';
import SnippetDescriptionEdit from '~/snippets/components/snippet_description_edit.vue';
import SnippetVisibilityEdit from '~/snippets/components/snippet_visibility_edit.vue';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import CreateSnippetMutation from '~/snippets/mutations/create_snippet.mutation.graphql';
import UpdateSnippetMutation from '~/snippets/mutations/update_snippet.mutation.graphql';
import FormFooterActions from '~/snippets/components/form_footer_actions.vue';
import { testEntries, createGQLSnippetsQueryResponse, createGQLSnippet } from '../test_utils';

jest.mock('~/alert');

const TEST_UPLOADED_FILES = ['foo/bar.txt', 'alpha/beta.js'];
const TEST_API_ERROR = new Error('TEST_API_ERROR');
const TEST_MUTATION_ERROR = 'Test mutation error';
const TEST_ACTIONS = {
  NO_CONTENT: merge({}, testEntries.created.diff, { content: '' }),
  NO_PATH: merge({}, testEntries.created.diff, { filePath: '' }),
  VALID: merge({}, testEntries.created.diff),
};
const TEST_WEB_URL = '/snippets/7';
const TEST_SNIPPET_GID = 'gid://gitlab/PersonalSnippet/42';

const createSnippet = () =>
  merge(createGQLSnippet(), {
    webUrl: TEST_WEB_URL,
    visibilityLevel: VISIBILITY_LEVEL_PRIVATE_STRING,
  });

const createQueryResponse = (obj = {}) =>
  createGQLSnippetsQueryResponse([merge(createSnippet(), obj)]);

const createMutationResponse = (key, obj = {}) => ({
  data: {
    [key]: merge(
      {
        errors: [],
        snippet: {
          __typename: 'Snippet',
          id: 1,
          webUrl: TEST_WEB_URL,
        },
      },
      obj,
    ),
  },
});

const createMutationResponseWithErrors = (key) =>
  createMutationResponse(key, { errors: [TEST_MUTATION_ERROR] });

const getApiData = ({
  id,
  title = '',
  description = '',
  visibilityLevel = VISIBILITY_LEVEL_PRIVATE_STRING,
} = {}) => ({
  id,
  title,
  description,
  visibilityLevel,
  blobActions: [],
});

Vue.use(VueApollo);

describe('Snippet Edit app', () => {
  useFakeDate();

  let wrapper;
  let getSpy;

  // Mutate spy receives a "key" so that we can:
  // - Use the same spy whether we are creating or updating.
  // - Build the correct response object
  // - Assert which mutation was sent
  let mutateSpy;

  const relativeUrlRoot = '/foo/';

  beforeEach(() => {
    stubPerformanceWebAPI();

    getSpy = jest.fn().mockResolvedValue(createQueryResponse());

    // See `mutateSpy` declaration comment for why we send a key
    mutateSpy = jest.fn().mockImplementation((key) => Promise.resolve(createMutationResponse(key)));

    gon.relative_url_root = relativeUrlRoot;
    jest.spyOn(urlUtils, 'visitUrl').mockImplementation();
  });

  const findBlobActions = () => wrapper.findComponent(SnippetBlobActionsEdit);
  const findCancelButton = () => wrapper.findByTestId('snippet-cancel-btn');
  const clickSubmitBtn = () => wrapper.findByTestId('snippet-edit-form').trigger('submit');

  const triggerBlobActions = (actions) => findBlobActions().vm.$emit('actions', actions);
  const setUploadFilesHtml = (paths) => {
    wrapper.element.innerHTML = paths
      .map((path) => `<input name="files[]" value="${path}">`)
      .join('');
  };
  const setTitle = (val) =>
    wrapper.findByTestId('snippet-title-input-field').vm.$emit('input', val);
  const setDescription = (val) =>
    wrapper.findComponent(SnippetDescriptionEdit).vm.$emit('input', val);

  const createComponent = ({
    props = {},
    selectedLevel = VISIBILITY_LEVEL_PRIVATE_STRING,
  } = {}) => {
    const requestHandlers = [
      [GetSnippetQuery, getSpy],
      // See `mutateSpy` declaration comment for why we send a key
      [UpdateSnippetMutation, (...args) => mutateSpy('updateSnippet', ...args)],
      [CreateSnippetMutation, (...args) => mutateSpy('createSnippet', ...args)],
    ];
    const apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(SnippetEditApp, {
      apolloProvider,
      stubs: {
        ApolloMutation,
        FormFooterActions,
      },
      provide: {
        selectedLevel,
      },
      propsData: {
        snippetGid: TEST_SNIPPET_GID,
        markdownPreviewPath: 'http://preview.foo.bar',
        markdownDocsPath: 'http://docs.foo.bar',
        ...props,
      },
    });
  };

  // Creates comopnent and waits for gql load
  const createComponentAndLoad = async (...args) => {
    createComponent(...args);

    await waitForPromises();
  };

  // Creates loaded component and submits form
  const createComponentAndSubmit = async (...args) => {
    await createComponentAndLoad(...args);

    clickSubmitBtn();

    await waitForPromises();
  };

  describe('when loading', () => {
    it('renders loader', () => {
      createComponent();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe.each`
    snippetGid          | expectedQueries
    ${TEST_SNIPPET_GID} | ${[[{ ids: [TEST_SNIPPET_GID] }]]}
    ${''}               | ${[]}
  `('when loaded with snippetGid=$snippetGid', ({ snippetGid, expectedQueries }) => {
    beforeEach(() => createComponentAndLoad({ props: { snippetGid } }));

    it(`queries with ${JSON.stringify(expectedQueries)}`, () => {
      expect(getSpy.mock.calls).toEqual(expectedQueries);
    });

    it('should render components', () => {
      expect(wrapper.findComponent(GlFormGroup).attributes('label')).toEqual('Title');
      expect(wrapper.findComponent(SnippetDescriptionEdit).exists()).toBe(true);
      expect(wrapper.findComponent(SnippetVisibilityEdit).exists()).toBe(true);
      expect(wrapper.findComponent(FormFooterActions).exists()).toBe(true);
      expect(findBlobActions().exists()).toBe(true);
    });

    it('should hide loader', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });
  });

  describe('default', () => {
    it.each`
      title    | actions                                          | titleHasErrors | blobActionsHasErrors
      ${''}    | ${[]}                                            | ${true}        | ${false}
      ${''}    | ${[TEST_ACTIONS.VALID]}                          | ${true}        | ${false}
      ${'foo'} | ${[]}                                            | ${false}       | ${false}
      ${'foo'} | ${[TEST_ACTIONS.VALID]}                          | ${false}       | ${false}
      ${'foo'} | ${[TEST_ACTIONS.VALID, TEST_ACTIONS.NO_CONTENT]} | ${false}       | ${true}
      ${'foo'} | ${[TEST_ACTIONS.VALID, TEST_ACTIONS.NO_PATH]}    | ${false}       | ${false}
    `(
      'validates correctly (title="$title", actions="$actions", titleHasErrors="$titleHasErrors", blobActionsHasErrors="$blobActionsHasErrors")',
      async ({ title, actions, titleHasErrors, blobActionsHasErrors }) => {
        getSpy.mockResolvedValue(createQueryResponse({ title }));

        await createComponentAndLoad();

        triggerBlobActions(actions);

        clickSubmitBtn();

        await nextTick();

        expect(wrapper.findComponent(GlFormGroup).exists()).toBe(true);
        expect(Boolean(wrapper.findComponent(GlFormGroup).attributes('state'))).toEqual(
          !titleHasErrors,
        );

        expect(wrapper.findComponent(SnippetBlobActionsEdit).props('isValid')).toEqual(
          !blobActionsHasErrors,
        );
      },
    );

    it.each`
      projectPath       | snippetGid          | expectation
      ${''}             | ${''}               | ${urlUtils.joinPaths('/', relativeUrlRoot, '-', 'snippets')}
      ${'project/path'} | ${''}               | ${urlUtils.joinPaths('/', relativeUrlRoot, 'project/path/-', 'snippets')}
      ${''}             | ${TEST_SNIPPET_GID} | ${TEST_WEB_URL}
      ${'project/path'} | ${TEST_SNIPPET_GID} | ${TEST_WEB_URL}
    `(
      'should set cancel href (projectPath="$projectPath", snippetGid="$snippetGid")',
      async ({ projectPath, snippetGid, expectation }) => {
        await createComponentAndLoad({
          props: {
            projectPath,
            snippetGid,
          },
        });

        expect(findCancelButton().attributes('href')).toBe(expectation);
      },
    );

    it.each([
      VISIBILITY_LEVEL_PRIVATE_STRING,
      VISIBILITY_LEVEL_INTERNAL_STRING,
      VISIBILITY_LEVEL_PUBLIC_STRING,
    ])('marks %s visibility by default', (visibility) => {
      createComponent({
        props: { snippetGid: '' },
        selectedLevel: visibility,
      });

      expect(wrapper.findComponent(SnippetVisibilityEdit).props('value')).toBe(visibility);
    });

    describe('form submission handling', () => {
      describe('when creating a new snippet', () => {
        it.each`
          projectPath       | uploadedFiles          | input
          ${''}             | ${TEST_UPLOADED_FILES} | ${{ ...getApiData({ title: 'Title' }), projectPath: '', uploadedFiles: TEST_UPLOADED_FILES }}
          ${'project/path'} | ${TEST_UPLOADED_FILES} | ${{ ...getApiData({ title: 'Title' }), projectPath: 'project/path', uploadedFiles: TEST_UPLOADED_FILES }}
        `(
          'should submit a createSnippet mutation (projectPath=$projectPath, uploadedFiles=$uploadedFiles)',
          async ({ projectPath, uploadedFiles, input }) => {
            await createComponentAndLoad({
              props: {
                snippetGid: '',
                projectPath,
              },
            });

            setTitle(input.title);
            setUploadFilesHtml(uploadedFiles);

            await nextTick();

            clickSubmitBtn();

            expect(mutateSpy).toHaveBeenCalledTimes(1);
            expect(mutateSpy).toHaveBeenCalledWith('createSnippet', {
              input,
            });
          },
        );
      });

      describe('when updating a snippet', () => {
        it.each`
          projectPath       | uploadedFiles | input
          ${''}             | ${[]}         | ${getApiData(createSnippet())}
          ${'project/path'} | ${[]}         | ${getApiData(createSnippet())}
        `(
          'should submit an updateSnippet mutation (projectPath=$projectPath, uploadedFiles=$uploadedFiles)',
          async ({ projectPath, uploadedFiles, input }) => {
            await createComponentAndLoad({
              props: {
                snippetGid: TEST_SNIPPET_GID,
                projectPath,
              },
            });

            setUploadFilesHtml(uploadedFiles);

            await nextTick();

            clickSubmitBtn();

            expect(mutateSpy).toHaveBeenCalledTimes(1);
            expect(mutateSpy).toHaveBeenCalledWith('updateSnippet', {
              input,
            });
          },
        );
      });

      it('should redirect to snippet view on successful mutation', async () => {
        await createComponentAndSubmit();

        expect(urlUtils.visitUrl).toHaveBeenCalledWith(TEST_WEB_URL);
      });

      describe('when there are errors after creating a new snippet', () => {
        it.each`
          projectPath
          ${'project/path'}
          ${''}
        `('should alert error (projectPath=$projectPath)', async ({ projectPath }) => {
          mutateSpy.mockResolvedValue(createMutationResponseWithErrors('createSnippet'));

          await createComponentAndLoad({
            props: { projectPath, snippetGid: '' },
          });

          setTitle('Title');

          clickSubmitBtn();

          await waitForPromises();

          expect(urlUtils.visitUrl).not.toHaveBeenCalled();
          expect(createAlert).toHaveBeenCalledWith({
            message: `Can't create snippet: ${TEST_MUTATION_ERROR}`,
          });
        });
      });

      describe('when there are errors after updating a snippet', () => {
        it.each`
          projectPath
          ${'project/path'}
          ${''}
        `(
          'should alert error with (snippet=$snippetGid, projectPath=$projectPath)',
          async ({ projectPath }) => {
            mutateSpy.mockResolvedValue(createMutationResponseWithErrors('updateSnippet'));

            await createComponentAndSubmit({
              props: {
                projectPath,
                snippetGid: TEST_SNIPPET_GID,
              },
            });

            expect(urlUtils.visitUrl).not.toHaveBeenCalled();
            expect(createAlert).toHaveBeenCalledWith({
              message: `Can't update snippet: ${TEST_MUTATION_ERROR}`,
            });
          },
        );
      });

      describe('with apollo network error', () => {
        beforeEach(async () => {
          jest.spyOn(console, 'error').mockImplementation();
          mutateSpy.mockRejectedValue(TEST_API_ERROR);

          await createComponentAndSubmit();
          await nextTick();
        });

        it('should not redirect', () => {
          expect(urlUtils.visitUrl).not.toHaveBeenCalled();
        });

        it('should alert', () => {
          // Apollo automatically wraps the resolver's error in a NetworkError
          expect(createAlert).toHaveBeenCalledWith({
            message: `Can't update snippet: ${TEST_API_ERROR.message}`,
          });
        });

        it('should console error', () => {
          // eslint-disable-next-line no-console
          expect(console.error).toHaveBeenCalledTimes(1);
          // eslint-disable-next-line no-console
          expect(console.error).toHaveBeenCalledWith(
            '[gitlab] unexpected error while updating snippet',
            expect.objectContaining({ message: `${TEST_API_ERROR.message}` }),
          );
        });
      });
    });
  });

  describe('on before unload', () => {
    it.each([
      ['there are no actions', false, () => triggerBlobActions([])],
      ['there is an empty action', false, () => triggerBlobActions([testEntries.empty.diff])],
      ['there are actions', true, () => triggerBlobActions([testEntries.updated.diff])],
      [
        'the title is set',
        true,
        () => {
          triggerBlobActions([testEntries.empty.diff]);
          setTitle('test');
        },
      ],
      [
        'the description is set',
        true,
        () => {
          triggerBlobActions([testEntries.empty.diff]);
          setDescription('test');
        },
      ],
      [
        'the snippet is being saved',
        false,
        () => {
          triggerBlobActions([testEntries.updated.diff]);
          setTitle('test');
          clickSubmitBtn();
        },
      ],
    ])(
      'handles before unload prevent when %s (expectPrevented=%s)',
      async (_, expectPrevented, action) => {
        await createComponentAndLoad({
          props: {
            snippetGid: '',
          },
        });

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
