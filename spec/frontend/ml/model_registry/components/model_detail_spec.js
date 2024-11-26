import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { model } from '../graphql_mock_data';

let wrapper;

const createWrapper = (modelProp = model) => {
  wrapper = shallowMountExtended(ModelDetail, {
    propsData: { model: modelProp },
    provide: { createModelVersionPath: 'versions/new' },
    stubs: { GlTab },
  });
};

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
});
