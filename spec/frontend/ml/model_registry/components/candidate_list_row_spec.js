import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CandidateListRow from '~/ml/model_registry/components/candidate_list_row.vue';
import { graphqlCandidates } from '../graphql_mock_data';

const CANDIDATE = graphqlCandidates[0];

let wrapper;
const createWrapper = (candidate = CANDIDATE) => {
  wrapper = shallowMount(CandidateListRow, {
    propsData: { candidate },
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

describe('ml/model_registry/components/candidate_list_row.vue', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('Has a link to the candidate', () => {
    expect(findTruncated().props('text')).toBe(CANDIDATE.name);
    expect(findLink().attributes('href')).toBe(CANDIDATE._links.showPath);
  });

  it('Shows created at', () => {
    expect(findTooltip().props('time')).toBe(CANDIDATE.createdAt);
  });
});
