import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import { modelVersionWithCandidate } from '../graphql_mock_data';

Vue.use(VueApollo);

const makeGraphqlModelVersion = (overrides = {}) => {
  return { ...modelVersionWithCandidate, ...overrides };
};

let wrapper;
const createWrapper = (modelVersion = modelVersionWithCandidate, props = {}, provide = {}) => {
  wrapper = shallowMountExtended(ModelVersionDetail, {
    propsData: {
      modelVersion,
      ...props,
    },
    provide: {
      projectPath: 'path/to/project',
      canWriteModelRegistry: true,
      importPath: 'path/to/import',
      maxAllowedFileSize: 99999,
      ...provide,
    },
  });
};

const findDescription = () => wrapper.findByTestId('description');
const findEmptyDescriptionState = () => wrapper.findByTestId('emptyDescriptionState');

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

    it('shows the description', () => {
      expect(findDescription().props('issuable')).toMatchObject({
        descriptionHtml: 'A model version description',
        titleHtml: undefined,
      });
      expect(findEmptyDescriptionState().exists()).toBe(false);
    });
  });

  describe('if model version does not have description', () => {
    beforeEach(() =>
      createWrapper(makeGraphqlModelVersion({ description: null, descriptionHtml: null })),
    );

    it('renders no description provided label', () => {
      expect(findDescription().exists()).toBe(false);
      expect(findEmptyDescriptionState().exists()).toBe(true);
      expect(findEmptyDescriptionState().text()).toContain(
        'No description available. To add a description, click "Edit model version" above.',
      );
    });
  });
});
