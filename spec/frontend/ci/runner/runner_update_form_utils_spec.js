import { ACCESS_LEVEL_NOT_PROTECTED } from '~/ci/runner/constants';
import {
  modelToUpdateMutationVariables,
  runnerToModel,
} from '~/ci/runner/runner_update_form_utils';

const mockId = 'gid://gitlab/Ci::Runner/1';
const mockDescription = 'Runner Desc.';

const mockRunner = {
  id: mockId,
  description: mockDescription,
  maximumTimeout: 100,
  accessLevel: ACCESS_LEVEL_NOT_PROTECTED,
  paused: false,
  locked: true,
  runUntagged: true,
  tagList: ['tag-1', 'tag-2'],
};

const mockModel = {
  ...mockRunner,
  tagList: 'tag-1, tag-2',
};

describe('~/ci/runner/runner_update_form_utils', () => {
  describe('runnerToModel', () => {
    it('collects all model data', () => {
      expect(runnerToModel(mockRunner)).toEqual(mockModel);
    });

    it('does not collect other data', () => {
      const model = runnerToModel({
        ...mockRunner,
        unrelated: 'unrelatedValue',
      });

      expect(model.unrelated).toEqual(undefined);
    });

    it('tag list defaults to an empty string', () => {
      const model = runnerToModel({
        ...mockRunner,
        tagList: undefined,
      });

      expect(model.tagList).toEqual('');
    });
  });

  describe('modelToUpdateMutationVariables', () => {
    it('collects all model data', () => {
      expect(modelToUpdateMutationVariables(mockModel)).toEqual({
        input: {
          ...mockRunner,
        },
      });
    });

    it('collects a nullable timeout from the model', () => {
      const variables = modelToUpdateMutationVariables({
        ...mockModel,
        maximumTimeout: '',
      });

      expect(variables).toEqual({
        input: {
          ...mockRunner,
          maximumTimeout: null,
        },
      });
    });

    it.each`
      tagList                       | tagListInput
      ${''}                         | ${[]}
      ${'tag1, tag2'}               | ${['tag1', 'tag2']}
      ${'with spaces'}              | ${['with spaces']}
      ${',,,,, commas'}             | ${['commas']}
      ${'more ,,,,, commas'}        | ${['more', 'commas']}
      ${'  trimmed  ,  trimmed2  '} | ${['trimmed', 'trimmed2']}
    `('collect comma-separated tags "$tagList" as $tagListInput', ({ tagList, tagListInput }) => {
      const variables = modelToUpdateMutationVariables({
        ...mockModel,
        tagList,
      });

      expect(variables).toEqual({
        input: {
          ...mockRunner,
          tagList: tagListInput,
        },
      });
    });
  });
});
