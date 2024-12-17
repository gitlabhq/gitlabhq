import { GlButton, GlFormGroup } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { mountExtended } from 'jest/__helpers__/vue_test_utils_helper';
import CommitStep, { i18n } from '~/pipeline_wizard/components/commit.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import createCommitMutation from '~/pipeline_wizard/queries/create_commit.graphql';
import getFileMetadataQuery from '~/pipeline_wizard/queries/get_file_meta.graphql';
import RefSelector from '~/ref/components/ref_selector.vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  createCommitMutationErrorResult,
  createCommitMutationResult,
  fileQueryErrorResult,
  fileQueryResult,
  fileQueryEmptyResult,
} from '../mock/query_responses';

Vue.use(VueApollo);

const COMMIT_MESSAGE_ADD_FILE = 'Add %{filename}';
const COMMIT_MESSAGE_UPDATE_FILE = 'Update %{filename}';

describe('Pipeline Wizard - Commit Page', () => {
  const createCommitMutationHandler = jest.fn();
  const $toast = {
    show: jest.fn(),
  };

  let wrapper;

  const getMockApollo = (scenario = {}) => {
    return createMockApollo([
      [
        createCommitMutation,
        createCommitMutationHandler.mockResolvedValue(
          scenario.commitHasError ? createCommitMutationErrorResult : createCommitMutationResult,
        ),
      ],
      [
        getFileMetadataQuery,
        (vars) => {
          if (scenario.fileResultByRef) return scenario.fileResultByRef[vars.ref];
          if (scenario.hasError) return fileQueryErrorResult;
          return scenario.fileExists ? fileQueryResult : fileQueryEmptyResult;
        },
      ],
    ]);
  };
  const createComponent = (props = {}, mockApollo = getMockApollo()) => {
    wrapper = mountExtended(CommitStep, {
      apolloProvider: mockApollo,
      propsData: {
        projectPath: 'some/path',
        defaultBranch: 'main',
        filename: 'newFile.yml',
        ...props,
      },
      mocks: { $toast },
      stubs: {
        RefSelector: true,
        GlFormGroup,
      },
    });
  };

  function getButtonWithLabel(label) {
    return wrapper.findAllComponents(GlButton).wrappers.find((n) => n.text().match(label));
  }

  describe('ui setup', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a commit message input with the correct label', () => {
      expect(wrapper.findByTestId('commit_message').exists()).toBe(true);
      expect(wrapper.find('label[for="commit_message"]').text()).toBe(i18n.commitMessageLabel);
    });

    it('shows a branch selector with the correct label', () => {
      expect(wrapper.findByTestId('branch').exists()).toBe(true);
      expect(wrapper.find('label[for="branch"]').text()).toBe(i18n.branchSelectorLabel);
    });

    it('shows a commit button', () => {
      expect(getButtonWithLabel(i18n.commitButtonLabel).exists()).toBe(true);
    });

    it('shows a back button', () => {
      expect(getButtonWithLabel('Back').exists()).toBe(true);
    });

    it('does not show a next button', () => {
      expect(getButtonWithLabel('Next')).toBeUndefined();
    });
  });

  describe('loading the remote file', () => {
    const projectPath = 'foo/bar';
    const filename = 'foo.yml';

    it('does not show a load error if call is successful', async () => {
      createComponent({ projectPath, filename });
      await waitForPromises();
      expect(wrapper.findByTestId('load-error').exists()).not.toBe(true);
    });

    it('shows a load error if call returns an unexpected error', async () => {
      const branch = 'foo';
      createComponent(
        { defaultBranch: branch, projectPath, filename },
        createMockApollo([[getFileMetadataQuery, () => fileQueryErrorResult]]),
      );
      await waitForPromises();
      expect(wrapper.findByTestId('load-error').exists()).toBe(true);
      expect(wrapper.findByTestId('load-error').text()).toBe(i18n.errors.loadError);
    });
  });

  describe('commit result handling', () => {
    describe('successful commit', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
        await getButtonWithLabel('Commit').trigger('click');
        await waitForPromises();
      });

      it('will not show an error', () => {
        expect(wrapper.findByTestId('commit-error').exists()).not.toBe(true);
      });

      it('will show a toast message', () => {
        expect($toast.show).toHaveBeenCalledWith('The file has been committed.');
      });

      it('emits a done event', () => {
        expect(wrapper.emitted().done.length).toBe(1);
      });
    });

    describe('failed commit', () => {
      beforeEach(async () => {
        createComponent({}, getMockApollo({ commitHasError: true }));
        await waitForPromises();
        await getButtonWithLabel('Commit').trigger('click');
        await waitForPromises();
      });

      it('will show an error', () => {
        expect(wrapper.findByTestId('commit-error').exists()).toBe(true);
        expect(wrapper.findByTestId('commit-error').text()).toBe(i18n.errors.commitError);
      });

      it('will not show a toast message', () => {
        expect($toast.show).not.toHaveBeenCalledWith(i18n.commitSuccessMessage);
      });

      it('will not emit a done event', () => {
        expect(wrapper.emitted().done?.length).toBeUndefined();
      });
    });
  });

  describe('modelling different input combinations', () => {
    const projectPath = 'some/path';
    const defaultBranch = 'foo';
    const fileContent = 'foo: bar';

    describe.each`
      filename     | fileExistsOnDefaultBranch | fileExistsOnInputtedBranch | fileLoadError | commitMessageInputValue | branchInputValue | expectedCommitBranch | expectedCommitMessage         | expectedAction
      ${'foo.yml'} | ${false}                  | ${undefined}               | ${false}      | ${'foo'}                | ${undefined}     | ${defaultBranch}     | ${'foo'}                      | ${'CREATE'}
      ${'foo.yml'} | ${true}                   | ${undefined}               | ${false}      | ${'foo'}                | ${undefined}     | ${defaultBranch}     | ${'foo'}                      | ${'UPDATE'}
      ${'foo.yml'} | ${false}                  | ${true}                    | ${false}      | ${'foo'}                | ${'dev'}         | ${'dev'}             | ${'foo'}                      | ${'UPDATE'}
      ${'foo.yml'} | ${false}                  | ${undefined}               | ${false}      | ${null}                 | ${undefined}     | ${defaultBranch}     | ${COMMIT_MESSAGE_ADD_FILE}    | ${'CREATE'}
      ${'foo.yml'} | ${true}                   | ${undefined}               | ${false}      | ${null}                 | ${undefined}     | ${defaultBranch}     | ${COMMIT_MESSAGE_UPDATE_FILE} | ${'UPDATE'}
      ${'foo.yml'} | ${false}                  | ${true}                    | ${false}      | ${null}                 | ${'dev'}         | ${'dev'}             | ${COMMIT_MESSAGE_UPDATE_FILE} | ${'UPDATE'}
    `(
      'Test with fileExistsOnDefaultBranch=$fileExistsOnDefaultBranch, fileExistsOnInputtedBranch=$fileExistsOnInputtedBranch, commitMessageInputValue=$commitMessageInputValue, branchInputValue=$branchInputValue, commitReturnsError=$commitReturnsError',
      ({
        filename,
        fileExistsOnDefaultBranch,
        fileExistsOnInputtedBranch,
        commitMessageInputValue,
        branchInputValue,
        expectedCommitBranch,
        expectedCommitMessage,
        expectedAction,
      }) => {
        let consoleSpy;

        beforeEach(async () => {
          createComponent(
            {
              filename,
              defaultBranch,
              projectPath,
              fileContent,
            },
            getMockApollo({
              fileResultByRef: {
                [defaultBranch]: fileExistsOnDefaultBranch ? fileQueryResult : fileQueryEmptyResult,
                [branchInputValue]: fileExistsOnInputtedBranch
                  ? fileQueryResult
                  : fileQueryEmptyResult,
              },
            }),
          );

          await waitForPromises();

          consoleSpy = jest.spyOn(console, 'error');

          await wrapper
            .findByTestId('commit_message')
            .get('textarea')
            .setValue(commitMessageInputValue);

          if (branchInputValue) {
            await wrapper.getComponent(RefSelector).vm.$emit('input', branchInputValue);
          }
          await Vue.nextTick();

          await waitForPromises();
        });

        it('sets up without error', () => {
          expect(consoleSpy).not.toHaveBeenCalled();
        });

        it('does not show a load error', () => {
          expect(wrapper.findByTestId('load-error').exists()).not.toBe(true);
        });

        it('sends the expected commit mutation', async () => {
          await getButtonWithLabel('Commit').trigger('click');

          expect(createCommitMutationHandler).toHaveBeenCalledWith({
            input: {
              actions: [
                {
                  action: expectedAction,
                  content: fileContent,
                  filePath: `/${filename}`,
                },
              ],
              branch: expectedCommitBranch,
              message: sprintf(expectedCommitMessage, { filename }),
              projectPath,
            },
          });
        });
      },
    );
  });
});
