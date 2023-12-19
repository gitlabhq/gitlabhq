import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ModelVersionRow from '~/ml/model_registry/components/model_version_row.vue';
import { graphqlModelVersions } from '../graphql_mock_data';

let wrapper;
const createWrapper = (modelVersion = graphqlModelVersions[0]) => {
  wrapper = shallowMount(ModelVersionRow, {
    propsData: { modelVersion },
    stubs: {
      GlSprintf,
      GlTruncate,
    },
  });
};

const findListItem = () => wrapper.findComponent(ListItem);
const findLink = () => findListItem().findComponent(GlLink);
const findTruncated = () => findLink().findComponent(GlTruncate);
const findTooltip = () => findListItem().findComponent(TimeAgoTooltip);

describe('ModelVersionRow', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('Has a link to the model version', () => {
    expect(findTruncated().props('text')).toBe(graphqlModelVersions[0].version);
    expect(findLink().attributes('href')).toBe(graphqlModelVersions[0]._links.showPath);
  });

  it('Shows created at', () => {
    expect(findTooltip().props('time')).toBe(graphqlModelVersions[0].createdAt);
  });
});
