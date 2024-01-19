import { GlLink, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import ModelRow from '~/ml/model_registry/components/model_row.vue';
import { modelWithOneVersion, modelWithVersions, modelWithoutVersion } from '../graphql_mock_data';

let wrapper;
const createWrapper = (model = modelWithVersions) => {
  wrapper = shallowMountExtended(ModelRow, { propsData: { model } });
};

const findListItem = () => wrapper.findComponent(ListItem);
const findTitleLink = () => findListItem().findAllComponents(GlLink).at(0);
const findTruncated = () => findTitleLink().findComponent(GlTruncate);
const findVersionLink = () => findListItem().findAllComponents(GlLink).at(1);
const findMessage = (message) => wrapper.findByText(message);

describe('ModelRow', () => {
  it('Has a link to the model', () => {
    createWrapper();

    expect(findTruncated().props('text')).toBe(modelWithVersions.name);
    expect(findTitleLink().attributes('href')).toBe(modelWithVersions._links.showPath);
  });

  it('Shows the latest version and the version count', () => {
    createWrapper();

    expect(findVersionLink().text()).toBe(modelWithVersions.latestVersion.version);
    expect(findVersionLink().attributes('href')).toBe(
      modelWithVersions.latestVersion._links.showPath,
    );
    expect(findMessage('· 2 versions').exists()).toBe(true);
  });

  it('Shows the latest version and no version count if it has only 1 version', () => {
    createWrapper(modelWithOneVersion);

    expect(findVersionLink().text()).toBe(modelWithOneVersion.latestVersion.version);
    expect(findVersionLink().attributes('href')).toBe(
      modelWithOneVersion.latestVersion._links.showPath,
    );

    expect(findMessage('· 1 version').exists()).toBe(true);
  });

  it('Shows no version message if model has no versions', () => {
    createWrapper(modelWithoutVersion);

    expect(findMessage('No registered versions').exists()).toBe(true);
  });
});
