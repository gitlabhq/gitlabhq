import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import EmptyState from '~/ml/model_registry/components/model_list_empty_state.vue';
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { model, modelWithoutVersion } from '../graphql_mock_data';

let wrapper;

const createWrapper = (modelProp = model) => {
  wrapper = shallowMountExtended(ModelDetail, {
    propsData: { model: modelProp },
    provide: { createModelVersionPath: 'versions/new' },
    stubs: { GlTab },
  });
};

const findEmptyState = () => wrapper.findComponent(EmptyState);
const findVersionLink = () => wrapper.findByTestId('model-version-link');
const findIssuable = () => wrapper.findComponent(IssuableDescription);
const findEmptyDescription = () => wrapper.findByTestId('empty-description-state');

describe('ShowMlModel', () => {
  describe('when it has description', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays description', () => {
      expect(findEmptyDescription().exists()).toBe(false);
      expect(findIssuable().props('issuable')).toEqual({
        titleHtml: model.name,
        descriptionHtml: model.descriptionHtml,
      });
    });
  });

  describe('when it does not have description', () => {
    beforeEach(() => {
      createWrapper({ ...model, description: '', descriptionHtml: '' });
    });

    it('displays empty state description', () => {
      expect(findEmptyDescription().exists()).toBe(true);
      expect(findEmptyDescription().text()).toContain(
        'No description available. To add a description, click "Edit model" above.',
      );
    });
  });

  describe('when it has latest version', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a link to latest version', () => {
      expect(wrapper.text()).toContain('Latest version:');
      expect(findVersionLink().attributes('href')).toBe(
        '/root/test-project/-/ml/models/1/versions/5000',
      );
      expect(findVersionLink().text()).toBe('1.0.4999');
    });
  });

  describe('when it does not have latest version', () => {
    beforeEach(() => {
      createWrapper(modelWithoutVersion);
    });

    it('shows empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'Manage versions of your machine learning model',
        description: 'Use versions to track performance, parameters, and metadata',
        primaryText: 'Create model version',
        primaryLink: 'versions/new',
      });
    });
  });
});
